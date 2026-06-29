-- | Wiring: load config, acquire database pools, interpret the effect stack,
-- and run the component system.
module Canvas.App
    ( main
    )
where

import Atelier.Component (runSystem)
import Atelier.Effects.Arguments (execParser, runArgumentsIO)
import Atelier.Effects.Clock (runClock)
import Atelier.Effects.Conc (runConc)
import Atelier.Effects.DB (runDB)
import Atelier.Effects.DB.Config (acquireDatabasePools)
import Atelier.Effects.Log (Severity (..), runLogToHandle)
import Atelier.Effects.Monitoring.Metrics (runMetrics)
import Atelier.Effects.Monitoring.Tracing (runTracingNoOp)
import Effectful (IOE, runEff)
import Effectful.Concurrent (runConcurrent)
import Effectful.Error.Static (Error, runErrorNoCallStack)
import Effectful.Reader.Static (runReader)
import System.IO (stdout)

import Canvas.Arguments (Options (..), optionsInfo)
import Canvas.Config (Config (..), loadConfig)
import Canvas.Effects.ItemRepo (runItemRepo)
import Canvas.Metrics (dbMetricNames)

import Canvas.Server qualified as Server


-- | Turn an @Error Text@ into an IO failure at the program boundary.
runErrorText :: (IOE :> es) => Eff (Error Text : es) a -> Eff es a
runErrorText action = do
    result <- runErrorNoCallStack action
    either (liftIO . fail . toString) pure result


main :: IO ()
main =
    runEff . runArgumentsIO $ do
        options <- execParser optionsInfo
        config <- liftIO $ loadConfig options.configPath

        -- Reader and writer share one role in the scaffold; split them later for
        -- least-privilege access.
        pools <- liftIO $ acquireDatabasePools config.database config.database

        runConcurrent
            . runClock
            . runTracingNoOp
            . runLogToHandle stdout DEBUG
            . runMetrics
            . runConc
            . runErrorText
            . runReader config
            . runReader pools
            . runDB dbMetricNames
            . runItemRepo
            $ runSystem [Server.component]
