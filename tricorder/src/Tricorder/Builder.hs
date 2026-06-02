module Tricorder.Builder
    ( component
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
    , withCabalChangeRestarts
    , withCycleLock
    , newCycleLock
    , CycleLock
    ) where

import Control.Concurrent.STM (TMVar, check, newTMVar, putTMVar, readTVar, retry, takeTMVar, writeTVar)
import Data.Default (Default (..))
import Data.Time (diffUTCTime)
import Effectful.Concurrent (Concurrent)
import Effectful.Concurrent.STM (atomically, newTVar)
import Effectful.Exception (bracket_, finally, trySync)
import Effectful.Reader.Static (Reader, ask)
import Effectful.State.Static.Shared (State, get, modify, put, state)
import System.FilePath (normalise)

import Data.Map.Strict qualified as Map
import Data.Set qualified as Set

import Atelier.Component (Component (..), defaultComponent)
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
import Tricorder.Effects.GhciSession.GhciProcess (GhciProcessError (..))
import Tricorder.Effects.SessionStore (SessionStore)
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
       , Sub SourceChangeDetected :> es
       , TestRunner :> es
       )
    => Component es
component =
    defaultComponent
        { name = "Builder"
        , listeners = pure [coordinator]
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


-- | Project the parts of 'Session' the Builder cares about.
mkBuilderSession :: Session -> BuilderSession
mkBuilderSession session =
    BuilderSession
        { command = session.command
        , targets = session.targets
        , testTargets = session.testTargets
        , watchDirs = session.watchDirs
        }


-- | Run @action@ in a loop that restarts whenever a 'CabalChangeDetected'
-- event arrives. At most one iteration of @action@ runs at any moment: cabal
-- events arriving during a restart collapse into a single next iteration.
--
-- A TVar flag funnels the events: the cabal listener writes 'True' to it; a
-- single coordinator drains it via 'restartableForkWith', runs @preRestart@,
-- and exits the inner scope. Scope teardown cancels the current @action@
-- (including the 'cabal repl' subprocess via its bracket) and waits for it to
-- finish before the next iteration starts — so we never have two builders
-- racing for the same dist-newstyle directory.
withCabalChangeRestarts
    :: ( Conc :> es
       , Concurrent :> es
       , Log :> es
       , Sub CabalChangeDetected :> es
       )
    => Eff es ()
    -- ^ Pre-restart hook: runs in the coordinator thread after the flag has
    -- been drained but before the inner scope is torn down. Use this to set
    -- the UI to 'Restarting' and reload the session.
    -> Eff es r
    -- ^ Setup: runs at the start of each iteration, before @action@ is forked.
    -> (r -> Eff es Void)
    -- ^ Inner action. Must never return.
    -> Eff es Void
withCabalChangeRestarts preRestart setup action = do
    needsRestart <- atomically (newTVar False)
    Conc.scoped do
        Conc.fork_ $ Conc.restartableForkWith (signal needsRestart) setup action
        Sub.listen_ @CabalChangeDetected $ \_ -> do
            Log.info "Cabal file changed; queued restart"
            atomically (writeTVar needsRestart True)
  where
    signal needsRestart = do
        atomically do
            check =<< readTVar needsRestart
            writeTVar needsRestart False
        preRestart


-- | Owns the Builder's lifecycle.
--
-- Cabal-change events flip a TVar; the coordinator consumes the flag,
-- transitions the UI to 'Restarting', reloads the session, then exits the
-- inner scope which cancels the in-flight builder. The next iteration
-- forks a fresh builder with the reloaded session.
coordinator
    :: ( BuildStore :> es
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
       , Sub SourceChangeDetected :> es
       , TestRunner :> es
       )
    => Eff es Void
coordinator = withCabalChangeRestarts preRestart setup action
  where
    preRestart = do
        -- Flip the UI to 'Restarting' immediately so the user sees the change
        -- has been picked up before scope teardown (which kills cabal repl
        -- and waits for graceful exit).
        buildId <- get
        setNewPhase $ EnteringNewPhase buildId Restarting
        -- Pick up cabal/package.yaml edits before the next iteration starts.
        SessionStore.rawReload

    setup = do
        session <- SessionStore.get
        let config = mkBuilderSession session
        ProjectRoot projectRoot <- ask
        Log.info $ "Builder.component: resolved command = " <> config.command
        Log.info $ "Builder.component: projectRoot = " <> toText projectRoot
        pure config

    action config =
        buildWithGhciOnChange config `finally` onRestart


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
       , Sub SourceChangeDetected :> es
       , TestRunner :> es
       )
    => BuilderSession
    -> Eff es Void
buildWithGhciOnChange config = forever do
    put emptyBuilderState
    projectRoot <- ask
    BuildId n <- get
    Log.info $ "Starting GHCi session #" <> show n <> ": " <> config.command

    initialStartTime <- Clock.currentTime
    result <- trySync $ GhciSession.withGhci config.command projectRoot \initialLoad controls -> do
        initialEndTime <- Clock.currentTime
        handleInitialBuild config initialStartTime initialEndTime initialLoad
        modify \s ->
            s
                { loadedModules = resolveKnownTargets Map.empty initialLoad
                , knownTargets = KnownTargetNames (Set.fromList initialLoad.targetNames)
                }
        rebuildOnChange config controls
    case result of
        Right _ -> pure ()
        Left ex -> do
            buildId <- get
            Log.err $ "GHCi session failed to start: " <> show ex
            setNewPhase $ EnteringNewPhase buildId $ BuildFailed $ renderStartupError ex
            -- Wait for a source change, then loop to retry the launch. A cabal
            -- change is handled out-of-band by the coordinator cancelling this
            -- scope. Without this, a startup failure was a dead end: the user
            -- could fix the offending source file and nothing would happen,
            -- because no 'SourceChangeDetected' listener is active on this path.
            Log.info "Build command failed; waiting for a source change to retry"
            void $ Sub.listenOnce_ @SourceChangeDetected


renderStartupError :: SomeException -> Text
renderStartupError ex = case fromException ex of
    Just (StartupFailed msg) -> msg
    Just StartupTimeout -> "Build command did not produce a GHCi banner before timing out."
    Just (UnexpectedExit cmd lastLine) ->
        "Build command exited unexpectedly: "
            <> cmd
            <> maybe "" (\l -> "\n" <> l) lastLine
    Nothing -> toText (displayException ex)


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
       , Sub SourceChangeDetected :> es
       , TestRunner :> es
       )
    => BuilderSession
    -> GhciSession.Controls (Eff es)
    -> Eff es Void
rebuildOnChange config controls = Conc.scoped do
    BuildId n <- get
    Log.debug $ "Builder: waiting for dirty flag (build #" <> show n <> ")"
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
