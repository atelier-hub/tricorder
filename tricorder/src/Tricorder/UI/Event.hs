module Tricorder.UI.Event
    ( Event (..)
    , handleEvent
    ) where

import Brick (BrickEvent (..), EventM)
import Brick.Keybindings (KeyDispatcher, handleKey)
import Control.Monad.State (modify)

import Graphics.Vty qualified as Vty

import Tricorder.BuildState (BuildState (..))
import Tricorder.UI.Keys (KeyEvent)
import Tricorder.UI.State (Processed (..), State (..), Viewports (..))


data Event
    = NewBuildState BuildState
    | FailedBuild Text


handleEvent :: KeyDispatcher KeyEvent (EventM Viewports State) -> BrickEvent Viewports Event -> EventM Viewports State ()
handleEvent _ (AppEvent ev) = handleAppEvent ev
handleEvent d (VtyEvent (Vty.EvKey key modifiers)) = void $ handleKey d key modifiers
handleEvent _ _ = pure ()


handleAppEvent :: Event -> EventM Viewports State ()
handleAppEvent = \case
    NewBuildState bs ->
        modify \s -> s {buildState = Success bs}
    FailedBuild reason ->
        modify \s -> s {buildState = Failure reason}
