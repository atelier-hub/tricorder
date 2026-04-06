module Atelier.Effects.Clock
    ( Clock
    , currentTime
    , currentTimeZone
    , runClock
    , runClockConst
    , runClockState
    , runClockList
    ) where

import Data.Time (UTCTime, getCurrentTime)
import Data.Time.LocalTime (TimeZone, getCurrentTimeZone, utc)
import Effectful (Effect, IOE)
import Effectful.Dispatch.Dynamic (interpret_, reinterpret)
import Effectful.State.Static.Shared (State, evalState, get, put)
import Effectful.TH (makeEffect)


data Clock :: Effect where
    CurrentTime :: Clock m UTCTime
    CurrentTimeZone :: Clock m TimeZone


makeEffect ''Clock


runClock :: (IOE :> es) => Eff (Clock : es) a -> Eff es a
runClock = interpret_ $ \case
    CurrentTime -> liftIO getCurrentTime
    CurrentTimeZone -> liftIO getCurrentTimeZone


runClockConst :: UTCTime -> Eff (Clock : es) a -> Eff es a
runClockConst time = interpret_ $ \case
    CurrentTime -> pure time
    CurrentTimeZone -> pure utc


runClockState :: (State UTCTime :> es) => Eff (Clock : es) a -> Eff es a
runClockState = interpret_ $ \case
    CurrentTime -> get
    CurrentTimeZone -> pure utc


-- | Scripted interpreter for testing: returns times from a pre-loaded list in
-- order. Each 'currentTime' call pops the next item. Crashes if the list is
-- exhausted.
runClockList :: [UTCTime] -> Eff (Clock : es) a -> Eff es a
runClockList times = reinterpret (evalState times) $ \_ -> \case
    CurrentTime ->
        get >>= \case
            [] -> error "runClockList: no more times in queue"
            t : ts -> put ts >> pure t
    CurrentTimeZone -> pure utc
