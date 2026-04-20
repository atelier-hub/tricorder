module Tricorder.Watch.Event
    ( Event (..)
    , handleEvent
    , keys
    , keyConfig
    , dispatcher
    , viewKeybindings
    ) where

import Brick
    ( BrickEvent (..)
    , EventM
    , Widget
    , halt
    , txt
    , vBox
    , vScrollBy
    , viewportScroll
    )
import Brick.Keybindings
    ( Binding
    , EventTrigger (..)
    , Handler (..)
    , KeyConfig
    , KeyDispatcher
    , KeyEventHandler (..)
    , KeyEvents
    , KeyHandler (..)
    , ToBinding (..)
    , allActiveBindings
    , binding
    , ctrl
    , handleKey
    , keyDispatcher
    , keyEvents
    , newKeyConfig
    , onEvent
    )
import Brick.Keybindings.Pretty (ppBinding)
import Control.Monad.State (modify)
import Graphics.Vty (Key (..))

import Data.Map.Strict qualified as Map
import Data.Set qualified as Set
import Data.Text qualified as T
import Graphics.Vty qualified as Vty

import Tricorder.BuildState (BuildState (..))
import Tricorder.Watch.State (Name (..), State (..), invertCollapsible)


data Event
    = NewBuildState BuildState


handleEvent :: BrickEvent Name Event -> EventM Name State ()
handleEvent (AppEvent ev) = handleAppEvent ev
handleEvent (VtyEvent (Vty.EvKey key modifiers)) = void $ handleKey dispatcher key modifiers
handleEvent _ = pure ()


handleAppEvent :: Event -> EventM Name State ()
handleAppEvent = \case
    NewBuildState bs ->
        modify \s -> s {buildState = Just bs}


data KeyEvent
    = ToggleDaemonInfoView
    | Quit
    | ScrollUp
    | ScrollDown
    | ToggleHelp
    deriving stock (Eq, Ord, Show)


keys :: KeyEvents KeyEvent
keys =
    keyEvents
        [ ("toggle daemon info", ToggleDaemonInfoView)
        , ("quit", Quit)
        , ("scroll up", ScrollUp)
        , ("scroll down", ScrollDown)
        , ("toggle help", ToggleHelp)
        ]


bindings :: [(KeyEvent, [Binding])]
bindings =
    [ (ToggleDaemonInfoView, [bind 'g'])
    , (Quit, [bind 'q', ctrl 'c', binding KEsc []])
    , (ScrollUp, [binding KUp []])
    , (ScrollDown, [binding KDown []])
    , (ToggleHelp, [bind 'h'])
    ]


keyConfig :: KeyConfig KeyEvent
keyConfig =
    newKeyConfig keys bindings []


dispatcher :: KeyDispatcher KeyEvent (EventM Name State)
dispatcher =
    -- TODO: Handle this error more gracefully.
    either (error . ("Invalid key dispatcher config: " <>) . stringify) id
        $ keyDispatcher
            keyConfig
            [ onEvent ToggleDaemonInfoView "Toggle daemon info view" do
                modify \s -> s {daemonInfoView = invertCollapsible s.daemonInfoView}
            , onEvent Quit "Exit" do
                halt
            , onEvent ScrollUp "Scrolling upwards" do
                vScrollBy (viewportScroll Watcher) (-1)
            , onEvent ScrollDown "Scrolling downwards" do
                vScrollBy (viewportScroll Watcher) 1
            , onEvent ToggleHelp "Toggle help" do
                modify \s -> s {showHelp = not s.showHelp}
            ]
  where
    stringify =
        show . fmap (second $ fmap $ handlerDescription . kehHandler . khHandler)


viewKeybindings :: (Ord k, Show k) => KeyConfig k -> [KeyEventHandler k m] -> Widget n
viewKeybindings kc =
    vBox
        . fmap (uncurry (viewEventAndTriggers kc))
        . Map.toList
        . foldr groupByEventName Map.empty
  where
    groupByEventName ev = Map.insertWith (<>) ev.kehHandler.handlerDescription [ev.kehEventTrigger]


viewEventAndTriggers :: (Ord k, Show k) => KeyConfig k -> Text -> [EventTrigger k] -> Widget n
viewEventAndTriggers kc eventName trigger =
    txt $ eventName <> ": " <> (showBindings $ mconcat $ getBindings <$> trigger)
  where
    showBindings = T.intercalate ", " . fmap ppBinding . sort . toList
    getBindings = \case
        ByKey k -> Set.singleton k
        ByEvent e -> Set.fromList $ allActiveBindings kc e
