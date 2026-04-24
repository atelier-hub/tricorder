module Tricorder.Web.Config
    ( Config (..)
    , BasePath
    ) where

import Data.Default (Default (..))
import GHC.TypeLits (symbolVal)


data Config = Config
    { host :: String
    , port :: Int
    , path :: String
    }


instance Default Config where
    def =
        Config
            { host = "localhost"
            , port = 14333
            , path = symbolVal $ Proxy @BasePath
            }


type BasePath = "api"
