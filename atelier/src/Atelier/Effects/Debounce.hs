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

      -- * Helpers
    , ensureEntry
    , ensureCallback
    , Entry (..)
    ) where

import Data.Dynamic (Dynamic, fromDynamic, toDyn)
import Effectful (Effect, Limit (..), Persistence (..), UnliftStrategy (..))
import Effectful.Concurrent (Concurrent)
import Effectful.Concurrent.STM (STM)
import Effectful.Dispatch.Dynamic (interpretWith, localSeqUnlift, localUnlift)
import Effectful.TH (makeEffect)

import Effectful.Concurrent.STM qualified as STM
import StmContainers.Map qualified as Map

import Atelier.Effects.Conc (Conc)
import Atelier.Effects.Timeout (Timeout, timeout)
import Atelier.Time (Millisecond)
import Atelier.Types.Semaphore.STM (Semaphore)

import Atelier.Effects.Conc qualified as Conc
import Atelier.Types.Semaphore.STM qualified as Sem


data Debounce key :: Effect where
    -- | Schedule @callback merged@ after the settle window. If another call
    -- with the same @key@ arrives before the window expires, the two values are
    -- combined with @merge old new@ and the timer resets. The callback fires at
    -- most once per burst.
    DebouncedWith
        :: (Typeable arg)
        => Millisecond
        -> (arg -> arg -> arg)
        -> key
        -> arg
        -> (arg -> m a)
        -> Debounce key m ()


makeEffect ''Debounce


-- | Schedule @action@ to run after the settle window unless a newer call with
-- the same @key@ arrives first. The last-registered action fires.
debounced :: (Debounce key :> es) => Millisecond -> key -> Eff es a -> Eff es ()
debounced settleMs key action = debouncedWith settleMs (\_ _ -> ()) key () (\_ -> action)


data Entry = Entry
    { arg :: Maybe Dynamic
    , generation :: Int
    , cancelled :: Semaphore
    }


-- | Run the 'Debounce' effect.
--
-- Each key maintains a generation counter. Rapid calls for the same key merge
-- their values and reset the settle timer; only the last generation fires.
runDebounce
    :: forall key es a
     . ( Conc :> es
       , Concurrent :> es
       , Hashable key
       , Timeout :> es
       )
    => Eff (Debounce key : es) a
    -> Eff es a
runDebounce eff = do
    state <- STM.atomically (Map.new @key @Entry)
    interpretWith eff \env -> \case
        DebouncedWith settleMs merge key arg callback -> do
            entry <- STM.atomically $ ensureEntry key arg state merge
            localUnlift env (ConcUnlift Persistent (Limited 1)) \unlift ->
                void
                    $ Conc.fork
                    $ ensureCallback settleMs entry \arg' -> do
                        STM.atomically $ Map.delete key state
                        unlift $ callback arg'


ensureCallback
    :: forall arg es a
     . ( Concurrent :> es
       , Timeout :> es
       , Typeable arg
       )
    => Millisecond
    -> Entry
    -> (arg -> Eff es a)
    -> Eff es ()
ensureCallback settleMs entry callback = do
    res <- timeout settleMs do
        STM.atomically $ Sem.wait entry.cancelled

    -- If res /= Nothing, then it was cancelled
    when (res == Nothing) do
        case fromDynamic =<< entry.arg of
            Nothing -> pure ()
            Just arg -> do
                void $ callback arg


ensureEntry
    :: (Hashable key, Typeable value)
    => key
    -> value
    -> Map.Map key Entry
    -> (value -> value -> value)
    -> STM Entry
ensureEntry key value state merge = do
    current <- Map.lookup key state
    entry <- case current of
        Nothing -> do
            cancelled <- Sem.new
            pure
                $ Entry
                    { arg = Nothing
                    , generation = 0
                    , cancelled
                    }
        Just e -> do
            void $ Sem.set e.cancelled
            cancelled <- Sem.new
            pure
                $ e
                    { generation = e.generation + 1
                    , cancelled
                    }
    let prior = current >>= (.arg) >>= fromDynamic
    let merged = case prior of
            Just p -> merge p value
            Nothing -> value
    let updatedEntry = entry {arg = Just (toDyn merged)}
    Map.insert updatedEntry key state
    pure updatedEntry


-- | No-op interpreter — fires every callback immediately with its value, without
-- debouncing. Useful for tests where timing is controlled externally.
runDebounceNoOp :: Eff (Debounce key : es) a -> Eff es a
runDebounceNoOp eff = interpretWith eff \env -> \case
    DebouncedWith _ _ _ value callback -> localSeqUnlift env \unlift -> void $ unlift (callback value)
