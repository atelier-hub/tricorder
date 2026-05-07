module Tricorder.GhciSession
    ( component
    , filterToWatchDirs
    , mergeDiagnostics
    , sessionListener
    ) where

import Control.Monad (foldM)
import Data.Time (diffUTCTime)
import Effectful.Exception (throwIO, trySync)
import Effectful.Reader.Static (Reader, ask)
import System.FilePath (isAbsolute, (</>))

import Data.Map.Strict qualified as Map

import Atelier.Component (Component (..), Listener, defaultComponent)
import Atelier.Effects.Clock (Clock, UTCTime)
import Atelier.Effects.Delay (Delay)
import Atelier.Effects.FileSystem (FileSystem, getCurrentDirectory)
import Atelier.Effects.Log (Log)
import Atelier.Exception (isGracefulShutdown)
import Atelier.Time (Millisecond)
import Tricorder.BuildState (BuildId (..), BuildPhase (..), BuildResult (..), ChangeKind (..), Diagnostic (..), Severity (..), TestRun (..))
import Tricorder.Config (Config (..), resolveCommand, resolveTestTargets, resolveWatchDirs)
import Tricorder.Effects.BuildStore (BuildStore)
import Tricorder.Effects.GhciSession (GhciSession, LoadResult (..))
import Tricorder.Effects.TestRunner (TestRunner)

import Atelier.Effects.Clock qualified as Clock
import Atelier.Effects.Delay qualified as Delay
import Atelier.Effects.Log qualified as Log
import Tricorder.Effects.BuildStore qualified as BuildStore
import Tricorder.Effects.GhciSession qualified as GhciSession
import Tricorder.Effects.TestRunner qualified as TestRunner


-- | Merge a new 'LoadResult' into the accumulated per-file diagnostic map.
--
-- Files in 'compiledFiles' have their previous diagnostics cleared and replaced
-- by any new diagnostics produced for them in this cycle. Files absent from
-- 'compiledFiles' were skipped by incremental compilation and retain their
-- previous diagnostics unchanged.
mergeDiagnostics :: Map.Map FilePath [Diagnostic] -> LoadResult -> Map.Map FilePath [Diagnostic]
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


-- | GhciSession component.
-- Starts a GHCi session, performs an initial load, then listens for reload
-- requests from the watcher. Catches UnexpectedExit and restarts the session
-- rather than propagating (the fix for ghcid's file-removal crash).
component
    :: ( BuildStore :> es
       , Clock :> es
       , Delay :> es
       , FileSystem :> es
       , GhciSession :> es
       , Log :> es
       , Reader Config :> es
       , TestRunner :> es
       )
    => Component es
component =
    defaultComponent
        { name = "GhciSession"
        , listeners = do
            cfg <- ask @Config
            projectRoot <- getCurrentDirectory
            cmd <- resolveCommand cfg projectRoot
            watchDirs <- resolveWatchDirs cfg projectRoot
            let testTargets = resolveTestTargets cfg
            Log.debug $ "GhciSession.component: resolved command = " <> cmd
            Log.debug $ "GhciSession.component: projectRoot = " <> toText projectRoot
            pure [sessionListener cmd projectRoot watchDirs testTargets]
        }


data SessionContinuation
    = Restart BuildId


sessionListener
    :: forall es
     . ( BuildStore :> es
       , Clock :> es
       , Delay :> es
       , GhciSession :> es
       , Log :> es
       , TestRunner :> es
       )
    => Text
    -> FilePath
    -> [FilePath]
    -> [Text]
    -> Listener es
sessionListener cmd projectRoot watchDirs testTargets = initSession (BuildId 1)
  where
    initSession (BuildId n) = do
        Log.info $ "Starting GHCi session #" <> show n <> ": " <> cmd
        BuildStore.setPhase (BuildId n) $ Building Nothing
        t0 <- Clock.currentTime
        res <- trySync $ GhciSession.withGhci cmd projectRoot \initialLoad@LoadResult {diagnostics = msgs} reload -> do
            t1 <- Clock.currentTime
            let filteredMsgs = filterDiags msgs
                partialResult = loadResultToBuildResult projectRoot watchDirs t0 t1 initialLoad
                accumulated = Map.fromListWith (++) [(d.file, [d]) | d <- filteredMsgs]
            Log.info $ "GHCi started (session #" <> show n <> "): " <> show (length filteredMsgs) <> " diagnostics"
            testRuns <- runTestsIfClean testTargets (BuildId n) partialResult
            BuildStore.setPhase (BuildId n) $ Done partialResult {testRuns}
            Log.debug $ "Build state updated to Done (session #" <> show n <> ")"
            loopSession reload (BuildId (n + 1)) accumulated
        case res of
            Left ex -> do
                Log.err $ "Failed to start GHCi (session #" <> show n <> "):" <> show ex
                Delay.wait (2_000 :: Millisecond)
                initSession (BuildId n)
            Right (Restart nextId) ->
                initSession nextId

    loopSession :: Eff es LoadResult -> BuildId -> Map FilePath [Diagnostic] -> Eff es SessionContinuation
    loopSession reload (BuildId n) accumulated = do
        Log.debug $ "GhciSession: waiting for dirty flag (build #" <> show n <> ")"
        changeKind <- BuildStore.waitDirty
        let nextId = BuildId (n + 1)
        case changeKind of
            CabalChange -> do
                Log.info "Cabal file changed; restarting GHCi session"
                BuildStore.setPhase (BuildId n) Restarting
                pure $ Restart nextId
            SourceChange -> do
                Log.debug $ "GhciSession: dirty flag set, reloading"
                BuildStore.setPhase (BuildId n) $ Building Nothing
                t0 <- Clock.currentTime
                -- TODO: Do better error handling here, or push it up the call tree.
                result <- Right <$> reload
                case result of
                    Left ex -> do
                        when (isGracefulShutdown ex) $ throwIO ex
                        Log.warn "GHCi session died; restarting"
                        pure $ Restart nextId
                    Right loadResult -> do
                        t1 <- Clock.currentTime
                        let filteredResult =
                                LoadResult
                                    { moduleCount = loadResult.moduleCount
                                    , compiledFiles = loadResult.compiledFiles
                                    , diagnostics = filterDiags loadResult.diagnostics
                                    }
                            durationMs = round (realToFrac (diffUTCTime t1 t0) * 1000 :: Double) :: Int
                            newAccumulated = mergeDiagnostics accumulated filteredResult
                            allMsgs = concat (Map.elems newAccumulated)
                        let partialResult = BuildResult {completedAt = t1, durationMs, moduleCount = loadResult.moduleCount, diagnostics = allMsgs, testRuns = []}
                        testRuns <- runTestsIfClean testTargets (BuildId n) partialResult
                        BuildStore.setPhase (BuildId n) $ Done partialResult {testRuns}
                        loopSession reload nextId newAccumulated

    filterDiags = filterToWatchDirs projectRoot watchDirs


-- Run all configured test suites if the build has no errors.
-- Transitions to 'Testing' phase while suites are running.
runTestsIfClean
    :: (BuildStore :> es, Log :> es, TestRunner :> es)
    => [Text] -> BuildId -> BuildResult -> Eff es [TestRun]
runTestsIfClean testTargets bid partialResult
    | not (null testTargets) && not (any (\d -> d.severity == SError) partialResult.diagnostics) = do
        let pendingRun = TestRunning
        BuildStore.setPhase bid (Testing partialResult {testRuns = map pendingRun testTargets})
        Log.info $ "Running " <> show (length testTargets) <> " test suite(s)"
        foldM
            ( \done target -> do
                Log.info $ "Running tests: " <> target
                result <- TestRunner.runTestSuite target
                let remaining = drop (length done + 1) testTargets
                    runs = done ++ [result] ++ map pendingRun remaining
                BuildStore.setPhase bid (Testing partialResult {testRuns = runs})
                pure (done ++ [result])
            )
            []
            testTargets
    | otherwise = pure []


loadResultToBuildResult :: FilePath -> [FilePath] -> UTCTime -> UTCTime -> LoadResult -> BuildResult
loadResultToBuildResult projectRoot watchDirs t0 t1 LoadResult {moduleCount, diagnostics = msgs} = do
    BuildResult {completedAt = t1, durationMs, moduleCount, diagnostics = filteredMsgs, testRuns = []}
  where
    filterDiags = filterToWatchDirs projectRoot watchDirs
    durationMs = round (realToFrac (diffUTCTime t1 t0) * 1000 :: Double) :: Int
    filteredMsgs = filterDiags msgs
