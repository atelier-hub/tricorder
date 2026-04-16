module Tricorder.Daemon
    ( runDaemon
    , startDaemon
    , stopDaemon
    ) where

import Control.Exception (try)
import Data.Default (def)
import Effectful (IOE, runEff)
import Effectful.Concurrent (runConcurrent)
import Effectful.Reader.Static (runReader)
import System.FilePath (makeRelative)

import Atelier.Component (runSystem)
import Atelier.Effects.Cache (runCacheTtl)
import Atelier.Effects.Clock (runClock)
import Atelier.Effects.Conc (runConc)
import Atelier.Effects.Delay (runDelay)
import Atelier.Effects.FileSystem (FileSystem, removeFile, runFileSystemIO)
import Atelier.Effects.Log (Severity (..), runLogNoOp, runLogToHandle)
import Atelier.Effects.Monitoring.Metrics (runMetrics)
import Atelier.Effects.Monitoring.Tracing (runTracingNoOp)
import Atelier.Effects.Posix.Process (Process, createSession, forkProcess)
import Tricorder.BuildState (DaemonInfo (..))
import Tricorder.Config (Config (..), loadConfig, resolveTargets, resolveWatchDirs)
import Tricorder.Effects.BuildStore (runBuildStore)
import Tricorder.Effects.FileWatcher (runFileWatcherIO)
import Tricorder.Effects.GhcPkg (runGhcPkgIO)
import Tricorder.Effects.GhciSession (runGhciSessionIO)
import Tricorder.Effects.TestRunner (runTestRunnerIO)
import Tricorder.Effects.UnixSocket (runUnixSocketIO)
import Tricorder.GhcPkg.Types (ModuleName, PackageId)
import Tricorder.Socket.Client (socketPath)

import Atelier.Effects.Cache.Config qualified as CacheConfig
import Atelier.Effects.Conc qualified as Conc
import Tricorder.Config qualified as Config
import Tricorder.GhciSession qualified as GhciSession
import Tricorder.Observability qualified as Observability
import Tricorder.Socket.Server qualified as SocketServer
import Tricorder.Watcher qualified as Watcher


-- | Run the daemon for the given project root.
-- Blocks forever; all work happens inside the component system.
runDaemon :: FilePath -> Config -> IO ()
runDaemon projectRoot cfg = do
    (sockPath, effectiveTargets, watchDirs) <-
        runEff . runFileSystemIO $ do
            sp <- socketPath projectRoot
            et <- resolveTargets cfg.targets projectRoot
            let effectiveCfg' = cfg {Config.targets = et}
            wd <- resolveWatchDirs effectiveCfg' projectRoot
            pure (sp, et, wd)
    let effectiveCfg = cfg {Config.targets = effectiveTargets}
    let daemonInfo =
            DaemonInfo
                { targets = effectiveTargets
                , watchDirs = map (makeRelative projectRoot) watchDirs
                , sockPath
                , logFile = cfg.logFile
                , metricsPort = cfg.metricsPort
                }
    case cfg.logFile of
        Nothing -> runWith runLogNoOp sockPath daemonInfo effectiveCfg
        Just path -> withFile path AppendMode $ \h -> do
            hSetBuffering h LineBuffering
            runWith (runLogToHandle h INFO) sockPath daemonInfo effectiveCfg
  where
    runWith runLogger sockPath daemonInfo effectiveCfg =
        runEff
            . runConcurrent
            . runTracingNoOp
            . runLogger
            . runClock
            . runMetrics
            . runDelay
            . runConc
            . runFileWatcherIO
            . runGhciSessionIO
            . runTestRunnerIO projectRoot
            . runUnixSocketIO
            . runFileSystemIO
            . runReader effectiveCfg
            . runReader (def :: CacheConfig.Config)
            . runGhcPkgIO
            . runCacheTtl @ModuleName @PackageId
            . runCacheTtl @(PackageId, ModuleName) @Text
            $ do
                runBuildStore daemonInfo do
                    runSystem
                        [ Observability.component
                        , Watcher.component
                        , GhciSession.component
                        , SocketServer.component sockPath
                        ]
                    Conc.awaitAll


-- | Fork the daemon as a background process and return immediately.
-- No-op if the daemon is already running (caller should check beforehand).
startDaemon :: (FileSystem :> es, IOE :> es, Process :> es) => FilePath -> Eff es ()
startDaemon projectRoot = do
    cfg <- loadConfig projectRoot
    void $ forkProcess do
        void createSession -- detach from terminal
        liftIO $ runDaemon projectRoot cfg


-- | Remove the daemon's socket file, which causes the socket server to stop.
-- The daemon process itself will exit once its scope closes.
stopDaemon :: FilePath -> IO ()
stopDaemon projectRoot = do
    sockPath <- runEff . runFileSystemIO $ socketPath projectRoot
    void $ try @SomeException $ runEff . runFileSystemIO $ removeFile sockPath
