module Ghcib.GhciSession (component, filterToWatchDirs, mergeDiagnostics, sessionListener) where

import Data.Time (diffUTCTime)
import Effectful.Exception (throwIO, try)
import Effectful.Reader.Static (Reader, ask)
import System.FilePath (isAbsolute, (</>))

import Data.Map.Strict qualified as Map

import Atelier.Component (Component (..), Listener, defaultComponent)
import Atelier.Effects.Clock (Clock)
import Atelier.Effects.Delay (Delay, wait)
import Atelier.Effects.FileSystem (FileSystem, getCurrentDirectory)
import Atelier.Effects.Log (Log)
import Atelier.Exception (isGracefulShutdown)
import Atelier.Time (Millisecond)
import Ghcib.BuildState (BuildId (..), BuildPhase (..), BuildResult (..), ChangeKind (..), Diagnostic (..))
import Ghcib.Config (Config (..), resolveCommand, resolveWatchDirs)
import Ghcib.Effects.BuildStore (BuildStore, setPhase, waitDirty)
import Ghcib.Effects.GhciSession (GhciSession, LoadResult (..))

import Atelier.Effects.Clock qualified as Clock
import Atelier.Effects.Log qualified as Log
import Ghcib.Effects.GhciSession qualified as GhciSession


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
            Log.debug $ "GhciSession.component: resolved command = " <> cmd
            Log.debug $ "GhciSession.component: projectRoot = " <> toText projectRoot
            pure [sessionListener cmd projectRoot watchDirs]
        }


sessionListener
    :: ( BuildStore :> es
       , Clock :> es
       , Delay :> es
       , GhciSession :> es
       , Log :> es
       )
    => Text
    -> FilePath
    -> [FilePath]
    -> Listener es
sessionListener cmd projectRoot watchDirs = startSession (BuildId 1)
  where
    filterDiags = filterToWatchDirs projectRoot watchDirs

    startSession (BuildId n) = do
        Log.info $ "Starting GHCi session #" <> show n <> ": " <> cmd
        t0 <- Clock.currentTime
        result <- try @SomeException $ GhciSession.startGhci cmd projectRoot
        Log.debug $ "GhciSession.startGhci returned (session #" <> show n <> ")"
        case result of
            Left ex -> do
                when (isGracefulShutdown ex) $ throwIO ex
                Log.err $ "Failed to start GHCi (session #" <> show n <> "): " <> show ex
                -- Brief pause before retry to avoid tight restart loop
                wait (2_000 :: Millisecond)
                startSession (BuildId n)
            Right LoadResult {moduleCount, diagnostics = msgs} -> do
                t1 <- Clock.currentTime
                let filteredMsgs = filterDiags msgs
                Log.info $ "GHCi started (session #" <> show n <> "): " <> show (length filteredMsgs) <> " diagnostics"
                let durationMs = round (realToFrac (diffUTCTime t1 t0) * 1000 :: Double) :: Int
                    buildResult = BuildResult {completedAt = t1, durationMs, moduleCount, diagnostics = filteredMsgs}
                    accumulated = Map.fromListWith (++) [(d.file, [d]) | d <- filteredMsgs]
                setPhase (BuildId n) (Done buildResult)
                Log.debug $ "Build state updated to Done (session #" <> show n <> ")"
                listenLoop (BuildId (n + 1)) accumulated

    listenLoop (BuildId n) accumulated = do
        Log.debug $ "GhciSession: waiting for dirty flag (build #" <> show n <> ")"
        changeKind <- waitDirty
        let nextId = BuildId (n + 1)
        case changeKind of
            CabalChange -> do
                Log.info "Cabal file changed; restarting GHCi session"
                void $ try @SomeException GhciSession.stopGhci
                startSession nextId
            SourceChange -> do
                Log.debug $ "GhciSession: dirty flag set, reloading"
                setPhase (BuildId n) Building
                t0 <- Clock.currentTime
                result <- try @SomeException GhciSession.reloadGhci
                case result of
                    Left ex -> do
                        when (isGracefulShutdown ex) $ throwIO ex
                        Log.warn "GHCi session died; restarting"
                        void $ try @SomeException GhciSession.stopGhci
                        startSession nextId
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
                            buildResult = BuildResult {completedAt = t1, durationMs, moduleCount = loadResult.moduleCount, diagnostics = allMsgs}
                        setPhase (BuildId n) (Done buildResult)
                        listenLoop nextId newAccumulated
