module Tricorder.Session.PidFile
    ( PidFile (..)
    , asReader
    ) where

import Effectful.Reader.Static (Reader, ask, runReader)
import System.FilePath ((</>))

import Atelier.Effects.Posix.Daemons (PidFile (..))
import Tricorder.Session.RuntimeDir (RuntimeDir (..))


asReader :: (Reader RuntimeDir :> es) => Eff (Reader PidFile : es) a -> Eff es a
asReader act = do
    RuntimeDir runtimeDir <- ask
    runReader (PidFile $ runtimeDir </> "daemon.pid") act
