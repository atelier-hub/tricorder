module Atelier.Effects.Timeout
    ( Timeout
    , timeout
    , runTimeout
    ) where

import Effectful (Effect, IOE, Limit (..), Persistence (..), UnliftStrategy (..))
import Effectful.Dispatch.Dynamic (interpret, localUnliftIO)
import Effectful.TH (makeEffect)

import System.Timeout qualified as IO

import Atelier.Time (TimeUnit (..))


data Timeout :: Effect where
    Timeout :: (TimeUnit t) => t -> m a -> Timeout m (Maybe a)


makeEffect ''Timeout


runTimeout :: (HasCallStack, IOE :> es) => Eff (Timeout : es) a -> Eff es a
runTimeout = interpret \env -> \case
    Timeout delay action ->
        localUnliftIO env (ConcUnlift Persistent (Limited 1)) \unlift ->
            IO.timeout (fromIntegral $ toMicroseconds delay) $ unlift action
