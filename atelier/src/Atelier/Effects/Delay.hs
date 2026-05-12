module Atelier.Effects.Delay
    ( Delay
    , wait
    , every
    , withTimeout
    , runDelay
    , runDelayNoOp

      -- * Mock delays and give control to the callsite
    , runDelayWithControls
    , settle
    , Timers
    , Timer (..)
    , mkTimers
    , tick
    , tickNext
    ) where

import Data.Time.Units (TimeUnit, convertUnit, toMicroseconds)
import Effectful (Effect, IOE)
import Effectful.Concurrent (Concurrent, threadDelay)
import Effectful.Concurrent.Async (race)
import Effectful.Concurrent.MVar (newEmptyMVar, takeMVar)
import Effectful.Dispatch.Dynamic (interpret_)
import Effectful.State.Static.Shared (State, modifyM)
import Effectful.TH (makeEffect)

import Control.Concurrent.MVar qualified as IO

import Atelier.Time (Microsecond)


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


-- | Race an action against a deadline. Returns 'Right' if the action
-- completes first, 'Left' if the timeout fires first.
withTimeout
    :: (Concurrent :> es, Delay :> es, TimeUnit t)
    => t
    -> Eff es a
    -> Eff es (Either () a)
withTimeout duration = race (wait duration)


runDelay :: (Concurrent :> es) => Eff (Delay : es) a -> Eff es a
runDelay = interpret_ \(Wait delay) ->
    threadDelay $ fromIntegral (toMicroseconds delay)


-- | Delay interpreter that makes every 'wait' a no-op — useful in unit tests.
runDelayNoOp :: Eff (Delay : es) a -> Eff es a
runDelayNoOp = interpret_ \(Wait _) -> pure ()


runDelayWithControls
    :: ( Concurrent :> es
       , State Timers :> es
       )
    => Eff (Delay : es) a -> Eff es a
runDelayWithControls = interpret_ \(Wait delay) -> do
    var <- newEmptyMVar
    modifyM \ts -> do
        let timer =
                Timer
                    { timeRemaining = convertUnit delay
                    , release = void $ IO.tryPutMVar var ()
                    }
        pure $ addTimer timer ts
    takeMVar var
    pure ()


tick :: (Concurrent :> es, IOE :> es, State Timers :> es, TimeUnit t) => t -> Eff es ()
tick delay = withSettledThreads do
    modifyM $ tickTimers (convertUnit delay)


tickNext :: (Concurrent :> es, IOE :> es, State Timers :> es) => Eff es ()
tickNext = withSettledThreads do
    modifyM \case
        [] -> pure []
        t : ts -> tickTimers t.timeRemaining (t : ts)


tickTimers :: (IOE :> es) => Microsecond -> Timers -> Eff es Timers
tickTimers delay = fmap catMaybes . traverse (tickTimer delay)


settle :: (Concurrent :> es) => Eff es ()
settle = withSettledThreads $ pure ()


withSettledThreads :: (Concurrent :> es) => Eff es a -> Eff es a
withSettledThreads eff = do
    -- Wait 10 ms, to ensure running threads get the chance to hit a `Wait` or
    -- `Every` operation.
    threadDelay 10_000
    res <- eff
    -- Wait 10 ms, to ensure other threads settle.
    threadDelay 10_000
    pure res


type Timers = [Timer]


mkTimers :: Timers
mkTimers = []


addTimer :: Timer -> Timers -> Timers
addTimer t ts = sortOn (.timeRemaining) $ t : ts


tickTimer
    :: (IOE :> es)
    => Microsecond
    -> Timer
    -> Eff es (Maybe Timer)
tickTimer delay timer
    | timer.timeRemaining > delay =
        pure
            $ Just
                timer
                    { timeRemaining = timer.timeRemaining - delay
                    }
    | otherwise = do
        liftIO timer.release
        pure Nothing


data Timer = Timer
    { release :: IO ()
    , timeRemaining :: Microsecond
    }
