module Tricorder.Builder
    ( component
    , withBuilderSession
    , BuilderSession (..)
    , NewLoadResult (..)
    , EnteringNewPhase (..)
    , afterLoad
    , compileLoadResultsIntoBuildResults
    , requestTestRunsForNewBuildResults
    , buildWithGhciOnChange
    , handleSourceChanges
    , handleInitialBuild
    , interruptCurrent
    , onRestart
    , reloadOnSourceChange
    , setNewPhase
    , withCycleLock
    , newCycleLock
    , CycleLock
    ) where

import Control.Concurrent.STM (TMVar, newTMVar, putTMVar, readTVar, retry, takeTMVar, writeTVar)
import Data.Default (Default (..))
import Data.Time (diffUTCTime)
import Effectful.Concurrent (Concurrent)
import Effectful.Concurrent.STM (atomically, newTVar)
import Effectful.Exception (bracket_, trySync)
import Effectful.Reader.Static (Reader, ask)
import Effectful.State.Static.Shared (State, get, modify, put, state)
import System.FilePath (normalise)

import Data.Map.Strict qualified as Map
import Data.Set qualified as Set

import Atelier.Component (Component (..), defaultComponent)
import Atelier.Effects.Chan (Chan)
import Atelier.Effects.Clock (Clock, UTCTime)
import Atelier.Effects.Conc (Conc)
import Atelier.Effects.Debounce (Debounce, debounced)
import Atelier.Effects.Log (Log)
import Atelier.Effects.Publishing (Sub)
import Atelier.Time (Millisecond, nominalDiffTime)
import Tricorder.BuildState
    ( BuildId (..)
    , BuildPhase (..)
    , BuildResult (..)
    , CabalChangeDetected (..)
    , Diagnostic (..)
    , Severity (..)
    , SourceChangeDetected (..)
    , TestRun (..)
    )
import Tricorder.Builder.Dispatch
    ( BuilderState (..)
    , DispatchAction (..)
    , KnownTargetNames (..)
    , dispatch
    , emptyBuilderState
    , filterToWatchDirs
    , mergeDiagnostics
    )
import Tricorder.Effects.BuildStore (BuildStore)
import Tricorder.Effects.GhciSession (GhciSession, LoadResult (..))
import Tricorder.Effects.GhciSession.GhciParser (resolveKnownTargets)
import Tricorder.Effects.SessionStore (SessionStore, SessionStoreReloaded)
import Tricorder.Effects.TestRunner (TestRunner)
import Tricorder.Runtime (ProjectRoot (..))
import Tricorder.Session (Session (..))

import Atelier.Effects.Clock qualified as Clock
import Atelier.Effects.Conc qualified as Conc
import Atelier.Effects.Log qualified as Log
import Atelier.Effects.Publishing qualified as Sub
import Tricorder.Effects.BuildStore qualified as BuildStore
import Tricorder.Effects.GhciSession qualified as GhciSession
import Tricorder.Effects.SessionStore qualified as SessionStore
import Tricorder.Effects.TestRunner qualified as TestRunner


-- | Builder component.
-- Starts a GHCi session, performs an initial load, then listens for changes
-- from the watcher.
component
    :: ( BuildStore :> es
       , Chan :> es
       , Clock :> es
       , Conc :> es
       , Concurrent :> es
       , Debounce Text :> es
       , GhciSession :> es
       , Log :> es
       , Reader ProjectRoot :> es
       , SessionStore :> es
       , State BuildId :> es
       , State BuilderState :> es
       , Sub CabalChangeDetected :> es
       , Sub SessionStoreReloaded :> es
       , Sub SourceChangeDetected :> es
       , TestRunner :> es
       )
    => Component es
component =
    defaultComponent
        { name = "Builder"
        , listeners = do
            session <- SessionStore.get
            pure [withBuilderSession session restartableListeners]
        }


-- | A subset of 'Session' with just the properties that 'Builder' cares about.
data BuilderSession = BuilderSession
    { command :: Text
    , targets :: [Text]
    , testTargets :: [Text]
    , watchDirs :: [FilePath]
    }
    deriving stock (Eq)


instance Default BuilderSession where
    def =
        BuilderSession
            { command = session.command
            , targets = session.targets
            , testTargets = session.testTargets
            , watchDirs = session.watchDirs
            }
      where
        session = def @Session


-- | Tracks the parts of 'Session' that 'Builder' cares about, and restarts the
-- passed function whenever those parts change.
withBuilderSession
    :: ( Chan :> es
       , Conc :> es
       , SessionStore :> es
       , Sub SessionStoreReloaded :> es
       )
    => Session
    -> (SessionStore.Reloader es -> BuilderSession -> Eff es ())
    -> Eff es Void
withBuilderSession =
    -- 'withReloadingSubSession' (not 'withSubSession') so cabal-file edits
    -- always restart GHCi, even when the projected fields (command, targets,
    -- testTargets, watchDirs) didn't change. Most cabal edits change ghc-
    -- options or deps, which are invisible to the projection but still
    -- require a fresh GHCi.
    SessionStore.withReloadingSubSession mkBuilderSession
  where
    mkBuilderSession session =
        BuilderSession
            { command = session.command
            , targets = session.targets
            , testTargets = session.testTargets
            , watchDirs = session.watchDirs
            }


restartableListeners
    :: ( BuildStore :> es
       , Clock :> es
       , Conc :> es
       , Concurrent :> es
       , Debounce Text :> es
       , GhciSession :> es
       , Log :> es
       , Reader ProjectRoot :> es
       , State BuildId :> es
       , State BuilderState :> es
       , Sub CabalChangeDetected :> es
       , Sub SourceChangeDetected :> es
       , TestRunner :> es
       )
    => SessionStore.Reloader es
    -> BuilderSession
    -> Eff es ()
restartableListeners reloader config = bracket_ (pure ()) onRestart do
    ProjectRoot projectRoot <- ask
    Log.info $ "Builder.component: resolved command = " <> config.command
    Log.info $ "Builder.component: projectRoot = " <> toText projectRoot
    void $ buildWithGhciOnChange reloader config


onRestart
    :: ( BuildStore :> es
       , Log :> es
       , State BuildId :> es
       )
    => Eff es ()
onRestart = do
    Log.info "Restarting builder..."
    buildId <- get
    modify @BuildId (+ 1)
    setNewPhase $ EnteringNewPhase buildId $ Building Nothing


setNewPhase
    :: (BuildStore :> es)
    => EnteringNewPhase -> Eff es ()
setNewPhase (EnteringNewPhase bid phase) =
    BuildStore.setPhase bid phase


-- | Run the post-load pipeline synchronously: compile diagnostics into a
-- 'BuildResult', then (optionally) run tests and transition through the
-- corresponding phases.
afterLoad
    :: ( BuildStore :> es
       , Log :> es
       , Reader ProjectRoot :> es
       , State BuildId :> es
       , State BuilderState :> es
       , TestRunner :> es
       )
    => BuilderSession -> NewLoadResult -> Eff es ()
afterLoad config newLoadResult = do
    buildResult <- compileLoadResultsIntoBuildResults config newLoadResult
    requestTestRunsForNewBuildResults config buildResult


buildWithGhciOnChange
    :: ( BuildStore :> es
       , Clock :> es
       , Conc :> es
       , Concurrent :> es
       , Debounce Text :> es
       , GhciSession :> es
       , Log :> es
       , Reader ProjectRoot :> es
       , State BuildId :> es
       , State BuilderState :> es
       , Sub CabalChangeDetected :> es
       , Sub SourceChangeDetected :> es
       , TestRunner :> es
       )
    => SessionStore.Reloader es
    -> BuilderSession
    -> Eff es Void
buildWithGhciOnChange reloader config = forever do
    put emptyBuilderState
    projectRoot <- ask
    BuildId n <- get
    Log.info $ "Starting GHCi session #" <> show n <> ": " <> config.command

    initialStartTime <- Clock.currentTime
    GhciSession.withGhci config.command projectRoot \initialLoad controls -> do
        initialEndTime <- Clock.currentTime
        handleInitialBuild config initialStartTime initialEndTime initialLoad
        modify \s ->
            s
                { loadedModules = resolveKnownTargets Map.empty initialLoad
                , knownTargets = KnownTargetNames (Set.fromList initialLoad.targetNames)
                }
        rebuildOnChange reloader config controls


handleInitialBuild
    :: ( BuildStore :> es
       , Log :> es
       , Reader ProjectRoot :> es
       , State BuildId :> es
       , State BuilderState :> es
       , TestRunner :> es
       )
    => BuilderSession
    -> UTCTime
    -> UTCTime
    -> LoadResult
    -> Eff es ()
handleInitialBuild config startTime endTime loadResult = do
    ProjectRoot projectRoot <- ask
    BuildId n <- get
    let filteredMsgs = filterToWatchDirs projectRoot config.watchDirs loadResult.diagnostics

    Log.info
        $ mconcat
            [ "GHCi started (session #"
            , show n
            , "): "
            , show $ length filteredMsgs
            , " diagnostics"
            ]
    afterLoad config NewLoadResult {startTime, endTime, loadResult}


rebuildOnChange
    :: ( BuildStore :> es
       , Clock :> es
       , Conc :> es
       , Concurrent :> es
       , Debounce Text :> es
       , Log :> es
       , Reader ProjectRoot :> es
       , State BuildId :> es
       , State BuilderState :> es
       , Sub CabalChangeDetected :> es
       , Sub SourceChangeDetected :> es
       , TestRunner :> es
       )
    => SessionStore.Reloader es
    -> BuilderSession
    -> GhciSession.Controls (Eff es)
    -> Eff es Void
rebuildOnChange reloader config controls = Conc.scoped do
    BuildId n <- get
    Log.debug $ "Builder: waiting for dirty flag (build #" <> show n <> ")"
    Conc.fork_ $ Sub.listen_ @CabalChangeDetected $ \_ -> do
        Log.info "Cabal file changed; reloading session"
        -- Signals to `withBuilderSession` that the session should be reloaded.
        reloader.reload
    handleSourceChanges config controls


handleSourceChanges
    :: ( BuildStore :> es
       , Clock :> es
       , Conc :> es
       , Concurrent :> es
       , Debounce Text :> es
       , Log :> es
       , Reader ProjectRoot :> es
       , State BuildId :> es
       , State BuilderState :> es
       , Sub SourceChangeDetected :> es
       , TestRunner :> es
       )
    => BuilderSession -> GhciSession.Controls (Eff es) -> Eff es Void
handleSourceChanges config controls = forever $ Conc.scoped do
    -- Coalesce debounced source-change events through a single-slot
    -- register: the debounced listener writes the latest event into the
    -- slot, and a single worker fork drains it. Events that arrive while
    -- the worker is processing the previous one simply overwrite the slot,
    -- so a burst of N touches collapses into exactly one trailing cycle
    -- (carrying the most recent event) rather than queueing N back-to-back
    -- cycles. This matters whenever 'interruptCurrent' can't drop the
    -- in-flight cycle promptly — e.g. when a 'status --wait' caller has
    -- registered as a waiter, gating 'interruptCurrent' to a no-op.
    pending <- atomically (newTVar @(Maybe SourceChangeDetected) Nothing)
    Conc.fork_ $ Sub.listen_ \ev ->
        debounced 200 "source_change_reloader"
            $ atomically (writeTVar pending (Just ev))
    Conc.fork_ $ Sub.listen_ \_ -> interruptCurrent controls
    Conc.fork_ $ forever do
        ev <- atomically do
            readTVar pending >>= \case
                Nothing -> retry
                Just e -> writeTVar pending Nothing >> pure e
        reloadOnSourceChange config controls ev
    Conc.awaitAll


-- | A mutex serialising one build/test cycle at a time.
newtype CycleLock = CycleLock (TMVar ())


newCycleLock :: (Concurrent :> es) => Eff es CycleLock
newCycleLock = CycleLock <$> atomically (newTMVar ())


-- | Run @action@ under @lock@, blocking if another cycle is already in
-- flight. The lock is released even if @action@ throws.
withCycleLock :: (Concurrent :> es) => CycleLock -> Eff es a -> Eff es a
withCycleLock (CycleLock t) =
    bracket_ (atomically (takeTMVar t)) (atomically (putTMVar t ()))


-- 'controls.interrupt' is a safe no-op when GHCi is idle, and 'GhciSession'
-- serialises subsequent reloads through its own STM state.
interruptCurrent
    :: ( BuildStore :> es
       , Log :> es
       , TestRunner :> es
       )
    => GhciSession.Controls (Eff es) -> Eff es ()
interruptCurrent controls = do
    hasWaiters <- BuildStore.hasWaiters
    unless hasWaiters do
        Log.info "Change detected with no waiters. Interrupting current build/tests."
        controls.interrupt
        TestRunner.interruptCurrent


reloadOnSourceChange
    :: ( BuildStore :> es
       , Clock :> es
       , Log :> es
       , Reader ProjectRoot :> es
       , State BuildId :> es
       , State BuilderState :> es
       , TestRunner :> es
       )
    => BuilderSession
    -> GhciSession.Controls (Eff es)
    -> SourceChangeDetected
    -> Eff es ()
reloadOnSourceChange config controls (SourceChangeDetected fp event) = do
    Log.debug $ "Builder: source change detected " <> show event <> " " <> toText fp
    builderState <- get @BuilderState
    let known = Map.lookup (normalise fp) builderState.loadedModules
    case dispatch builderState.knownTargets known fp event of
        Nothing ->
            Log.debug
                $ "Builder: no-op for "
                    <> show event
                    <> " of file not loaded in GHCi: "
                    <> toText fp
        Just action -> do
            buildId <- get
            setNewPhase $ EnteringNewPhase buildId $ Building Nothing

            res <- trySync do
                startTime <- Clock.currentTime
                res <- runAction controls action
                endTime <- Clock.currentTime
                pure (startTime, endTime, res)

            case res of
                Left e -> do
                    now <- Clock.currentTime
                    Log.err $ show now <> " Reload errored: " <> show e
                Right (startTime, endTime, loadResult) -> do
                    modify \s ->
                        s
                            { loadedModules = resolveKnownTargets s.loadedModules loadResult
                            , knownTargets = KnownTargetNames (Set.fromList loadResult.targetNames)
                            }
                    afterLoad config NewLoadResult {startTime, endTime, loadResult}


runAction :: GhciSession.Controls (Eff es) -> DispatchAction -> Eff es LoadResult
runAction controls = \case
    Reload -> controls.reload
    Add fp -> controls.add fp
    Unadd mn -> controls.unadd mn


data NewLoadResult = NewLoadResult
    { startTime :: UTCTime
    , endTime :: UTCTime
    , loadResult :: LoadResult
    }
    deriving stock (Eq, Show)


-- | A pending phase transition. Carried by 'setNewPhase' into the 'BuildStore'.
data EnteringNewPhase = EnteringNewPhase BuildId BuildPhase
    deriving stock (Eq, Show)


compileLoadResultsIntoBuildResults
    :: ( Reader ProjectRoot :> es
       , State BuilderState :> es
       )
    => BuilderSession
    -> NewLoadResult
    -> Eff es BuildResult
compileLoadResultsIntoBuildResults session newLoadResult = do
    ProjectRoot projectRoot <- ask
    let filteredResult =
            loadResult
                { GhciSession.diagnostics =
                    filterToWatchDirs projectRoot watchDirs loadResult.diagnostics
                }

    newAccumulated <- state \s ->
        let merged = mergeDiagnostics s.diagnosticMap filteredResult
        in  (merged, s {diagnosticMap = merged})

    pure
        BuildResult
            { completedAt = endTime
            , duration = nominalDiffTime (diffUTCTime endTime startTime) :: Millisecond
            , moduleCount = loadResult.moduleCount
            , diagnostics = sortOn (\d -> (d.severity, d.file, d.line, d.col)) $ concat (Map.elems newAccumulated)
            , testRuns = []
            }
  where
    BuilderSession {watchDirs} = session
    NewLoadResult {startTime, endTime, loadResult} = newLoadResult


requestTestRunsForNewBuildResults
    :: ( BuildStore :> es
       , Log :> es
       , State BuildId :> es
       , TestRunner :> es
       )
    => BuilderSession
    -> BuildResult
    -> Eff es ()
requestTestRunsForNewBuildResults config partialResult = do
    buildId <- get
    runTestsIfClean config buildId partialResult >>= \case
        Nothing -> Log.info "Test run aborted by source change; skipping Done transition."
        Just testRuns ->
            setNewPhase $ EnteringNewPhase buildId $ Done partialResult {testRuns}


-- Run all configured test suites if the build has no errors.
-- Transitions to 'Testing' phase while suites are running.
--
-- Returns 'Nothing' if the run was aborted mid-flight by a source change
-- (the caller should not transition to a Done phase in that case). Returns
-- 'Just' with the collected results otherwise.
runTestsIfClean
    :: ( BuildStore :> es
       , Log :> es
       , TestRunner :> es
       )
    => BuilderSession
    -> BuildId
    -> BuildResult
    -> Eff es (Maybe [TestRun])
runTestsIfClean (BuilderSession {testTargets}) bid partialResult
    | null testTargets || any (\d -> d.severity == SError) partialResult.diagnostics = pure (Just [])
    | otherwise = do
        TestRunner.resetAbort
        setNewPhase
            $ EnteringNewPhase bid
            $ Testing partialResult {testRuns = map (`TestRunning` Nothing) testTargets}

        Log.info $ "Running " <> show (length testTargets) <> " test suite(s)"

        let initial = (\t -> (t, TestRunning t Nothing)) <$> testTargets
        runLoop initial testTargets
  where
    runLoop acc [] = pure (Just (snd <$> acc))
    runLoop acc (target : rest) = do
        Log.info $ "Running tests: " <> target
        result <- TestRunner.runTestSuite target
        aborted <- TestRunner.isAborted
        if aborted then
            pure Nothing
        else do
            let acc' = insert target result acc
            setNewPhase
                $ EnteringNewPhase bid
                $ Testing partialResult {testRuns = snd <$> acc'}
            runLoop acc' rest

    insert _ _ [] = []
    insert k v ((k', v') : xs)
        | k == k' = (k, v) : xs
        | otherwise = (k', v') : insert k v xs
