module Ghcib.Daemon
    ( runDaemon
    , startDaemon
    , stopDaemon
    ) where

import Control.Exception (try)
import Effectful (runEff)
import Effectful.Concurrent (runConcurrent)
import Effectful.Reader.Static (runReader)
import System.Directory (removeFile)
import System.FilePath (makeRelative)
import System.Posix.Process (createSession, forkProcess)

import Atelier.Component (runSystem)
import Atelier.Effects.Clock (runClock)
import Atelier.Effects.Conc (runConc)
import Atelier.Effects.Delay (runDelay)
import Atelier.Effects.Log (Severity (..), runLogNoOp, runLogToHandle)
import Atelier.Effects.Monitoring.Tracing (runTracingNoOp)
import Ghcib.BuildState (DaemonInfo (..))
import Ghcib.Config (Config (..), loadConfig, resolveWatchDirs)
import Ghcib.Effects.BuildStore (runBuildStore)
import Ghcib.Effects.FileWatcher (runFileWatcherIO)
import Ghcib.Effects.GhciSession (runGhciSessionIO)
import Ghcib.Effects.UnixSocket (runUnixSocketIO)
import Ghcib.Socket.Client (socketPath)

import Atelier.Effects.Conc qualified as Conc
import Ghcib.GhciSession qualified as GhciSession
import Ghcib.Socket.Server qualified as SocketServer
import Ghcib.Watcher qualified as Watcher


-- | Run the daemon for the given project root.
-- Blocks forever; all work happens inside the component system.
runDaemon :: FilePath -> Config -> IO ()
runDaemon projectRoot cfg = do
    sockPath <- socketPath projectRoot
    watchDirs <- resolveWatchDirs cfg.targets projectRoot
    let daemonInfo =
            DaemonInfo
                { targets = cfg.targets
                , watchDirs = map (makeRelative projectRoot) watchDirs
                , sockPath
                , logFile = cfg.logFile
                }
    case cfg.logFile of
        Nothing -> runWith runLogNoOp sockPath daemonInfo
        Just path -> withFile path AppendMode $ \h -> do
            hSetBuffering h LineBuffering
            runWith (runLogToHandle h INFO) sockPath daemonInfo
  where
    runWith runLogger sockPath daemonInfo =
        runEff
            . runConcurrent
            . runTracingNoOp
            . runLogger
            . runClock
            . runDelay
            . runConc
            . runFileWatcherIO
            . runGhciSessionIO
            . runUnixSocketIO
            . runReader cfg
            $ do
                runBuildStore daemonInfo do
                    runSystem
                        [ Watcher.component
                        , GhciSession.component
                        , SocketServer.component sockPath
                        ]
                    Conc.awaitAll


-- | Fork the daemon as a background process and return immediately.
-- No-op if the daemon is already running (caller should check beforehand).
startDaemon :: FilePath -> IO ()
startDaemon projectRoot = do
    cfg <- loadConfig projectRoot
    void $ forkProcess do
        void createSession -- detach from terminal
        runDaemon projectRoot cfg


-- | Remove the daemon's socket file, which causes the socket server to stop.
-- The daemon process itself will exit once its scope closes.
stopDaemon :: FilePath -> IO ()
stopDaemon projectRoot = do
    sockPath <- socketPath projectRoot
    try @SomeException (removeFile sockPath) >> pure ()
