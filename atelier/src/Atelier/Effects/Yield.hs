module Atelier.Effects.Yield
    ( -- * Effect
      Yield

      -- * Operations
    , yield
    , inFoldable
    , yieldEvents
    , cycleToYield

      -- * Interpreters
    , forEach
    , yieldToList
    , yieldToReverseList
    , withYieldToList
    , ignoreYield
    , enumerate
    , enumerateFrom
    , map
    , mapMaybe
    , catMaybes
    , changes
    , filter
    ) where

import Effectful.Dispatch.Dynamic (impose_, interpose_)
import Effectful.State.Static.Shared (evalState, get)

import Atelier.Effects.Internal.Coroutine
    ( Yield (..)
    , catMaybes
    , cycleToYield
    , enumerate
    , enumerateFrom
    , forEach
    , ignoreYield
    , inFoldable
    , map
    , mapMaybe
    , withYieldToList
    , yield
    , yieldEvents
    , yieldToList
    , yieldToReverseList
    )
import Prelude hiding (catMaybes, filter, map, mapMaybe)


filter :: (a -> Bool) -> Eff (Yield a : es) r -> Eff (Yield a : es) r
filter p = interpose_ \(Yield x) ->
    when (p x) do
        yield x


changes :: forall a es r. (Eq a) => a -> Eff (Yield a : es) r -> Eff (Yield a : es) r
changes initial = impose_ (evalState initial) \(Yield x) -> do
    curr <- get
    when (curr /= x) do
        yield x
