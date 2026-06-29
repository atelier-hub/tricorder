-- | The HTTP server, exposed as an atelier 'Component' running Warp over a
-- plain WAI 'Application'. Routes are dispatched by path and run in @Eff@.
module Canvas.Server
    ( component
    )
where

import Atelier.Component (Component (..), defaultComponent)
import Atelier.Effects.Log (Log)
import Atelier.Effects.Monitoring.Metrics (Metrics, exportMetrics)
import Effectful (IOE, Limit (..), Persistence (..), UnliftStrategy (..), withEffToIO)
import Effectful.Reader.Static (Reader, ask)
import Network.HTTP.Types (status200, status404)
import Network.Wai (Application, Response, pathInfo, responseLBS)
import Network.Wai.Handler.Warp (defaultSettings, runSettings, setHost, setPort)

import Atelier.Effects.Log qualified as Log
import Data.Aeson qualified as Aeson

import Canvas.Config (Config (..), ServerConfig (..))
import Canvas.Effects.ItemRepo (ItemRepo, listItems)


-- | The server component. Its @start@ phase binds Warp and blocks; 'runSystem'
-- forks start phases, so this does not block system startup.
component
    :: ( IOE :> es
       , ItemRepo :> es
       , Log :> es
       , Metrics :> es
       , Reader Config :> es
       )
    => Component es
component =
    defaultComponent
        { name = "Server"
        , start = do
            cfg <- ask @Config
            let host = cfg.server.host
                port = cfg.server.port

            Log.info $ "Starting canvas on " <> host <> ":" <> show port

            let settings = setPort port $ setHost (fromString (toString host)) defaultSettings

            app <-
                withEffToIO (ConcUnlift Persistent Unlimited) \unlift ->
                    pure \request respond -> do
                        response <- unlift (route request)
                        respond response

            liftIO $ runSettings settings (app :: Application)
        }
  where
    plain = ("Content-Type", "text/plain; charset=utf-8")
    json = ("Content-Type", "application/json")

    route request =
        case pathInfo request of
            [] -> ok "canvas is running\n"
            ["health"] -> ok "ok"
            ["metrics"] -> do
                metrics <- exportMetrics
                pure $ responseLBS status200 [plain] (encodeUtf8 metrics)
            ["items"] -> do
                items <- listItems
                pure $ responseLBS status200 [json] (Aeson.encode items)
            _ -> pure $ responseLBS status404 [plain] "not found\n"

    ok :: (Applicative f) => LByteString -> f Response
    ok = pure . responseLBS status200 [plain]
