module Tricorder.CLI.Main (main) where

import Effectful (runEff)
import Effectful.Concurrent (runConcurrent)
import Effectful.Timeout (runTimeout)

import Atelier.Config (runConfig)
import Atelier.Effects.Clock (runClock)
import Atelier.Effects.Conc (runConc)
import Atelier.Effects.Console (runConsole)
import Atelier.Effects.Delay (runDelay)
import Atelier.Effects.Exit (runExit)
import Atelier.Effects.File (runFile)
import Atelier.Effects.FileSystem (runFileSystemIO)
import Atelier.Effects.Posix.Daemons (runDaemons)
import Tricorder.Arguments (runArguments)
import Tricorder.Config (runLoadedConfig)
import Tricorder.Effects.Brick (runBrick)
import Tricorder.Effects.BrickChan (runBrickChan)
import Tricorder.Effects.UnixSocket (runUnixSocketIO)
import Tricorder.Runtime (runLogPath, runPidFile, runProjectRoot, runRuntimeDir, runSocketPath)

import Tricorder qualified
import Tricorder.UI.Keys qualified as Keys


main :: IO ()
main =
    runEff
        . runTimeout
        . runConcurrent
        . runConc
        . runBrickChan
        . runBrick
        . runConsole
        . runExit
        . runClock
        . runDelay
        . runFile
        . runFileSystemIO
        . runProjectRoot
        . runRuntimeDir
        . runPidFile
        . runSocketPath
        . runLogPath
        . runLoadedConfig
        . runConfig @"keybindings" @Keys.Config
        . runDaemons
        . runArguments
        . runUnixSocketIO
        $ Tricorder.run
