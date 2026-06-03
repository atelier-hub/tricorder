module Atelier.Effects.Delay
    ( Delay
    , wait
    , every
    , runDelay
    , runDelayNoOp
    ) where

import Data.Time.Units (TimeUnit, toMicroseconds)
import Effectful (Effect)
import Effectful.Concurrent (Concurrent, threadDelay)
import Effectful.Dispatch.Dynamic (interpret_)
import Effectful.TH (makeEffect)


data Delay :: Effect where
    -- | Halt the thread and wait for the passed duration before continuing.
    Wait :: (TimeUnit t) => t -> Delay m ()


makeEffect ''Delay


-- | Runs an action repeatedly, waiting the given duration in between each
-- execution, starting immediately. Returns Void since it runs forever.
-- Caller is responsible for forking.
every :: (Delay :> es, TimeUnit t) => t -> Eff es () -> Eff es Void
every delay action = forever do
    action
    wait delay


runDelay :: (Concurrent :> es) => Eff (Delay : es) a -> Eff es a
runDelay = interpret_ \(Wait delay) ->
    threadDelay $ fromIntegral (toMicroseconds delay)


-- | Delay interpreter that makes every 'wait' a no-op — useful in unit tests.
runDelayNoOp :: Eff (Delay : es) a -> Eff es a
runDelayNoOp = interpret_ \(Wait _) -> pure ()
