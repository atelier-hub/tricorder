module Atelier.Effects.Iterator
    ( Iterator
    , next
    , fromEvents
    , filter
    , changes
    ) where

import Prelude hiding (filter)

import Atelier.Effects.Chan (Chan)
import Atelier.Effects.Conc (Conc)
import Atelier.Effects.Publishing (Sub)

import Atelier.Effects.Chan qualified as Chan
import Atelier.Effects.Conc qualified as Conc
import Atelier.Effects.Publishing qualified as Sub


-- | An pull-based iterator of (potentially infinite) values.
newtype Iterator es a = Iterator {next :: Eff es a}
    deriving (Functor) via (Eff es)


-- | Run a continuation with a buffered iterator of 'Sub' events. The iterator
-- subscribes before the continuation runs, so no events are missed. The
-- internal listener thread is scoped to the continuation, and is killed when
-- the continuation returns.
fromEvents
    :: forall event es a
     . (Chan :> es, Conc :> es, Sub event :> es)
    => (Iterator es event -> Eff es a)
    -> Eff es a
fromEvents use = Conc.scoped do
    (inChan, outChan) <- Chan.newChan
    Conc.fork_ $ Sub.listen_ (Chan.writeChan inChan)
    use $ Iterator (Chan.readChan outChan)


-- | Iterate only over values that pass a predicate.
filter :: (a -> Bool) -> Iterator es a -> Iterator es a
filter p (Iterator n) = Iterator loop
  where
    loop = do
        x <- n
        if p x then pure x else loop


-- | Iterate only values that differ from the previous one.
changes :: (Eq a) => a -> Iterator es a -> Iterator es a
changes initial iterator = Iterator (loop initial)
  where
    loop prev = do
        x <- next (filter (/= prev) iterator)
        pure x
