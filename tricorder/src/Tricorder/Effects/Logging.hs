module Tricorder.Effects.Logging (runLogging) where

import Effectful (IOE)
import Effectful.Reader.Static (Reader, asks)

import Atelier.Effects.File (File)
import Atelier.Effects.Log (Log, Severity (..), runLogNoOp, runLogToHandle)

import Atelier.Effects.File qualified as File
import Tricorder.Observability qualified as Observability


runLogging :: (File :> es, IOE :> es, Reader Observability.Config :> es) => Eff (Log : es) a -> Eff es a
runLogging act = do
    logFile <- asks @Observability.Config (.logFile)
    case logFile of
        Nothing -> runLogNoOp act
        Just path -> File.withFile path AppendMode \h -> do
            File.hSetBuffering h LineBuffering
            runLogToHandle h INFO act
