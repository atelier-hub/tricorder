module Tricorder.Observability
    ( Config (..)
    , MetricsConfig (..)
    , component
    ) where

import Data.Aeson (FromJSON, ToJSON)
import Data.Default (Default (..))
import Effectful (IOE)
import Effectful.Exception (IOException, try)
import Effectful.Reader.Static (Reader, ask)

import Atelier.Component (Component (..), Trigger, defaultComponent)
import Atelier.Effects.Delay (Delay)
import Atelier.Effects.Log (Log)
import Atelier.Effects.Monitoring.Tracing (TracingConfig)
import Atelier.Time (Millisecond)
import Atelier.Types.QuietSnake (QuietSnake (..))
import Atelier.Types.WithDefaults (WithDefaults (..))

import Atelier.Effects.Delay qualified as Delay
import Atelier.Effects.Log qualified as Log
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


component :: (Delay :> es, IOE :> es, Log :> es, Reader Config :> es) => Component es
component =
    defaultComponent
        { name = "Observability"
        , triggers = do
            cfg <- ask @Config
            pure
                $ if cfg.metrics.enabled then
                    [metricsServerTrigger cfg.metrics.port]
                else
                    []
        }


metricsServerTrigger :: (Delay :> es, IOE :> es, Log :> es) => Int -> Trigger es
metricsServerTrigger port = do
    result <- try @IOException $ liftIO $ Server.runMetricsServer port
    case result of
        Right () -> pure ()
        Left e ->
            Log.warn $ "Metrics server on port " <> show port <> " failed to start: " <> show e
    forever $ Delay.wait (3_600_000 :: Millisecond)
