{-# LANGUAGE UndecidableInstances #-}

module Atelier.Types.QuietSnake
    ( QuietSnake (..)
    ) where

import Data.Aeson (FromJSON (..), GFromJSON, GToJSON, Options, ToJSON (..), Zero, genericParseJSON, genericToJSON)
import Data.Aeson.Types (defaultOptions, fieldLabelModifier)
import GHC.Generics (Rep)
import Text.Casing (quietSnake)


-- | Newtype wrapper for deriving FromJSON with quiet_snake_case field names
newtype QuietSnake a = QuietSnake {getQuietSnake :: a}


instance (GFromJSON Zero (Rep a), Generic a) => FromJSON (QuietSnake a) where
    parseJSON = fmap QuietSnake . genericParseJSON opts


instance (GToJSON Zero (Rep a), Generic a) => ToJSON (QuietSnake a) where
    toJSON = genericToJSON opts . getQuietSnake


opts :: Options
opts = defaultOptions {fieldLabelModifier = quietSnake}
