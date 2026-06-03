module Atelier.Types.WithDefaults
    ( WithDefaults (..)
    ) where

import Data.Aeson (FromJSON (..), ToJSON (..), Value (..))
import Data.Default (Default (..))

import Data.Aeson.KeyMap qualified as KM


-- | Newtype wrapper that merges default-instance values into incoming JSON before
-- parsing, so non-Maybe fields absent from the input fall back to their 'Default'
-- values rather than causing a parse failure.
newtype WithDefaults a = WithDefaults {getWithDefaults :: a}


instance (Default a, FromJSON a, ToJSON a) => FromJSON (WithDefaults a) where
    parseJSON v = WithDefaults <$> parseJSON merged
      where
        merged = mergeLeft (toJSON (def :: a)) v

        mergeLeft (Object l) (Object r) = Object $ KM.unionWith mergeLeft l r
        mergeLeft _ r = r
