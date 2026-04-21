-- | Debounce effect for coalescing rapid bursts of keyed events.
--
-- == Overview
--
-- @debounced key action@ schedules @action@ to run after the settle window,
-- but cancels it if another call with the same @key@ arrives before the
-- window expires. This coalesces rapid bursts (e.g. two inotify events for
-- the same file) into a single callback.
--
-- == Example
--
-- @
-- watchFilePaths watches \path ->
--     debounced path (markDirty (changeKindFor path))
-- @
module Atelier.Effects.Debounce
    ( -- * Effect
      Debounce
    , debounced

      -- * Interpreters
    , runDebounce
    , runDebounceNoOp
    ) where

import Effectful (Effect, IOE)
import Effectful.Concurrent (Concurrent)
import Effectful.Concurrent.STM (STM)
import Effectful.Dispatch.Dynamic (interpretWith, localSeqUnlift, localUnliftIO)
import Effectful.TH (makeEffect)

import Effectful.Concurrent.STM qualified as STM
import StmContainers.Map qualified as Map

import Atelier.Effects.Conc (Conc, concStrat, fork)
import Atelier.Effects.Delay (Delay)
import Atelier.Time (Millisecond)

import Atelier.Effects.Delay qualified as Delay


data Debounce key :: Effect where
    -- | Schedule @action@ to run after the settle window unless a newer call
    -- with the same @key@ arrives first.
    Debounced :: Millisecond -> key -> m () -> Debounce key m ()


makeEffect ''Debounce


-- | Run the 'Debounce' effect.
--
-- @settleMs@ is the quiet window — how long to wait for silence before firing.
runDebounce
    :: forall key es a
     . ( Conc :> es
       , Concurrent :> es
       , Delay :> es
       , Hashable key
       , IOE :> es
       )
    => Eff (Debounce key : es) a
    -> Eff es a
runDebounce eff = do
    counters <- STM.atomically (Map.new :: STM (Map.Map key Int))
    interpretWith eff \env -> \case
        Debounced settleMs key action -> do
            -- localUnliftIO must be called in the handler thread (not inside a fork).
            -- We use it to pre-create an IO action that's safe to run from any thread.
            fireIO <- localUnliftIO env concStrat \unlift -> pure (unlift action)
            n <- STM.atomically $ do
                current <- Map.lookup key counters
                let n = maybe 0 (+ 1) current
                Map.insert n key counters
                pure n
            void $ fork $ do
                Delay.wait settleMs
                shouldFire <- STM.atomically $ do
                    current <- Map.lookup key counters
                    if current == Just n then
                        Map.delete key counters $> True
                    else
                        pure False
                when shouldFire $ liftIO fireIO


-- | No-op interpreter — fires every action immediately without debouncing.
-- Useful for tests where timing is controlled externally.
runDebounceNoOp :: Eff (Debounce key : es) a -> Eff es a
runDebounceNoOp eff = interpretWith eff \env -> \case
    Debounced _ _ action -> localSeqUnlift env \unlift -> unlift action
