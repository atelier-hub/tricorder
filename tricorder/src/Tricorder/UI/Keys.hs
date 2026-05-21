module Tricorder.UI.Keys
    ( KeyEvent
    , Config
    , keys
    , dispatcher
    , viewKeybindings
    , mkKeyConfig
    ) where

import Brick
    ( EventM
    , Widget
    , halt
    , txt
    , vBox
    , vScrollBy
    , viewportScroll
    )
import Brick.Keybindings
    ( Binding
    , BindingState
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
    , keyDispatcher
    , keyEvents
    , newKeyConfig
    , onEvent
    , parseBindingList
    )
import Brick.Keybindings.Pretty (ppBinding)
import Brick.Widgets.Core (hBox)
import Control.Monad.State (gets, modify)
import Data.Aeson (FromJSON (..))
import Data.Default (Default (..))
import Effectful.Exception (throwIO)
import Effectful.Reader.Static (Reader, ask)
import Graphics.Vty (Key (..))
import System.IO.Error (userError)
import Text.Casing (quietSnake)

import Data.Map.Strict qualified as Map
import Data.Set qualified as Set
import Data.Text qualified as T

import Atelier.Effects.Console (Console)
import Tricorder.UI.Misc (warn)
import Tricorder.UI.State
    ( ActiveView (..)
    , State (..)
    , Viewports (..)
    , currentView
    , cycleTestView
    , popView
    , pushView
    )

import Atelier.Effects.Console qualified as Console


-- When adding a new event here, also list it in the README under "Custom Key Bindings".
data KeyEvent
    = ToggleDaemonInfoView
    | Quit
    | ExitView
    | ScrollUp
    | ScrollDown
    | ToggleHelp
    | CycleTestView
    deriving stock (Bounded, Enum, Eq, Ord, Show)


keyEventToText :: KeyEvent -> Text
keyEventToText = toText . quietSnake . show


keyEventTextMap :: Map Text KeyEvent
keyEventTextMap = Map.fromList $ (\e -> (keyEventToText e, e)) <$> universe


textToKeyEvent :: Text -> Maybe KeyEvent
textToKeyEvent = (`Map.lookup` keyEventTextMap)


keys :: KeyEvents KeyEvent
keys =
    keyEvents
        [ ("toggle daemon info", ToggleDaemonInfoView)
        , ("quit", Quit)
        , ("exit view", ExitView)
        , ("scroll up", ScrollUp)
        , ("scroll down", ScrollDown)
        , ("toggle help", ToggleHelp)
        , ("cycle test view", CycleTestView)
        ]


bindings :: [(KeyEvent, [Binding])]
bindings =
    [ (ToggleDaemonInfoView, [bind 'g'])
    , (Quit, [bind 'q', ctrl 'c'])
    , (ExitView, [binding KEsc []])
    , (ScrollUp, [binding KUp []])
    , (ScrollDown, [binding KDown []])
    , (ToggleHelp, [bind 'h'])
    , (CycleTestView, [bind 't'])
    ]


mkKeyConfig :: (Console :> es, Reader Config :> es) => Eff es (KeyConfig KeyEvent)
mkKeyConfig = do
    customBindings <- parseCustomBindings
    pure $ newKeyConfig keys bindings customBindings


newtype Config = Config (Map Text Text)
    deriving stock (Generic)
    deriving newtype (FromJSON)


instance Default Config where
    def = Config mempty


parseCustomBindings
    :: ( Console :> es
       , Reader Config :> es
       )
    => Eff es [(KeyEvent, BindingState)]
parseCustomBindings = do
    Config cfg <- ask
    let (errors, customBindings) = partitionEithers $ uncurry parseEntry <$> Map.toList cfg
    unless (null errors) do
        Console.putTextLn "Error(s) encountered when attempting to parse key bindings:"
        traverse_ (Console.putTextLn . toText) errors
        throwIO $ userError "Malformed keybindings"
    pure customBindings


parseEntry :: Text -> Text -> Either Text (KeyEvent, BindingState)
parseEntry ev binds =
    (,) <$> parsedEvent <*> parsedBinds
  where
    parsedEvent = parseKeyEvent ev
    parsedBinds = first toText $ parseBindingList binds


parseKeyEvent :: Text -> Either Text KeyEvent
parseKeyEvent ev = maybeToRight ("Unrecognized key event: " <> ev) $ textToKeyEvent ev


dispatcher :: KeyConfig KeyEvent -> KeyDispatcher KeyEvent (EventM Viewports State)
dispatcher cfg =
    -- TODO: Handle this error more gracefully.
    either (error . ("Invalid key dispatcher config: " <>) . stringify) id
        $ keyDispatcher
            cfg
            [ onEvent ToggleDaemonInfoView "Toggle daemon info view" do
                modify \s ->
                    if currentView s == Just ViewDaemonInfo then
                        popView s
                    else
                        pushView ViewDaemonInfo s
            , onEvent Quit "Exit" do
                halt
            , onEvent ExitView "Exit or go back" do
                stack <- gets (.viewStack)
                if null stack then halt else modify popView
            , onEvent ScrollUp "Scroll up" do
                av <- gets currentView
                unless (av == Just ViewHelp) do
                    let vp = case av of
                            Just (ViewTestResults _) -> TestViewport
                            _ -> DiagnosticViewport
                    vScrollBy (viewportScroll vp) (-1)
            , onEvent ScrollDown "Scroll down" do
                av <- gets currentView
                unless (av == Just ViewHelp) do
                    let vp = case av of
                            Just (ViewTestResults _) -> TestViewport
                            _ -> DiagnosticViewport
                    vScrollBy (viewportScroll vp) 1
            , onEvent ToggleHelp "Toggle help" do
                modify \s ->
                    if currentView s == Just ViewHelp then
                        popView s
                    else
                        pushView ViewHelp s
            , onEvent CycleTestView "Cycle test results view" do
                modify \s -> case currentView s of
                    Just (ViewTestResults tv) ->
                        if tv == maxBound then
                            popView s
                        else
                            pushView (ViewTestResults (cycleTestView tv)) (popView s)
                    _ -> pushView (ViewTestResults minBound) s
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
    hBox
        [ warn $ txt $ eventName <> ": "
        , txt $ showBindings $ mconcat $ getBindings <$> trigger
        ]
  where
    showBindings = T.intercalate ", " . fmap ppBinding . sort . toList
    getBindings = \case
        ByKey k -> Set.singleton k
        ByEvent e -> Set.fromList $ allActiveBindings kc e
