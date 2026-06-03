module Atelier.Types.JsonReadShow (JsonReadShow (..)) where

import Data.Aeson (FromJSON (..), ToJSON (..), Value (..), withText)
import Data.Typeable (typeRep)


newtype JsonReadShow a = JsonReadShow {getJsonReadShow :: a}


instance forall a. (Read a, Typeable a) => FromJSON (JsonReadShow a) where
    parseJSON =
        let
            typeName = show $ typeRep $ Proxy @a
        in
            withText typeName
                $ maybe
                    (fail $ "Failed to read " <> typeName)
                    (pure . JsonReadShow)
                    . readMaybe
                    . toString


instance (Show a) => ToJSON (JsonReadShow a) where
    toJSON = String . show . getJsonReadShow
