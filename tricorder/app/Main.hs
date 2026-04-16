module Main (main) where

import Effectful (runEff)
import Effectful.Concurrent (runConcurrent)

import Atelier.Effects.Clock (runClock)
import Atelier.Effects.Console (runConsole)
import Atelier.Effects.Delay (runDelay)
import Atelier.Effects.File (runFile)
import Atelier.Effects.FileSystem (runFileSystemIO)
import Atelier.Effects.Posix.Process (runProcess)
import Tricorder.Arguments (runArguments)
import Tricorder.Effects.Display (runDisplayIO)
import Tricorder.Effects.UnixSocket (runUnixSocketIO)

import Tricorder.Program qualified as Program


main :: IO ()
main =
    runEff
        . runConcurrent
        . runConsole
        . runProcess
        . runDelay
        . runFile
        . runFileSystemIO
        . runArguments
        . runClock
        . runUnixSocketIO
        . runDisplayIO
        $ Program.run
