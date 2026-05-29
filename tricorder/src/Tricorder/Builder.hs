module Tricorder.Builder
    ( component
    , withBuilderSession
    , BuilderSession (..)
    , NewLoadResult (..)
    , compileLoadResultsIntoBuildResults
    , requestTestRunsForNewBuildResults
    , buildWithGhciOnChange
    , handleInitialBuild
    , onRestart
    , reloadOnSourceChange
    , setNewPhase
    ) where

import Data.Default (Default (..))
import Data.Time (diffUTCTime)
import Effectful.Concurrent (Concurrent)
import Effectful.Exception (bracket_, trySync)
import Effectful.Reader.Static (Reader, ask)
import Effectful.State.Static.Shared (State, get, modify, state)
import System.FilePath (normalise)

import Data.Map.Strict qualified as Map
import Data.Set qualified as Set

import Atelier.Component (Component (..), defaultComponent)
import Atelier.Effects.Chan (Chan)
import Atelier.Effects.Clock (Clock, UTCTime)
import Atelier.Effects.Conc (Conc)
import Atelier.Effects.Debounce (Debounce, debounced)
import Atelier.Effects.FileWatcher (FileEvent (..))
import Atelier.Effects.Log (Log)
import Atelier.Effects.Publishing (Pub, Sub, publish)
import Atelier.Time (Millisecond, nominalDiffTime)
import Atelier.Types.Semaphore (Semaphore)
import Tricorder.BuildState
    ( BuildId (..)
    , BuildPhase (..)
    , BuildResult (..)
    , CabalChangeDetected (..)
    , Diagnostic (..)
    , EnteredNewPhase (..)
    , EnteringNewPhase (..)
    , Severity (..)
    , SourceChangeDetected (..)
    , TestRun (..)
    )
import Tricorder.Builder.Dispatch
    ( BuilderState (..)
    , KnownTargetNames (..)
    , emptyBuilderState
    , fileMatchesAnyTarget
    , filterToWatchDirs
    , mergeDiagnostics
    , resolveKnownTargets
    )
import Tricorder.Effects.BuildStore (BuildStore)
import Tricorder.Effects.GhciSession (GhciSession, LoadResult (..))
import Tricorder.Effects.SessionStore (SessionStore, SessionStoreReloaded)
import Tricorder.Effects.TestRunner (TestRunner)
import Tricorder.Runtime (ProjectRoot (..))
import Tricorder.Session (Session (..))

import Atelier.Effects.Clock qualified as Clock
import Atelier.Effects.Conc qualified as Conc
import Atelier.Effects.Log qualified as Log
import Atelier.Effects.Publishing qualified as Sub
import Atelier.Types.Semaphore qualified as Sem
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
       , Pub BuildResult :> es
       , Pub EnteredNewPhase :> es
       , Pub EnteringNewPhase :> es
       , Pub NewLoadResult :> es
       , Reader ProjectRoot :> es
       , SessionStore :> es
       , State BuildId :> es
       , State BuilderState :> es
       , Sub BuildResult :> es
       , Sub CabalChangeDetected :> es
       , Sub EnteringNewPhase :> es
       , Sub NewLoadResult :> es
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
       , Pub BuildResult :> es
       , Pub EnteredNewPhase :> es
       , Pub EnteringNewPhase :> es
       , Pub NewLoadResult :> es
       , Reader ProjectRoot :> es
       , State BuildId :> es
       , State BuilderState :> es
       , Sub BuildResult :> es
       , Sub CabalChangeDetected :> es
       , Sub EnteringNewPhase :> es
       , Sub NewLoadResult :> es
       , Sub SourceChangeDetected :> es
       , TestRunner :> es
       )
    => SessionStore.Reloader es
    -> BuilderSession
    -> Eff es ()
restartableListeners reloader config = bracket_ (pure ()) (onRestart) $ Conc.scoped do
    ProjectRoot projectRoot <- ask
    Log.info $ "Builder.component: resolved command = " <> config.command
    Log.info $ "Builder.component: projectRoot = " <> toText projectRoot
    Conc.fork_ $ Sub.listen_ $ compileLoadResultsIntoBuildResults config
    Conc.fork_ $ Sub.listen_ $ requestTestRunsForNewBuildResults config
    Conc.fork_ $ buildWithGhciOnChange reloader config
    Conc.fork_ $ Sub.listen_ setNewPhase
    Conc.awaitAll


onRestart
    :: ( Log :> es
       , Pub EnteringNewPhase :> es
       , State BuildId :> es
       )
    => Eff es ()
onRestart = do
    Log.info "Restarting builder..."
    buildId <- state (\b -> (b, b + 1))
    publish $ EnteringNewPhase buildId $ Building Nothing


setNewPhase
    :: ( BuildStore :> es
       , Pub EnteredNewPhase :> es
       )
    => EnteringNewPhase -> Eff es ()
setNewPhase (EnteringNewPhase bid phase) = do
    BuildStore.setPhase bid phase
    publish $ EnteredNewPhase bid phase


buildWithGhciOnChange
    :: ( BuildStore :> es
       , Clock :> es
       , Conc :> es
       , Concurrent :> es
       , Debounce Text :> es
       , GhciSession :> es
       , Log :> es
       , Pub EnteringNewPhase :> es
       , Pub NewLoadResult :> es
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
    modify @BuilderState (const emptyBuilderState)
    projectRoot <- ask
    BuildId n <- get
    Log.info $ "Starting GHCi session #" <> show n <> ": " <> config.command

    initialStartTime <- Clock.currentTime
    GhciSession.withGhci config.command projectRoot \initialLoad controls -> do
        initialEndTime <- Clock.currentTime
        handleInitialBuild config initialStartTime initialEndTime initialLoad
        modify @BuilderState \s ->
            s
                { loadedModules = resolveKnownTargets Map.empty initialLoad
                , knownTargets = KnownTargetNames (Set.fromList initialLoad.targetNames)
                }
        rebuildOnChange reloader controls


handleInitialBuild
    :: ( Log :> es
       , Pub NewLoadResult :> es
       , Reader ProjectRoot :> es
       , State BuildId :> es
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
    publish
        NewLoadResult
            { startTime
            , endTime
            , loadResult
            }


rebuildOnChange
    :: ( BuildStore :> es
       , Clock :> es
       , Conc :> es
       , Concurrent :> es
       , Debounce Text :> es
       , Log :> es
       , Pub EnteringNewPhase :> es
       , Pub NewLoadResult :> es
       , State BuildId :> es
       , State BuilderState :> es
       , Sub CabalChangeDetected :> es
       , Sub SourceChangeDetected :> es
       , TestRunner :> es
       )
    => SessionStore.Reloader es
    -> GhciSession.Controls (Eff es)
    -> Eff es Void
rebuildOnChange reloader controls = Conc.scoped do
    BuildId n <- get
    Log.debug $ "Builder: waiting for dirty flag (build #" <> show n <> ")"
    Conc.fork_ $ Sub.listen_ @CabalChangeDetected $ \_ -> do
        Log.info "Cabal file changed; reloading session"
        -- Signals to `withBuilderSession` that the session should be reloaded.
        reloader.reload
    handleSourceChanges controls


handleSourceChanges
    :: ( BuildStore :> es
       , Clock :> es
       , Conc :> es
       , Concurrent :> es
       , Debounce Text :> es
       , Log :> es
       , Pub EnteringNewPhase :> es
       , Pub NewLoadResult :> es
       , State BuildId :> es
       , State BuilderState :> es
       , Sub SourceChangeDetected :> es
       , TestRunner :> es
       )
    => GhciSession.Controls (Eff es) -> Eff es Void
handleSourceChanges controls = forever $ Conc.scoped do
    readyToBuildSem <- Sem.newSet
    Conc.fork_ $ Sub.listen_ \ev ->
        debounced 200 "source_change_reloader" $ reloadOnSourceChange readyToBuildSem controls ev
    Conc.fork_ $ Sub.listen_ \_ -> interruptCurrent readyToBuildSem controls
    Conc.awaitAll


interruptCurrent
    :: ( BuildStore :> es
       , Concurrent :> es
       , Log :> es
       , TestRunner :> es
       )
    => Semaphore -> GhciSession.Controls (Eff es) -> Eff es ()
interruptCurrent readyToBuildSem controls = do
    hasWaiters <- BuildStore.hasWaiters
    unless hasWaiters do
        Log.info "Change detected with no waiters. Interrupting current build/tests."
        isIdle <- Sem.peek readyToBuildSem
        unless isIdle
            $ bracket_
                (Sem.unset readyToBuildSem)
                (Sem.set readyToBuildSem)
                controls.interrupt
        TestRunner.interruptCurrent


reloadOnSourceChange
    :: ( Clock :> es
       , Concurrent :> es
       , Log :> es
       , Pub EnteringNewPhase :> es
       , Pub NewLoadResult :> es
       , State BuildId :> es
       , State BuilderState :> es
       )
    => Semaphore -> GhciSession.Controls (Eff es) -> SourceChangeDetected -> Eff es ()
reloadOnSourceChange readyToBuildSem controls (SourceChangeDetected fp event) = do
    Log.debug $ "Builder: source change detected " <> show event <> " " <> toText fp
    builderState <- get @BuilderState
    let known = Map.lookup (normalise fp) builderState.loadedModules
    case dispatch builderState.knownTargets known of
        Nothing ->
            Log.debug
                $ "Builder: no-op for "
                    <> show event
                    <> " of file not loaded in GHCi: "
                    <> toText fp
        Just action -> do
            buildId <- get
            publish $ EnteringNewPhase buildId $ Building Nothing

            res <- trySync $ Sem.withSemaphore readyToBuildSem do
                startTime <- Clock.currentTime
                res <- action
                endTime <- Clock.currentTime
                pure (startTime, endTime, res)

            case res of
                Left e -> do
                    now <- Clock.currentTime
                    Log.err $ show now <> " Reload errored: " <> show e
                Right (startTime, endTime, loadResult) -> do
                    modify @BuilderState \s ->
                        s
                            { loadedModules = resolveKnownTargets s.loadedModules loadResult
                            , knownTargets = KnownTargetNames (Set.fromList loadResult.targetNames)
                            }
                    publish $ NewLoadResult {startTime, endTime, loadResult}
  where
    -- The path-keyed module map misses targets that failed on first load,
    -- so we fall back to 'KnownTargetNames' for those — otherwise the
    -- dispatcher would issue @:add@ (a no-op for an already-tracked cabal
    -- target), leaving stale diagnostics in place.
    dispatch knownTargets = \case
        Just lm -> Just $ case event of
            Added -> controls.reload
            Modified -> controls.reload
            Removed -> controls.unadd lm.moduleName
        Nothing
            | fileMatchesAnyTarget knownTargets fp -> case event of
                Added -> Just controls.reload
                Modified -> Just controls.reload
                Removed -> Nothing
            | otherwise -> case event of
                Added -> Just (controls.add fp)
                Modified -> Just (controls.add fp)
                Removed -> Nothing


data NewLoadResult = NewLoadResult
    { startTime :: UTCTime
    , endTime :: UTCTime
    , loadResult :: LoadResult
    }
    deriving stock (Eq, Show)


compileLoadResultsIntoBuildResults
    :: ( Pub BuildResult :> es
       , Reader ProjectRoot :> es
       , State BuilderState :> es
       )
    => BuilderSession
    -> NewLoadResult
    -> Eff es ()
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

    publish
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
    :: ( Log :> es
       , Pub EnteringNewPhase :> es
       , State BuildId :> es
       , TestRunner :> es
       )
    => BuilderSession
    -> BuildResult
    -> Eff es ()
requestTestRunsForNewBuildResults config partialResult = do
    buildId <- get
    runTestsIfClean config buildId partialResult >>= \case
        Nothing -> Log.info "Test run aborted by source change; skipping Done publish."
        Just testRuns ->
            publish $ EnteringNewPhase buildId $ Done partialResult {testRuns}


-- Run all configured test suites if the build has no errors.
-- Transitions to 'Testing' phase while suites are running.
--
-- Returns 'Nothing' if the run was aborted mid-flight by a source change
-- (the caller should not publish a Done phase in that case). Returns
-- 'Just' with the collected results otherwise.
runTestsIfClean
    :: ( Log :> es
       , Pub EnteringNewPhase :> es
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
        publish
            $ EnteringNewPhase bid
            $ Testing partialResult {testRuns = map TestRunning testTargets}

        Log.info $ "Running " <> show (length testTargets) <> " test suite(s)"

        let initial = (\t -> (t, TestRunning t)) <$> testTargets
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
            publish
                $ EnteringNewPhase bid
                $ Testing partialResult {testRuns = snd <$> acc'}
            runLoop acc' rest

    insert _ _ [] = []
    insert k v ((k', v') : xs)
        | k == k' = (k, v) : xs
        | otherwise = (k', v') : insert k v xs
