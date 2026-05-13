module Tricorder.Builder
    ( component
    , withBuilderSession
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
    , setNewPhase
    ) where

import Data.Default (Default (..))
import Data.Time (diffUTCTime)
import Effectful.Concurrent (Concurrent)
import Effectful.Exception (bracket_, trySync)
import Effectful.Reader.Static (Reader, ask)
import Effectful.State.Static.Shared (State, execState, get, put, state)
import Relude.Extra.Tuple (dup)
import System.FilePath (isAbsolute, (</>))

import Data.Map.Strict qualified as Map

import Atelier.Component (Component (..), defaultComponent)
import Atelier.Effects.Clock (Clock, UTCTime)
import Atelier.Effects.Conc (Conc)
import Atelier.Effects.Debounce (Debounce, debounced)
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


type DiagnosticMap = Map FilePath [Diagnostic]


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
       , Pub BuildResult :> es
       , Pub EnteredNewPhase :> es
       , Pub EnteringNewPhase :> es
       , Pub NewLoadResult :> es
       , Reader ProjectRoot :> es
       , SessionStore :> es
       , State BuildId :> es
       , State DiagnosticMap :> es
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
    :: ( Conc :> es
       , Concurrent :> es
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
       , Pub EnteredNewPhase :> es
       , Pub EnteringNewPhase :> es
       , Pub NewLoadResult :> es
       , Reader ProjectRoot :> es
       , State BuildId :> es
       , State DiagnosticMap :> es
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
       , State DiagnosticMap :> es
       , Sub CabalChangeDetected :> es
       , Sub SourceChangeDetected :> es
       )
    => SessionStore.Reloader es
    -> BuilderSession
    -> Eff es Void
buildWithGhciOnChange reloader config = forever do
    put Map.empty
    projectRoot <- ask
    BuildId n <- get
    Log.info $ "Starting GHCi session #" <> show n <> ": " <> config.command

    initialStartTime <- Clock.currentTime
    GhciSession.withGhci config.command projectRoot \initialLoad controls -> do
        initialEndTime <- Clock.currentTime
        handleInitialBuild config initialStartTime initialEndTime initialLoad
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
       , Sub CabalChangeDetected :> es
       , Sub SourceChangeDetected :> es
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
       , Sub SourceChangeDetected :> es
       )
    => GhciSession.Controls (Eff es) -> Eff es Void
handleSourceChanges controls = forever $ Conc.scoped do
    readyToBuildSem <- Sem.newSet
    Conc.fork_ $ Sub.listen_ \ev ->
        debounced 200 "source_change_reloader" $ reloadOnSourceChange readyToBuildSem controls ev
    Conc.fork_ $ Sub.listen_ \_ -> interruptCurrentReload readyToBuildSem controls
    Conc.awaitAll


interruptCurrentReload
    :: ( BuildStore :> es
       , Concurrent :> es
       , Log :> es
       )
    => Semaphore -> GhciSession.Controls (Eff es) -> Eff es ()
interruptCurrentReload readyToBuildSem controls = do
    isIdle <- Sem.peek readyToBuildSem
    hasWaiters <- BuildStore.hasWaiters
    unless (isIdle || hasWaiters)
        $ bracket_
            (Sem.unset readyToBuildSem)
            (Sem.set readyToBuildSem)
            do
                Log.info "Change detected. Interrupting current GHCi build."
                controls.interrupt


reloadOnSourceChange
    :: ( Clock :> es
       , Concurrent :> es
       , Log :> es
       , Pub EnteringNewPhase :> es
       , Pub NewLoadResult :> es
       , State BuildId :> es
       )
    => Semaphore -> GhciSession.Controls (Eff es) -> SourceChangeDetected -> Eff es ()
reloadOnSourceChange readyToBuildSem controls SourceChangeDetected = do
    Log.debug $ "Builder: dirty flag set, reloading"
    buildId <- get
    publish $ EnteringNewPhase buildId $ Building Nothing

    res <- trySync $ Sem.withSemaphore readyToBuildSem do
        startTime <- Clock.currentTime
        res <- controls.reload
        endTime <- Clock.currentTime
        pure (startTime, endTime, res)

    case res of
        Left e -> do
            now <- Clock.currentTime
            Log.err $ show now <> " Reload errored: " <> show e
        Right (startTime, endTime, loadResult) ->
            publish $ NewLoadResult {startTime, endTime, loadResult}


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
    testRuns <- runTestsIfClean config buildId partialResult
    publish $ EnteringNewPhase buildId $ Done partialResult {testRuns}


-- Run all configured test suites if the build has no errors.
-- Transitions to 'Testing' phase while suites are running.
runTestsIfClean
    :: ( Log :> es
       , Pub EnteringNewPhase :> es
       , TestRunner :> es
       )
    => BuilderSession
    -> BuildId
    -> BuildResult
    -> Eff es [TestRun]
runTestsIfClean (BuilderSession {testTargets}) bid partialResult
    | null testTargets || any (\d -> d.severity == SError) partialResult.diagnostics = pure []
    | otherwise = do
        publish
            $ EnteringNewPhase bid
            $ Testing partialResult {testRuns = map TestRunning testTargets}

        Log.info $ "Running " <> show (length testTargets) <> " test suite(s)"

        fmap (fmap snd)
            $ execState ((\t -> (t, TestRunning t)) <$> testTargets)
            $ for_ testTargets \target -> do
                Log.info $ "Running tests: " <> target
                result <- TestRunner.runTestSuite target
                runs <- state $ dup . insert target result
                publish
                    $ EnteringNewPhase bid
                    $ Testing partialResult {testRuns = snd <$> runs}
  where
    insert _ _ [] = []
    insert k v ((k', v') : xs)
        | k == k' = (k, v) : xs
        | otherwise = (k', v') : insert k v xs


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
