module Atelier.Effects.Stream
    ( Stream
    , next
    , fromEvents
    , filter
    , changes
    ) where

import Atelier.Effects.Chan (Chan)
import Atelier.Effects.Conc (Conc)
import Atelier.Effects.Publishing (Sub)
import Prelude hiding (filter)

import Atelier.Effects.Chan qualified as Chan
import Atelier.Effects.Conc qualified as Conc
import Atelier.Effects.Publishing qualified as Sub


-- | An infinite pull-based stream of values.
newtype Stream es a = Stream {next :: Eff es a}
    deriving (Functor) via (Eff es)


-- | Run a continuation with a buffered stream of 'Sub' events. The stream
-- subscribes before the continuation runs, so no events are missed. The
-- internal listener thread is scoped to the continuation.
fromEvents
    :: forall event es a
     . (Chan :> es, Conc :> es, Sub event :> es)
    => (Stream es event -> Eff es a)
    -> Eff es a
fromEvents use = Conc.scoped do
    (inChan, outChan) <- Chan.newChan
    Conc.fork_ $ Sub.listen_ (Chan.writeChan inChan)
    use $ Stream (Chan.readChan outChan)


filter :: (a -> Bool) -> Stream es a -> Stream es a
filter p (Stream n) = Stream loop
  where
    loop = do
        x <- n
        if p x then pure x else loop


-- | Only emit values that differ from the previous one.
changes :: (Eq a) => a -> Stream es a -> Stream es a
changes initial stream = Stream (loop initial)
  where
    loop prev = do
        x <- next (filter (/= prev) stream)
        pure x
