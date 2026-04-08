module Main (main) where

import Effectful (runEff)

import Atelier.Effects.Clock (runClock)
import Atelier.Effects.Console (runConsole)
import Atelier.Effects.FileSystem (runFileSystemIO)
import Ghcib.Arguments (runArguments)
import Ghcib.Effects.Display (runDisplayIO)
import Ghcib.Effects.UnixSocket (runUnixSocketIO)

import Ghcib.Program qualified as Program


main :: IO ()
main =
    runEff
        . runConsole
        . runFileSystemIO
        . runArguments
        . runClock
        . runUnixSocketIO
        . runDisplayIO
        $ Program.run
