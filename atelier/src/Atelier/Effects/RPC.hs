module Atelier.Effects.RPC
    ( Multiplicity (..)
    , Client (..)
    , runRequest
    , runStream
    , Handler (..)
    , serveOnce
    , serveMany
    , SomeRPC (..)
    , dispatch
    , encodeText
    ) where

import Data.Aeson (FromJSON, ToJSON, decode, encode, object, (.=))
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


data SomeRPC protocol
    = forall a. (ToJSON a) => OnceRPC (protocol Once a)
    | forall a. (ToJSON a) => ManyRPC (protocol Many a)


-- | Decode one wire-format request line and route it to the appropriate
-- 'Handler' operation, sending each response back through the supplied
-- @send@ callback.
--
-- Polymorphic over @protocol@: any GADT with @FromJSON (SomeRPC protocol)@
-- (typically derived via 'Atelier.Effects.RPC.TH.makeProtocol') gets dispatch
-- for free. On parse failure, sends a JSON object @{"message":"invalid request"}@.
dispatch
    :: forall protocol es
     . ( FromJSON (SomeRPC protocol)
       , Handler protocol :> es
       )
    => (Text -> Eff es ())
    -> Text
    -> Eff es ()
dispatch send line =
    case decode @(SomeRPC protocol) (BSL.fromStrict (encodeUtf8 line)) of
        Nothing -> send (encodeText invalidRequest)
        Just (OnceRPC req) -> serveOnce req >>= send . encodeText
        Just (ManyRPC req) -> serveMany req (send . encodeText)
  where
    invalidRequest = object ["message" .= ("invalid request" :: Text)]


encodeText :: (ToJSON a) => a -> Text
encodeText = decodeUtf8 . BSL.toStrict . encode
