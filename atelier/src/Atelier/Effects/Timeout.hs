module Atelier.Effects.Timeout
    ( Timeout
    , timeout
    , timeout_
    , runTimeout
    , runTimeoutAlwaysRun
    , runTimeoutAlwaysTimesOut
    , runTimeoutMVar
    ) where

import Effectful (Effect, IOE, Limit (..), Persistence (..), UnliftStrategy (..))
import Effectful.Concurrent.MVar (MVar, takeMVar)
import Effectful.Concurrent.STM (Concurrent)
import Effectful.Dispatch.Dynamic (interpret, interpret_, localSeqUnlift, localUnlift, localUnliftIO)
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


-- | Ignore timeouts, and let the action run for as long as it wants.
runTimeoutAlwaysRun :: Eff (Timeout : es) a -> Eff es a
runTimeoutAlwaysRun = interpret \env -> \case
    Timeout _ action ->
        localSeqUnlift env \unlift -> do
            Just <$> unlift action


-- | Pretend like the action always timed out.
runTimeoutAlwaysTimesOut :: Eff (Timeout : es) a -> Eff es a
runTimeoutAlwaysTimesOut = interpret_ \case
    Timeout _ _ -> pure Nothing


-- | Control the timeout with an 'MVar'.
--
-- - If the 'MVar' contains 'False', the next 'timeout' will time out.
-- - If it contains 'True', the action will run to completion. The timeout will
-- wait until the 'MVar' is filled.
runTimeoutMVar
    :: (Concurrent :> es)
    => MVar Bool
    -> Eff (Timeout : es) a
    -> Eff es a
runTimeoutMVar ref = interpret \env -> \case
    Timeout _ action -> do
        localUnlift env (ConcUnlift Persistent (Limited 1)) \unlift -> do
            shouldRunAction <- takeMVar ref
            if shouldRunAction then
                Just <$> unlift action
            else
                pure Nothing
