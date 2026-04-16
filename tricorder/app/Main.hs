module Main (main) where

import Data.Default (def)
import Effectful (runEff)
import Effectful.Concurrent (runConcurrent)
import Effectful.Reader.Static (runReader)

import Atelier.Effects.Cache (runCacheTtl)
import Atelier.Effects.Clock (runClock)
import Atelier.Effects.Conc (runConc)
import Atelier.Effects.Console (runConsole)
import Atelier.Effects.Delay (runDelay)
import Atelier.Effects.File (runFile)
import Atelier.Effects.FileSystem (runFileSystemIO)
import Atelier.Effects.Monitoring.Tracing (runTracingNoOp)
import Atelier.Effects.Posix.Process (runProcess)
import Tricorder.Arguments (runArguments)
import Tricorder.BuildState (runDaemonInfo)
import Tricorder.Config (runConfig)
import Tricorder.Effects.Brick (runBrick)
import Tricorder.Effects.BrickChan (runBrickChan)
import Tricorder.Effects.BuildStore (runBuildStore)
import Tricorder.Effects.FileWatcher (runFileWatcherIO)
import Tricorder.Effects.GhcPkg (runGhcPkgIO)
import Tricorder.Effects.GhciSession (runGhciSessionIO)
import Tricorder.Effects.Logging (runLogging)
import Tricorder.Effects.TestRunner (runTestRunnerIO)
import Tricorder.Effects.UnixSocket (runUnixSocketIO)
import Tricorder.Project (runProjectRoot)
import Tricorder.Socket.SocketPath (runSocketPath)

import Atelier.Effects.Cache.Config qualified as CacheConfig
import Tricorder.GhcPkg.Types qualified as GhcPkg
import Tricorder.Program qualified as Program


main :: IO ()
main =
    runEff
        . runConcurrent
        . runConc
        . runBrickChan
        . runBrick
        . runConsole
        . runProcess
        . runClock
        . runTracingNoOp
        . runDelay
        . runFile
        . runFileSystemIO
        . runProjectRoot
        . runSocketPath
        . runConfig
        . runReader @CacheConfig.Config def
        . runDaemonInfo
        . runLogging
        . runTestRunnerIO
        . runCacheTtl @GhcPkg.ModuleName @GhcPkg.PackageId
        . runCacheTtl @(GhcPkg.PackageId, GhcPkg.ModuleName) @Text
        . runGhciSessionIO
        . runFileWatcherIO
        . runGhcPkgIO
        . runBuildStore
        . runArguments
        . runUnixSocketIO
        $ Program.run
