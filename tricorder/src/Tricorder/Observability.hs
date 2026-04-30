module Tricorder.Observability
    ( Config (..)
    , MetricsConfig (..)
    , component
    ) where

import Data.Aeson (FromJSON, ToJSON)
import Data.Default (Default (..))
import Effectful (IOE)
import Effectful.Reader.Static (Reader, ask)

import Atelier.Component (Component (..), defaultComponent)
import Atelier.Effects.Monitoring.Tracing (TracingConfig)
import Atelier.Types.QuietSnake (QuietSnake (..))
import Atelier.Types.WithDefaults (WithDefaults (..))

import Atelier.Effects.Monitoring.Metrics.Server qualified as Server


data MetricsConfig = MetricsConfig
    { enabled :: Bool
    , port :: Int
    }
    deriving stock (Eq, Generic, Show)
    deriving (ToJSON) via QuietSnake MetricsConfig
    deriving (FromJSON) via WithDefaults (QuietSnake MetricsConfig)


instance Default MetricsConfig where
    def = MetricsConfig {enabled = False, port = 9091}


data Config = Config
    { metrics :: MetricsConfig
    , logFile :: Maybe FilePath
    , tracing :: TracingConfig
    }
    deriving stock (Eq, Generic, Show)
    deriving (FromJSON) via QuietSnake Config


instance Default Config where
    def = Config {metrics = def, logFile = Nothing, tracing = def}


component :: (IOE :> es, Reader Config :> es) => Component es
component =
    defaultComponent
        { name = "Observability"
        , triggers = do
            cfg <- ask @Config
            pure
                $ if cfg.metrics.enabled then
                    [liftIO $ forever $ Server.runMetricsServer cfg.metrics.port]
                else
                    []
        }
