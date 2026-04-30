module Tricorder.UI.State
    ( Viewports (..)
    , State (..)
    , Processed (..)
    , init
    , Collapsible (..)
    , invertCollapsible
    ) where

import Atelier.Effects.Clock (Clock, TimeZone)
import Tricorder.BuildState (BuildState (..))
import Prelude hiding (init)

import Atelier.Effects.Clock qualified as Clock


data Viewports
    = MainViewport
    | DiagnosticViewport
    deriving stock (Eq, Ord, Show)


data State = State
    { buildState :: Processed Text BuildState
    , timeZone :: TimeZone
    , daemonInfoView :: Collapsible
    , showHelp :: Bool
    }


data Processed e a
    = Waiting
    | Failure e
    | Success a


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
            { buildState = Waiting
            , timeZone = tz
            , daemonInfoView = Collapsed
            , showHelp = False
            }
