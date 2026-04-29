module Atelier.Effects.Client
    ( Client (..)
    , Multiplicity (..)
    , runRequest
    , runStream
    ) where

import Data.Aeson (FromJSON, ToJSON)
import Effectful (Effect)
import Effectful.TH (makeEffect)


data Multiplicity = Once | Many


data Client protocol :: Effect where
    RunRequest
        :: (FromJSON a, ToJSON (protocol Once a))
        => protocol Once a -> Client protocol m (Either Text a)
    RunStream
        :: (FromJSON a, ToJSON (protocol Many a))
        => protocol Many a -> (a -> m ()) -> Client protocol m ()


makeEffect ''Client
