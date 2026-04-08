module Main (main) where

import Effectful (runEff)
import Effectful.Concurrent (runConcurrent)

import Atelier.Effects.Clock (runClock)
import Atelier.Effects.Console (runConsole)
import Atelier.Effects.Delay (runDelay)
import Atelier.Effects.File (runFile)
import Atelier.Effects.FileSystem (runFileSystemIO)
import Ghcib.Arguments (runArguments)
import Ghcib.Effects.Display (runDisplayIO)
import Ghcib.Effects.UnixSocket (runUnixSocketIO)

import Ghcib.Program qualified as Program


main :: IO ()
main =
    runEff
        . runConcurrent
        . runConsole
        . runDelay
        . runFile
        . runFileSystemIO
        . runArguments
        . runClock
        . runUnixSocketIO
        . runDisplayIO
        $ Program.run
