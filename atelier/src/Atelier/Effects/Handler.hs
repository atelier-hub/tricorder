module Atelier.Effects.Handler
    ( Handler (..)
    , serveOnce
    , serveMany
    ) where

import Data.Aeson (ToJSON)
import Effectful (Effect)
import Effectful.TH (makeEffect)

import Atelier.Effects.Client (Multiplicity (..))


data Handler protocol :: Effect where
    ServeOnce :: (ToJSON a) => protocol Once a -> Handler protocol m a
    ServeMany :: protocol Many a -> (a -> m ()) -> Handler protocol m ()


makeEffect ''Handler
