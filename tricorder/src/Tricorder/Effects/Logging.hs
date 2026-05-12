module Tricorder.Effects.Logging (runLogging) where

import Effectful (IOE)
import Effectful.Reader.Static (Reader, asks)

import Atelier.Effects.File (File)
import Atelier.Effects.Log (Log, Severity (..), runLogToHandle)
import Tricorder.Runtime (LogPath (..))

import Atelier.Effects.File qualified as File


runLogging :: (File :> es, IOE :> es, Reader LogPath :> es) => Eff (Log : es) a -> Eff es a
runLogging act = do
    path <- asks @LogPath (.getLogPath)
    File.withFile path AppendMode \h -> do
        File.hSetBuffering h LineBuffering
        runLogToHandle h INFO act
