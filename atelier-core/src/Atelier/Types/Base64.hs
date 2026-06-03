module Atelier.Types.Base64
    ( Base64 (..)
    ) where

import Data.Aeson (FromJSON (..), ToJSON (..), withText)

import Data.ByteString.Base64 qualified as Base64


-- | Newtype wrapper for deriving ToJSON/FromJSON with Base64 encoding.
newtype Base64 = Base64 {getBase64 :: ByteString}


instance ToJSON Base64 where
    toJSON = toJSON . decodeUtf8 @Text . Base64.encode . getBase64


instance FromJSON Base64 where
    parseJSON = withText "Base64" $ \t ->
        case Base64.decode (encodeUtf8 t) of
            Left err -> fail err
            Right b -> pure (Base64 b)
