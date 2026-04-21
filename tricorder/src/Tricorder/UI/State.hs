module Tricorder.UI.State
    ( Name (..)
    , State (..)
    , init
    , Collapsible (..)
    , invertCollapsible
    ) where

import Atelier.Effects.Clock (Clock, TimeZone)
import Tricorder.BuildState (BuildState (..))
import Prelude hiding (init)

import Atelier.Effects.Clock qualified as Clock


data Name = UI
    deriving stock (Eq, Ord, Show)


data State = State
    { buildState :: Maybe BuildState
    , timeZone :: TimeZone
    , daemonInfoView :: Collapsible
    , showHelp :: Bool
    }


data Collapsible
    = Expanded
    | Collapsed
    deriving stock (Eq)


invertCollapsible :: Collapsible -> Collapsible
invertCollapsible Expanded = Collapsed
invertCollapsible Collapsed = Expanded


init :: (Clock :> es) => Eff es State
init = do
    tz <- Clock.currentTimeZone
    pure
        State
            { buildState = Nothing
            , timeZone = tz
            , daemonInfoView = Collapsed
            , showHelp = False
            }
