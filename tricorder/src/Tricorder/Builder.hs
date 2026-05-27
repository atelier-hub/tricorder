module Tricorder.Builder
    ( component
    , BuilderSession (..)
    , filterToWatchDirs
    , mergeDiagnostics
    , NewLoadResult (..)
    , DiagnosticMap
    , compileLoadResultsIntoBuildResults
    , requestTestRunsForNewBuildResults
    , buildWithGhciOnChange
    , handleInitialBuild
    , onRestart
    , reloadOnSourceChange
    , resolveKnownTargets
    , upsertTestRun
    ) where

import Data.Default (Default (..))
import Data.Time (diffUTCTime)
import Effectful.Concurrent (Concurrent)
import Effectful.Exception (bracket_, trySync)
import Effectful.Reader.Static (Reader, ask)
import Effectful.State.Static.Shared (State, get, modify, put, state)
import Relude.Extra.Tuple (dup)
import System.FilePath (isAbsolute, normalise, (</>))

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
    , Severity (..)
    , SourceChangeDetected (..)
    , TestRun (..)
    , TestRunCompletion (..)
    , TestRunError (..)
    )
import Tricorder.Effects.BuildStore (BuildStore)
import Tricorder.Effects.GhciSession (GhciSession, LoadResult (..), LoadedModule (..))
import Tricorder.Effects.SessionStore (SessionStore, SessionStoreReloaded)
import Tricorder.Effects.TestRunner (BatchStatus (..), TestRunOutcome (..), TestRunner)
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


type DiagnosticMap = Map FilePath [Diagnostic]


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
       , Pub NewLoadResult :> es
       , Reader ProjectRoot :> es
       , SessionStore :> es
       , State (Map FilePath LoadedModule) :> es
       , State BuildId :> es
       , State DiagnosticMap :> es
       , Sub BuildResult :> es
       , Sub CabalChangeDetected :> es
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
    SessionStore.withSubSession mkBuilderSession
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
       , Pub NewLoadResult :> es
       , Reader ProjectRoot :> es
       , State (Map FilePath LoadedModule) :> es
       , State BuildId :> es
       , State DiagnosticMap :> es
       , Sub BuildResult :> es
       , Sub CabalChangeDetected :> es
       , Sub NewLoadResult :> es
       , Sub SourceChangeDetected :> es
       , TestRunner :> es
       )
    => SessionStore.Reloader es
    -> BuilderSession
    -> Eff es ()
restartableListeners reloader config = bracket_ (pure ()) onRestart $ Conc.scoped do
    ProjectRoot projectRoot <- ask
    Log.info $ "Builder.component: resolved command = " <> config.command
    Log.info $ "Builder.component: projectRoot = " <> toText projectRoot
    Conc.fork_ $ Sub.listen_ @NewLoadResult $ compileLoadResultsIntoBuildResults config
    Conc.fork_ $ Sub.listen_ @BuildResult $ requestTestRunsForNewBuildResults config
    Conc.fork_ $ buildWithGhciOnChange reloader config
    Conc.awaitAll


onRestart
    :: ( BuildStore :> es
       , Log :> es
       , State BuildId :> es
       )
    => Eff es ()
onRestart = do
    Log.info "Restarting builder..."
    buildId <- state (\b -> (b, b + 1))
    BuildStore.setPhase buildId (Building Nothing)


buildWithGhciOnChange
    :: ( BuildStore :> es
       , Clock :> es
       , Conc :> es
       , Concurrent :> es
       , Debounce Text :> es
       , GhciSession :> es
       , Log :> es
       , Pub NewLoadResult :> es
       , Reader ProjectRoot :> es
       , State (Map FilePath LoadedModule) :> es
       , State BuildId :> es
       , State DiagnosticMap :> es
       , Sub CabalChangeDetected :> es
       , Sub SourceChangeDetected :> es
       , TestRunner :> es
       )
    => SessionStore.Reloader es
    -> BuilderSession
    -> Eff es Void
buildWithGhciOnChange reloader config = forever do
    put @DiagnosticMap Map.empty
    put @(Map FilePath LoadedModule) Map.empty
    projectRoot <- ask
    BuildId n <- get
    Log.info $ "Starting GHCi session #" <> show n <> ": " <> config.command

    initialStartTime <- Clock.currentTime
    GhciSession.withGhci config.command projectRoot \initialLoad controls -> do
        initialEndTime <- Clock.currentTime
        handleInitialBuild config initialStartTime initialEndTime initialLoad
        put @(Map FilePath LoadedModule) (resolveKnownTargets Map.empty initialLoad)
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
       , Pub NewLoadResult :> es
       , State (Map FilePath LoadedModule) :> es
       , State BuildId :> es
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
       , Pub NewLoadResult :> es
       , State (Map FilePath LoadedModule) :> es
       , State BuildId :> es
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
    :: ( BuildStore :> es
       , Clock :> es
       , Concurrent :> es
       , Log :> es
       , Pub NewLoadResult :> es
       , State (Map FilePath LoadedModule) :> es
       , State BuildId :> es
       )
    => Semaphore -> GhciSession.Controls (Eff es) -> SourceChangeDetected -> Eff es ()
reloadOnSourceChange readyToBuildSem controls (SourceChangeDetected fp event) = do
    Log.debug $ "Builder: source change detected " <> show event <> " " <> toText fp
    moduleMap <- get @(Map FilePath LoadedModule)
    let known = Map.lookup (normalise fp) moduleMap
    case dispatch known of
        Nothing ->
            Log.debug
                $ "Builder: no-op for "
                    <> show event
                    <> " of file not loaded in GHCi: "
                    <> toText fp
        Just action -> do
            buildId <- get
            BuildStore.setPhase buildId (Building Nothing)

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
                    modify @(Map FilePath LoadedModule) (\prev -> resolveKnownTargets prev loadResult)
                    publish $ NewLoadResult {startTime, endTime, loadResult}
  where
    -- Dispatch on (is the file currently loaded in GHCi?, FileEvent).
    --
    -- The module map is the source of truth for "is this file a tracked
    -- target?" and it must be built from `:show targets` (which survives
    -- failed compiles), not `:show modules` (which drops them). See
    -- 'resolveKnownTargets' for how the map is maintained.
    dispatch = \case
        Just lm -> Just $ case event of
            Added -> controls.reload -- re-adding a known file is just a reload
            Modified -> controls.reload
            Removed -> controls.unadd lm.moduleName
        Nothing -> case event of
            Added -> Just (controls.add fp)
            Modified -> Just (controls.add fp) -- editor wrote a not-yet-loaded file
            Removed -> Nothing -- nothing to remove


data NewLoadResult = NewLoadResult
    { startTime :: UTCTime
    , endTime :: UTCTime
    , loadResult :: LoadResult
    }
    deriving stock (Eq, Show)


compileLoadResultsIntoBuildResults
    :: ( Pub BuildResult :> es
       , Reader ProjectRoot :> es
       , State DiagnosticMap :> es
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

    newAccumulated <- state $ dup . flip mergeDiagnostics filteredResult

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
        BatchAborted -> Log.info "Test run aborted by source change; skipping Done publish."
        BatchCompleted ->
            -- Freeze the build's final state as Done. From the normal path
            -- the phase is Testing with accumulated testRuns; from the
            -- early-return path (no targets / errored build) it's still
            -- whatever the build phase was, and we fall back to the input.
            BuildStore.modifyPhase buildId \case
                Testing buildResult -> Done buildResult
                _ -> Done partialResult


-- Run all configured test suites if the build has no errors.
-- Transitions to 'Testing' phase while suites are running, and updates the
-- per-target slot in BuildStore as each suite completes.
--
-- Returns 'BatchAborted' if the run was interrupted mid-flight by a source
-- change; the caller should not publish a Done phase in that case.
runTestsIfClean
    :: ( BuildStore :> es
       , Log :> es
       , TestRunner :> es
       )
    => BuilderSession
    -> BuildId
    -> BuildResult
    -> Eff es BatchStatus
runTestsIfClean (BuilderSession {testTargets}) bid partialResult
    | null testTargets || any (\d -> d.severity == SError) partialResult.diagnostics =
        pure BatchCompleted
    | otherwise = do
        BuildStore.setPhase bid $ Testing partialResult {testRuns = map TestRunning testTargets}
        Log.info $ "Running " <> show (length testTargets) <> " test suite(s)"
        TestRunner.withBatch testTargets \target -> \case
            TestAborted -> pure ()
            TestCompleted testRun -> do
                Log.info $ "Test completed: " <> target
                BuildStore.modifyPhase bid (upsertTestRun testRun)


-- | Replace the slot for a 'TestRun' (matched by target name) inside the
-- @testRuns@ list of a 'Testing' phase. Leaves other phases unchanged.
upsertTestRun :: TestRun -> BuildPhase -> BuildPhase
upsertTestRun newRun (Testing buildResult) =
    Testing buildResult {testRuns = replace buildResult.testRuns}
  where
    target = testRunTarget newRun
    replace [] = []
    replace (existing : rest)
        | testRunTarget existing == target = newRun : rest
        | otherwise = existing : replace rest
upsertTestRun _ phase = phase


testRunTarget :: TestRun -> Text
testRunTarget (TestRunning t) = t
testRunTarget (TestRunErrored e) = e.target
testRunTarget (TestRunCompleted c) = c.target


-- | Merge a new 'LoadResult' into the accumulated per-file diagnostic map.
--
-- Files in 'compiledFiles' have their previous diagnostics cleared and replaced
-- by any new diagnostics produced for them in this cycle. Files absent from
-- 'compiledFiles' were skipped by incremental compilation and retain their
-- previous diagnostics unchanged.
mergeDiagnostics :: DiagnosticMap -> LoadResult -> DiagnosticMap
mergeDiagnostics prev LoadResult {compiledFiles, diagnostics} =
    let cleared = foldr Map.delete prev compiledFiles
        newByFile = Map.fromListWith (++) [(d.file, [d]) | d <- diagnostics]
    in  Map.union newByFile cleared


-- | Compute the next "known targets" map by joining this cycle's
-- @:show modules@ (definitive path↔name mapping for successful loads) with
-- the prior map (carryover for targets that failed to compile and are
-- therefore absent from @:show modules@).
--
-- Targets that have never compiled successfully — so we have no entry for
-- them in either source — are dropped here: with neither @:show modules@ nor
-- prior knowledge we can't resolve their dotted name to a file path, and the
-- dispatcher keys on file paths. They'll be picked up next cycle via the
-- @unknown → :add@ branch.
resolveKnownTargets
    :: Map FilePath LoadedModule
    -- ^ Previous known-targets map (carryover source).
    -> LoadResult
    -> Map FilePath LoadedModule
resolveKnownTargets prev lr =
    let primary = lr.loadedModules
        primaryNames = Set.fromList [lm.moduleName | lm <- Map.elems primary]
        prevByName = Map.fromList [(lm.moduleName, (path, lm)) | (path, lm) <- Map.toList prev]
        carryover =
            Map.fromList
                [ (path, lm)
                | name <- lr.targetNames
                , not (Set.member name primaryNames)
                , Just (path, lm) <- [Map.lookup name prevByName]
                ]
    in  Map.union primary carryover


-- | Keep only diagnostics whose file is under one of the watched directories.
--
-- Diagnostics from outside the project (e.g. @.h@ files in the Nix store) and
-- those with mangled filenames produced by the C preprocessor (e.g.
-- @"In file included from ..."@) are dropped here, before they can enter the
-- accumulation map where they would be impossible to evict.
filterToWatchDirs :: FilePath -> [FilePath] -> [Diagnostic] -> [Diagnostic]
filterToWatchDirs _ [] diags = diags
filterToWatchDirs projectRoot watchDirs diags =
    filter (isUnderAnyWatchDir . (.file)) diags
  where
    absWatchDirs = map toAbsWd watchDirs
    toAbsWd wd
        | wd == "." = projectRoot
        | isAbsolute wd = wd
        | otherwise = projectRoot </> wd
    isUnderAnyWatchDir file
        | not (isAbsolute file) && not ("./" `isPrefixOf` file) = False
        | isAbsolute file =
            any (\wd -> (wd ++ "/") `isPrefixOf` file || wd == file) absWatchDirs
        | otherwise =
            let absFile = projectRoot </> drop 2 file
            in  any (\wd -> (wd ++ "/") `isPrefixOf` absFile || wd == absFile) absWatchDirs
