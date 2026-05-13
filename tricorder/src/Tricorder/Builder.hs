module Tricorder.Builder
    ( component
    , filterToWatchDirs
    , mergeDiagnostics
    , NewLoadResult (..)
    , DiagnosticMap
    , compileLoadResultsIntoBuildResults
    , requestTestRunsForNewBuildResults
    , buildWithGhciOnChange
    , handleInitialBuild
    , restartOnCabalChange
    , reloadOnSourceChange
    , setNewPhase
    ) where

import Data.Time (diffUTCTime)
import Effectful.Concurrent (Concurrent)
import Effectful.Reader.Static (Reader, ask)
import Effectful.State.Static.Shared (State, execState, get, put, state)
import Relude.Extra.Tuple (dup)
import System.FilePath (isAbsolute, (</>))

import Data.Map.Strict qualified as Map

import Atelier.Component (Component (..), defaultComponent)
import Atelier.Effects.Clock (Clock, UTCTime)
import Atelier.Effects.Conc (Conc)
import Atelier.Effects.Log (Log)
import Atelier.Effects.Publishing (Pub, Sub, publish)
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
import Tricorder.Effects.SessionStore (ActiveSession, SessionStore, SessionStoreReloaded)
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
        , listeners = pure [restartableListeners]
        }


restartableListeners
    :: ( BuildStore :> es
       , Clock :> es
       , Conc :> es
       , Concurrent :> es
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
    => Eff es Void
restartableListeners = SessionStore.withSession \activeSession -> do
    ProjectRoot projectRoot <- ask
    Log.debug $ "Builder.component: resolved command = " <> activeSession.session.command
    Log.debug $ "Builder.component: projectRoot = " <> toText projectRoot
    builderCancelSem <- Sem.new
    Conc.scoped do
        Conc.fork_ $ Sub.listen_ (compileLoadResultsIntoBuildResults activeSession.session)
        Conc.fork_ $ Sub.listen_ (requestTestRunsForNewBuildResults activeSession.session)
        Conc.fork_ $ buildWithGhciOnChange activeSession builderCancelSem
        Conc.fork_ $ Sub.listen_ setNewPhase
        void $ Sub.listenOnce_ @SessionStoreReloaded


setNewPhase
    :: ( BuildStore :> es
       , Pub EnteredNewPhase :> es
       )
    => EnteringNewPhase -> Eff es ()
setNewPhase (EnteringNewPhase bid phase) = do
    BuildStore.setPhase bid phase
    publish $ EnteredNewPhase bid phase


buildWithGhciOnChange
    :: ( Clock :> es
       , Conc :> es
       , Concurrent :> es
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
    => ActiveSession es
    -> Semaphore
    -> Eff es Void
buildWithGhciOnChange activeSession sem = forever do
    put Map.empty
    projectRoot <- ask
    BuildId n <- get
    Log.info $ "Starting GHCi session #" <> show n <> ": " <> activeSession.session.command

    initialStartTime <- Clock.currentTime
    GhciSession.withGhci activeSession.session.command projectRoot \initialLoad reload -> do
        initialEndTime <- Clock.currentTime
        handleInitialBuild activeSession.session initialStartTime initialEndTime initialLoad
        rebuildOnChange activeSession sem reload


handleInitialBuild
    :: ( Log :> es
       , Pub NewLoadResult :> es
       , Reader ProjectRoot :> es
       , State BuildId :> es
       )
    => Session
    -> UTCTime
    -> UTCTime
    -> LoadResult
    -> Eff es ()
handleInitialBuild session startTime endTime loadResult = do
    ProjectRoot projectRoot <- ask
    BuildId n <- get
    let filteredMsgs = filterToWatchDirs projectRoot session.watchDirs loadResult.diagnostics

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
    :: ( Clock :> es
       , Conc :> es
       , Concurrent :> es
       , Log :> es
       , Pub EnteringNewPhase :> es
       , Pub NewLoadResult :> es
       , State BuildId :> es
       , Sub CabalChangeDetected :> es
       , Sub SourceChangeDetected :> es
       )
    => ActiveSession es
    -> Semaphore
    -> Eff es LoadResult
    -> Eff es ()
rebuildOnChange activeSession sem reload = Conc.scoped do
    BuildId n <- get
    Log.debug $ "Builder: waiting for dirty flag (build #" <> show n <> ")"
    Conc.fork_ $ Sub.listen_ $ restartOnCabalChange activeSession sem
    Conc.fork_ $ Sub.listen_ $ reloadOnSourceChange reload
    -- TODO: Use this ref to cancel pending builds
    Sem.wait sem


restartOnCabalChange
    :: ( Concurrent :> es
       , Log :> es
       , Pub EnteringNewPhase :> es
       , State BuildId :> es
       )
    => ActiveSession es
    -> Semaphore
    -> CabalChangeDetected
    -> Eff es ()
restartOnCabalChange activeSession sem CabalChangeDetected = do
    Log.info "Cabal file changed; restarting GHCi session"
    buildId <- state (\b -> (b, b + 1))
    publish $ EnteringNewPhase buildId Restarting
    -- NOTE: This `activeSession.reloadSession` will probably cause the whole
    -- set of listeners, and the GHCi instance with them, to restart, but we
    -- signal a restart here as well for completeness sake.
    activeSession.reloadSession
    Sem.signal sem


reloadOnSourceChange
    :: ( Clock :> es
       , Log :> es
       , Pub EnteringNewPhase :> es
       , Pub NewLoadResult :> es
       , State BuildId :> es
       )
    => Eff es LoadResult
    -> SourceChangeDetected
    -> Eff es ()
reloadOnSourceChange reload SourceChangeDetected = do
    Log.debug $ "Builder: dirty flag set, reloading"
    buildId <- get
    publish $ EnteringNewPhase buildId $ Building Nothing
    startTime <- Clock.currentTime
    loadResult <- reload
    endTime <- Clock.currentTime
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
    => Session
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
            , durationMs = round (realToFrac (diffUTCTime endTime startTime) * 1000 :: Double) :: Int
            , moduleCount = loadResult.moduleCount
            , diagnostics = concat (Map.elems newAccumulated)
            , testRuns = []
            }
  where
    Session {watchDirs} = session
    NewLoadResult {startTime, endTime, loadResult} = newLoadResult


requestTestRunsForNewBuildResults
    :: ( Log :> es
       , Pub EnteringNewPhase :> es
       , State BuildId :> es
       , TestRunner :> es
       )
    => Session
    -> BuildResult
    -> Eff es ()
requestTestRunsForNewBuildResults session partialResult = do
    buildId <- get
    testRuns <- runTestsIfClean session buildId partialResult
    publish $ EnteringNewPhase buildId $ Done partialResult {testRuns}


-- Run all configured test suites if the build has no errors.
-- Transitions to 'Testing' phase while suites are running.
runTestsIfClean
    :: ( Log :> es
       , Pub EnteringNewPhase :> es
       , TestRunner :> es
       )
    => Session
    -> BuildId
    -> BuildResult
    -> Eff es [TestRun]
runTestsIfClean (Session {testTargets}) bid partialResult
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
