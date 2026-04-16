module Tricorder.Observability
    ( component
    ) where

import Effectful (IOE)
import Effectful.Reader.Static (Reader, ask)

import Atelier.Component (Component (..), defaultComponent)
import Tricorder.Config (Config (..))

import Atelier.Effects.Monitoring.Metrics.Server qualified as Server


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
