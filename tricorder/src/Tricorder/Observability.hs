module Tricorder.Observability
    ( Config (..)
    , component
    ) where

import Data.Aeson (FromJSON)
import Data.Default (Default (..))
import Effectful (IOE)
import Effectful.Reader.Static (Reader, ask)

import Atelier.Component (Component (..), defaultComponent)
import Atelier.Types.QuietSnake (QuietSnake (..))

import Atelier.Effects.Monitoring.Metrics.Server qualified as Server


data Config = Config
    { metricsPort :: Maybe Int
    , logFile :: Maybe FilePath
    }
    deriving stock (Eq, Generic, Show)
    deriving (FromJSON) via QuietSnake Config


instance Default Config where
    def = Config {metricsPort = Nothing, logFile = Nothing}


component :: (IOE :> es, Reader Config :> es) => Component es
component =
    defaultComponent
        { name = "Observability"
        , triggers = do
            cfg <- ask @Config
            pure $ case cfg.metricsPort of
                Nothing -> []
                Just port -> [liftIO $ forever $ Server.runMetricsServer port]
        }
