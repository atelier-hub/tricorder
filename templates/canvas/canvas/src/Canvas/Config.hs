-- | Application configuration, loaded from a YAML file (see @config/dev.yaml@).
module Canvas.Config
    ( Config (..)
    , ServerConfig (..)
    , loadConfig
    )
where

import Atelier.Effects.DB.Config (DBConfig)
import Atelier.Types.QuietSnake (QuietSnake (..))
import Data.Aeson (FromJSON)

import Data.Yaml qualified as Yaml


-- | HTTP server bind settings.
data ServerConfig = ServerConfig
    { host :: Text
    , port :: Int
    }
    deriving stock (Eq, Generic, Show)
    deriving (FromJSON) via QuietSnake ServerConfig


-- | Top-level application configuration.
data Config = Config
    { server :: ServerConfig
    , database :: DBConfig
    }
    deriving stock (Eq, Generic, Show)
    deriving (FromJSON) via QuietSnake Config


-- | Read and decode a YAML config file, throwing on parse failure.
loadConfig :: FilePath -> IO Config
loadConfig = Yaml.decodeFileThrow
