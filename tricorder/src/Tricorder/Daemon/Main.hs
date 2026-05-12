module Tricorder.Daemon.Main (main) where

import Data.Default (def)
import Effectful (runEff)
import Effectful.Concurrent (runConcurrent)
import Effectful.Reader.Static (runReader)
import Effectful.State.Static.Shared (evalState)
import Effectful.Timeout (runTimeout)

import Atelier.Component (runSystem)
import Atelier.Config (runConfig)
import Atelier.Effects.Cache (runCacheTtl)
import Atelier.Effects.Chan (runChan)
import Atelier.Effects.Clock (runClock)
import Atelier.Effects.Conc (runConc)
import Atelier.Effects.Debounce (runDebounce)
import Atelier.Effects.Delay (runDelay)
import Atelier.Effects.Exit (runExit)
import Atelier.Effects.File (runFile)
import Atelier.Effects.FileSystem (runFileSystemIO)
import Atelier.Effects.FileWatcher (runFileWatcherIO)
import Atelier.Effects.Monitoring.Tracing (TracingConfig, runTracingFromConfig)
import Atelier.Effects.Publishing (runPubSub)
import Tricorder.BuildState (BuildId (..), runDaemonInfo)
import Tricorder.Config (runLoadedConfig)
import Tricorder.Effects.BuildStore (runBuildStore)
import Tricorder.Effects.GhcPkg (runGhcPkgIO)
import Tricorder.Effects.GhciSession (runGhciSessionIO)
import Tricorder.Effects.Logging (runLogging)
import Tricorder.Effects.TestRunner (runTestRunnerIO)
import Tricorder.Effects.UnixSocket (runUnixSocketIO)
import Tricorder.Runtime (runLogPath, runProjectRoot, runRuntimeDir, runSocketPath)
import Tricorder.Session (runSession)

import Atelier.Effects.Cache.Config qualified as CacheConfig
import Atelier.Effects.Log qualified as Log
import Tricorder.BuildState qualified as BuildState
import Tricorder.Builder qualified as Builder
import Tricorder.GhcPkg.Types qualified as GhcPkg
import Tricorder.Observability qualified as Observability
import Tricorder.Socket.Server qualified as SocketServer
import Tricorder.Version qualified as Version
import Tricorder.Watcher qualified as Watcher


-- | Run the daemon for the given project root.
-- Blocks forever; all work happens inside the component system.
main :: IO ()
main =
    runEff
        . runTimeout
        . runConcurrent
        . runConc
        . runExit
        . runClock
        . runDelay
        . runFile
        . runFileSystemIO
        . runProjectRoot
        . runRuntimeDir
        . runSocketPath
        . runLogPath
        . runLoadedConfig
        . runSession
        . runConfig @"observability" @Observability.Config
        . runConfig @"observability.tracing" @TracingConfig
        . runTracingFromConfig
        . runReader @CacheConfig.Config def
        . runChan
        . runPubSub @Watcher.WatchedFile
        . runPubSub @Builder.NewLoadResult
        . runPubSub @BuildState.BuildResult
        . runPubSub @BuildState.CabalChangeDetected
        . runPubSub @BuildState.SourceChangeDetected
        . runPubSub @BuildState.EnteredNewPhase
        . runPubSub @BuildState.EnteringNewPhase
        . runDaemonInfo
        . runLogging
        . runTestRunnerIO
        . runCacheTtl @GhcPkg.ModuleName @GhcPkg.PackageId
        . runCacheTtl @(GhcPkg.PackageId, GhcPkg.ModuleName) @Text
        . runBuildStore
        . runFileWatcherIO
        . runDebounce
        . runGhcPkgIO
        . runUnixSocketIO
        . runGhciSessionIO
        . evalState (BuildId 1)
        . evalState @Builder.DiagnosticMap mempty
        $ do
            Log.info $ "Starting tricorder " <> Version.gitHash
            runSystem
                [ Observability.component
                , Watcher.component
                , Builder.component
                , SocketServer.component
                ]
