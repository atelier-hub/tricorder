module Tricorder.Effects.BrickChan
    ( BrickChan
    , BChan
    , newBChan
    , writeBChan
    , writeBChanNonBlocking
    , readBChan
    , readBChan2
    , runBrickChan
    ) where

import Brick.BChan (BChan)
import Effectful (Effect, IOE)
import Effectful.Dispatch.Dynamic (interpret_)
import Effectful.TH (makeEffect)

import Brick.BChan qualified as BChan


data BrickChan :: Effect where
    -- | Lifted `Brick.BChan.newBChan`
    NewBChan :: Int -> BrickChan m (BChan a)
    -- | Lifted `Brick.BChan.writeBChan`
    WriteBChan :: BChan a -> a -> BrickChan m ()
    -- | Lifted `Brick.BChan.writeBChanNonBlocking`
    WriteBChanNonBlocking :: BChan a -> a -> BrickChan m Bool
    -- | Lifted `Brick.BChan.readBChan`
    ReadBChan :: BChan a -> BrickChan m a
    -- | Lifted `Brick.BChan.readBChan2`
    ReadBChan2 :: BChan a -> BChan b -> BrickChan m (Either a b)


makeEffect ''BrickChan


runBrickChan :: (IOE :> es) => Eff (BrickChan : es) a -> Eff es a
runBrickChan = interpret_ \case
    NewBChan n -> liftIO $ BChan.newBChan n
    WriteBChan c x -> liftIO $ BChan.writeBChan c x
    WriteBChanNonBlocking c x -> liftIO $ BChan.writeBChanNonBlocking c x
    ReadBChan c -> liftIO $ BChan.readBChan c
    ReadBChan2 c1 c2 -> liftIO $ BChan.readBChan2 c1 c2
