module Atelier.Effects.Timeout
    ( Timeout
    , timeout
    , timeout_
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


-- | Like 'timeout', but for times where you do not need the result. If you
-- need to distinguish whether the action ran to completion, or whether it
-- timed out, you should use 'timeout'.
timeout_ :: (TimeUnit t, Timeout :> es) => t -> Eff es a -> Eff es ()
timeout_ t m = const () <$> timeout t m


runTimeout :: (HasCallStack, IOE :> es) => Eff (Timeout : es) a -> Eff es a
runTimeout = interpret \env -> \case
    Timeout delay action ->
        localUnliftIO env (ConcUnlift Persistent (Limited 1)) \unlift ->
            IO.timeout (fromIntegral $ toMicroseconds delay) $ unlift action
