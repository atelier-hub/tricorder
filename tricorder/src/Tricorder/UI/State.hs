module Tricorder.UI.State
    ( Viewports (..)
    , State (..)
    , Processed (..)
    , TestFilter (..)
    , init
    , currentRoute
    , viewToViewport
    , cycleTestFilter
    , pushRoute
    , popRoute
    ) where

import Atelier.Effects.Clock (Clock, TimeZone)
import Prelude hiding (init)

import Atelier.Effects.Clock qualified as Clock
import Data.List.NonEmpty qualified as NonEmpty

import Tricorder.BuildState (BuildState (..))
import Tricorder.UI.Route (Route)

import Tricorder.UI.Route qualified as Route


data Viewports
    = MainViewport
    | DiagnosticViewport
    | TestViewport
    deriving stock (Eq, Ord, Show)


data State = State
    { buildState :: Processed Text BuildState
    , timeZone :: TimeZone
    , routeHistory :: NonEmpty Route
    , testFilter :: TestFilter
    }


data TestFilter = TestFilterAll | TestFilterFailedOnly
    deriving stock (Bounded, Enum, Eq)


cycleTestFilter :: TestFilter -> TestFilter
cycleTestFilter x = if x == maxBound then minBound else succ x


data Processed e a
    = Waiting
    | Failure e
    | Success a


currentRoute :: State -> Route
currentRoute = NonEmpty.head . (.routeHistory)


viewToViewport :: Route -> Maybe Viewports
viewToViewport = \case
    Route.Tests -> Just TestViewport
    Route.Main -> Just DiagnosticViewport
    _ -> Nothing


pushRoute :: Route -> State -> State
pushRoute v s = s {routeHistory = v :| toList s.routeHistory}


popRoute :: State -> State
popRoute s =
    s
        { routeHistory = case s.routeHistory of
            _ :| [] -> Route.Main :| []
            _ :| (x : xs) -> x :| xs
        }


init :: (Clock :> es) => Eff es State
init = do
    tz <- Clock.currentTimeZone
    pure
        State
            { buildState = Waiting
            , timeZone = tz
            , routeHistory = Route.Main :| []
            , testFilter = minBound
            }
