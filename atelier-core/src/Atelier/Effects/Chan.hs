{-# OPTIONS_GHC -Wno-redundant-constraints #-}

-- | Module: Atelier.Effects.Chan
-- Description: Effect for creating and operating on bidirectional channels
module Atelier.Effects.Chan
    ( -- * Effect
      Chan
    , newChan
    , readChan
    , writeChan
    , dupChan
    , runChan

      -- * Channel Types

      -- | Re-exported from the underlying channel implementation.
      -- Import these from this module rather than directly from Unagi
      -- to maintain abstraction boundaries.
    , InChan
    , OutChan
    , readChanBatched
    ) where

import Control.Concurrent.Chan.Unagi (InChan, OutChan)
import Data.Time.Units (TimeUnit, toMicroseconds)
import Effectful (Dispatch (..), DispatchOf, Effect, IOE)
import Effectful.Dispatch.Static (SideEffects (..), StaticRep, evalStaticRep, unsafeEff_)
import Effectful.State.Static.Shared (evalState, get, modify)
import Effectful.Timeout (Timeout, timeout)

import Control.Concurrent.Chan.Unagi qualified as Unagi


-- | Effect for creating and operating on bidirectional channels.
data Chan :: Effect


type instance DispatchOf Chan = Static WithSideEffects
data instance StaticRep Chan = Chan


runChan :: forall a es. (IOE :> es) => Eff (Chan : es) a -> Eff es a
runChan = evalStaticRep Chan


newChan :: forall a es. (Chan :> es) => Eff es (InChan a, OutChan a)
newChan =
    unsafeEff_ Unagi.newChan


readChan :: forall a es. (Chan :> es) => OutChan a -> Eff es a
readChan outChan =
    unsafeEff_ $ Unagi.readChan outChan


writeChan :: forall a es. (Chan :> es) => InChan a -> a -> Eff es ()
writeChan inChan val =
    unsafeEff_ $ Unagi.writeChan inChan val


dupChan :: forall a es. (Chan :> es) => InChan a -> Eff es (OutChan a)
dupChan inChan =
    unsafeEff_ $ Unagi.dupChan inChan


-- | Read a batch of items from a channel.
--
-- Blocks until at least one item is available, then attempts to read
-- up to @batchSize@ items total within the given timeout. Always returns
-- at least one item.
readChanBatched
    :: forall t a es
     . ( Chan :> es
       , TimeUnit t
       , Timeout :> es
       )
    => t
    -- ^ Timeout for reading additional items after the first
    -> Int
    -- ^ Maximum number of items to read (batch size)
    -> OutChan a
    -- ^ Channel to read from
    -> Eff es (NonEmpty a)
    -- ^ Non-empty batch of items (at least one, up to batch size)
readChanBatched timeoutDuration batchSize outChan = do
    evalState @[a] [] $ do
        h <- readChan outChan -- blocking, get first item
        _ <- timeout (fromIntegral (toMicroseconds timeoutDuration))
            $ replicateM_ (batchSize - 1)
            $ do
                x <- readChan outChan
                modify (x :)
        rest <- get
        pure $ h :| reverse rest
