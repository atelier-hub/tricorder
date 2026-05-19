module Tricorder.UI.State
    ( Viewports (..)
    , State (..)
    , Processed (..)
    , init
    , ActiveView (..)
    , TestView (..)
    , currentView
    , pushView
    , popView
    , cycleTestView
    ) where

import Atelier.Effects.Clock (Clock, TimeZone)
import Tricorder.BuildState (BuildState (..))
import Prelude hiding (init)

import Atelier.Effects.Clock qualified as Clock


data Viewports
    = MainViewport
    | DiagnosticViewport
    | TestViewport
    deriving stock (Eq, Ord, Show)


data State = State
    { buildState :: Processed Text BuildState
    , timeZone :: TimeZone
    , viewStack :: [ActiveView]
    }


data Processed e a
    = Waiting
    | Failure e
    | Success a


data ActiveView
    = ViewHelp
    | ViewDaemonInfo
    | ViewTestResults TestView
    deriving stock (Eq)


data TestView = TestViewFailOnly | TestViewFull
    deriving stock (Bounded, Enum, Eq)


currentView :: State -> Maybe ActiveView
currentView = viaNonEmpty head . (.viewStack)


pushView :: ActiveView -> State -> State
pushView v s = s {viewStack = v : s.viewStack}


popView :: State -> State
popView s = s {viewStack = drop 1 s.viewStack}


cycleTestView :: TestView -> TestView
cycleTestView v = if v == maxBound then minBound else succ v


init :: (Clock :> es) => Eff es State
init = do
    tz <- Clock.currentTimeZone
    pure
        State
            { buildState = Waiting
            , timeZone = tz
            , viewStack = []
            }
