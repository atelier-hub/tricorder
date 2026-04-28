module Main (main) where

import Data.Default (def)
import Effectful (runEff)
import Effectful.Concurrent (runConcurrent)
import Effectful.Reader.Static (runReader)

import Atelier.Effects.Cache (runCacheTtl)
import Atelier.Effects.Clock (runClock)
import Atelier.Effects.Conc (runConc)
import Atelier.Effects.Console (runConsole)
import Atelier.Effects.Debounce (runDebounce)
import Atelier.Effects.Delay (runDelay)
import Atelier.Effects.Exit (runExit)
import Atelier.Effects.File (runFile)
import Atelier.Effects.FileSystem (runFileSystemIO)
import Atelier.Effects.FileWatcher (runFileWatcherIO)
import Atelier.Effects.Monitoring.Tracing (runTracingNoOp)
import Atelier.Effects.Posix.Daemons (runDaemons)
import Tricorder.Arguments (runArguments)
import Tricorder.BuildState (runDaemonInfo)
import Tricorder.Config (runConfig)
import Tricorder.Effects.Brick (runBrick)
import Tricorder.Effects.BrickChan (runBrickChan)
import Tricorder.Effects.BuildStore (runBuildStore)
import Tricorder.Effects.DaemonClient (runDaemonClient)
import Tricorder.Effects.DaemonServer (runDaemonServer)
import Tricorder.Effects.GhcPkg (runGhcPkgIO)
import Tricorder.Effects.GhciSession (runGhciSessionIO)
import Tricorder.Effects.Logging (runLogging)
import Tricorder.Effects.TestRunner (runTestRunnerIO)
import Tricorder.Effects.UnixSocket (runUnixSocketIO)
import Tricorder.Runtime (runPidFile, runProjectRoot, runRuntimeDir, runSocketPath)

import Atelier.Effects.Cache.Config qualified as CacheConfig
import Tricorder qualified
import Tricorder.GhcPkg.Types qualified as GhcPkg


main :: IO ()
main =
    runEff
        . runConcurrent
        . runConc
        . runBrickChan
        . runBrick
        . runConsole
        . runExit
        . runClock
        . runTracingNoOp
        . runDelay
        . runFile
        . runFileSystemIO
        . runProjectRoot
        . runRuntimeDir
        . runPidFile
        . runSocketPath
        . runConfig
        . runReader @CacheConfig.Config def
        . runDaemonInfo
        . runLogging
        . runDaemons
        . runTestRunnerIO
        . runCacheTtl @GhcPkg.ModuleName @GhcPkg.PackageId
        . runCacheTtl @(GhcPkg.PackageId, GhcPkg.ModuleName) @Text
        . runGhciSessionIO
        . runFileWatcherIO
        . runDebounce
        . runGhcPkgIO
        . runBuildStore
        . runArguments
        . runUnixSocketIO
        . runDaemonClient
        . runDaemonServer
        $ Tricorder.run
