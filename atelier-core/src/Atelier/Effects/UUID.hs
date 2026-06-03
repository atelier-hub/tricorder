module Atelier.Effects.UUID
    ( GenUUID
    , UUID
    , gen
    , runGenUUID
    , runGenUUIDConst
    ) where

import Data.UUID (UUID)
import Data.UUID.V4 (nextRandom)
import Effectful (Effect, IOE)
import Effectful.Dispatch.Dynamic (interpret_)
import Effectful.TH (makeEffect)


data GenUUID :: Effect where
    Gen :: GenUUID m UUID


makeEffect ''GenUUID


runGenUUID :: (IOE :> es) => Eff (GenUUID : es) a -> Eff es a
runGenUUID = interpret_ \Gen -> liftIO nextRandom


runGenUUIDConst :: UUID -> Eff (GenUUID : es) a -> Eff es a
runGenUUIDConst uuid = interpret_ \Gen -> pure uuid
