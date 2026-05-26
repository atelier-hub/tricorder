-- | Debounce effect for coalescing rapid bursts of keyed events.
--
-- == Overview
--
-- 'debouncedWith' is the fundamental operation: it accumulates rapid successive
-- calls with the same key using a merge function, then fires the callback once
-- after the settle window with the merged result.
--
-- 'debounced' is a convenience wrapper for the common case where only timing
-- matters and the last-registered action should fire.
--
-- == Example
--
-- @
-- watchFilePaths watches \path event ->
--     debouncedWith 100 mergeFileEvent path event (handleChange path)
-- @
module Atelier.Effects.Debounce
    ( -- * Effect
      Debounce
    , debouncedWith
    , debounced

      -- * Interpreters
    , runDebounce
    , runDebounceNoOp
    ) where

import Data.Dynamic (Dynamic, fromDynamic, toDyn)
import Effectful (Effect)
import Effectful.Concurrent (Concurrent)
import Effectful.Concurrent.STM (STM)
import Effectful.Dispatch.Dynamic (interpretWith, localSeqUnlift, localUnlift)
import Effectful.TH (makeEffect)

import Effectful.Concurrent.STM qualified as STM
import StmContainers.Map qualified as Map

import Atelier.Effects.Conc (Conc, concStrat, fork)
import Atelier.Effects.Delay (Delay)
import Atelier.Time (Millisecond)

import Atelier.Effects.Delay qualified as Delay


data Debounce key :: Effect where
    -- | Schedule @callback merged@ after the settle window. If another call
    -- with the same @key@ arrives before the window expires, the two values are
    -- combined with @merge old new@ and the timer resets. The callback fires at
    -- most once per burst.
    DebouncedWith
        :: (Typeable value)
        => Millisecond
        -> (value -> value -> value)
        -> key
        -> value
        -> (value -> m ())
        -> Debounce key m ()


makeEffect ''Debounce


-- | Schedule @action@ to run after the settle window unless a newer call with
-- the same @key@ arrives first. The last-registered action fires.
debounced :: (Debounce key :> es) => Millisecond -> key -> Eff es () -> Eff es ()
debounced settleMs key action = debouncedWith settleMs (\() () -> ()) key () (\() -> action)


-- | Run the 'Debounce' effect.
--
-- Each key maintains a generation counter. Rapid calls for the same key merge
-- their values and reset the settle timer; only the last generation fires.
runDebounce
    :: forall key es a
     . ( Conc :> es
       , Concurrent :> es
       , Delay :> es
       , Hashable key
       )
    => Eff (Debounce key : es) a
    -> Eff es a
runDebounce eff = do
    state <- STM.atomically (Map.new :: STM (Map.Map key (Int, Maybe Dynamic)))
    interpretWith eff \env -> \case
        DebouncedWith settleMs merge key value callback ->
            localUnlift env concStrat \unlift -> do
                n <- STM.atomically $ do
                    current <- Map.lookup key state
                    let n = maybe 0 ((+ 1) . fst) current
                    let prior = current >>= \(_, mDyn) -> mDyn >>= fromDynamic
                    let merged = case prior of
                            Just p -> merge p value
                            Nothing -> value
                    Map.insert (n, Just (toDyn merged)) key state
                    pure n
                void $ fork $ do
                    Delay.wait settleMs
                    mValue <- STM.atomically $ do
                        current <- Map.lookup key state
                        if fmap fst current == Just n then do
                            Map.delete key state
                            pure $ current >>= \(_, mDyn) -> mDyn >>= fromDynamic
                        else
                            pure Nothing
                    for_ mValue (unlift . callback)


-- | No-op interpreter — fires every callback immediately with its value, without
-- debouncing. Useful for tests where timing is controlled externally.
runDebounceNoOp :: Eff (Debounce key : es) a -> Eff es a
runDebounceNoOp eff = interpretWith eff \env -> \case
    DebouncedWith _ _ _ value callback -> localSeqUnlift env \unlift -> unlift (callback value)
