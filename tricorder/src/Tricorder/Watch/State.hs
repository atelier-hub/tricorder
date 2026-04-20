module Tricorder.Watch.State
    ( Name (..)
    , State (..)
    , init
    ) where

import Atelier.Effects.Clock (Clock, TimeZone)
import Tricorder.BuildState (BuildState (..))
import Prelude hiding (init)

import Atelier.Effects.Clock qualified as Clock


data Name = Watcher
    deriving stock (Eq, Ord, Show)


data State = State
    { buildState :: Maybe BuildState
    , timeZone :: TimeZone
    , showHelp :: Bool
    }


init :: (Clock :> es) => Eff es State
init = do
    tz <- Clock.currentTimeZone
    pure
        State
            { buildState = Nothing
            , timeZone = tz
            , showHelp = False
            }
