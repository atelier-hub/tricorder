module Atelier.Effects.RPC
    ( Multiplicity (..)
    , Client (..)
    , runRequest
    , runStream
    , Handler (..)
    , serveOnce
    , serveMany
    , encodeText
    ) where

import Data.Aeson (FromJSON, ToJSON, encode)
import Effectful (Effect)
import Effectful.TH (makeEffect)

import Data.ByteString.Lazy qualified as BSL


data Multiplicity = Once | Many


data Client protocol :: Effect where
    RunRequest
        :: (FromJSON a, ToJSON (protocol Once a))
        => protocol Once a -> Client protocol m (Either Text a)
    RunStream
        :: (FromJSON a, ToJSON (protocol Many a))
        => protocol Many a -> (a -> m ()) -> Client protocol m ()


makeEffect ''Client


data Handler protocol :: Effect where
    ServeOnce :: (ToJSON a) => protocol Once a -> Handler protocol m a
    ServeMany :: protocol Many a -> (a -> m ()) -> Handler protocol m ()


makeEffect ''Handler


encodeText :: (ToJSON a) => a -> Text
encodeText = decodeUtf8 . BSL.toStrict . encode
