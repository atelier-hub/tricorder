-- | HTTP server for exposing Prometheus metrics.
module Atelier.Effects.Monitoring.Metrics.Server
    ( runMetricsServer
    ) where

import Network.HTTP.Types (status200)
import Network.Wai (Application, responseLBS)

import Network.Wai.Handler.Warp qualified as Warp
import Prometheus qualified as Prom


metricsApp :: Application
metricsApp _req respond = do
    payload <- Prom.exportMetricsAsText
    respond
        $ responseLBS
            status200
            [("Content-Type", "text/plain; version=0.0.4; charset=utf-8")]
            payload


-- | Start an HTTP server that exposes Prometheus metrics at any path.
-- Blocks forever; intended to be run in a background thread.
runMetricsServer :: Int -> IO ()
runMetricsServer port = Warp.run port metricsApp
