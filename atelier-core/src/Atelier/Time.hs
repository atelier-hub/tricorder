{-# OPTIONS_GHC -Wno-orphans #-}

module Atelier.Time
    ( -- * Time units
      TimeUnit
    , Microsecond
    , Millisecond
    , Second
    , Minute
    , Hour

      -- * Conversions
    , nominalDiffTime
    , fromMicroseconds
    , toMicroseconds
    , convertUnit
    ) where

import Data.Aeson (FromJSON (..), ToJSON (..))
import Data.Time (NominalDiffTime)
import Data.Time.Units (Hour, Microsecond, Millisecond, Minute, Second, TimeUnit, convertUnit, fromMicroseconds, toMicroseconds)


nominalDiffTime :: (TimeUnit t) => NominalDiffTime -> t
nominalDiffTime = fromMicroseconds . round @Double . (* 1_000_000) . realToFrac


-- Orphan instances for JSON deserialization of time unit types.
-- All time units in Data.Time.Units wrap Integer, so we parse as Integer.

instance FromJSON Microsecond where
    parseJSON = fmap fromInteger . parseJSON


instance FromJSON Millisecond where
    parseJSON = fmap fromInteger . parseJSON


instance FromJSON Second where
    parseJSON = fmap fromInteger . parseJSON


instance FromJSON Minute where
    parseJSON = fmap fromInteger . parseJSON


instance FromJSON Hour where
    parseJSON = fmap fromInteger . parseJSON


instance ToJSON Microsecond where
    toJSON us = toJSON (toMicroseconds us)


instance ToJSON Millisecond where
    toJSON ms = toJSON (toMicroseconds ms `div` 1000)


instance ToJSON Second where
    toJSON s = toJSON (toMicroseconds s `div` 1_000_000)


instance ToJSON Minute where
    toJSON m = toJSON (toMicroseconds m `div` 60_000_000)


instance ToJSON Hour where
    toJSON h = toJSON (toMicroseconds h `div` 3_600_000_000)
