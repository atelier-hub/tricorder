module Tricorder.UI.Keys
    ( KeyEvent
    , Config
    , keys
    , dispatcher
    , viewKeybindings
    , mkKeyConfig
    , keybindForRoute
    ) where

import Atelier.Effects.Console (Console)
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
import Brick.Keybindings.KeyConfig (firstActiveBinding)
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

import Atelier.Effects.Console qualified as Console
import Data.Map.Strict qualified as Map
import Data.Set qualified as Set
import Data.Text qualified as T

import Tricorder.UI.Misc (warn)
import Tricorder.UI.Route (Route)
import Tricorder.UI.State
    ( State (..)
    , Viewports (..)
    , currentRoute
    , cycleTestFilter
    , navigate
    , viewToViewport
    )

import Tricorder.UI.Route qualified as Route


-- When adding a new event here, also list it in the README under "Custom Key Bindings".
data KeyEvent
    = ToggleDaemonInfoView
    | ToggleHelp
    | CycleTestView
    | ExitView
    | ScrollUp
    | ScrollDown
    | Quit
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
        , ("toggle help", ToggleHelp)
        , ("cycle test view", CycleTestView)
        , ("exit view", ExitView)
        , ("scroll up", ScrollUp)
        , ("scroll down", ScrollDown)
        , ("quit", Quit)
        ]


bindings :: [(KeyEvent, [Binding])]
bindings =
    [ (ToggleDaemonInfoView, [bind 'g'])
    , (ToggleHelp, [bind 'h'])
    , (CycleTestView, [bind 't'])
    , (ExitView, [binding KEsc []])
    , (ScrollUp, [binding KUp []])
    , (ScrollDown, [binding KDown []])
    , (Quit, [bind 'q', ctrl 'c'])
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
                    if currentRoute s == Route.DaemonInfo then
                        navigate Route.Main s
                    else
                        navigate Route.DaemonInfo s
            , onEvent ToggleHelp "Toggle help" do
                modify \s ->
                    if currentRoute s == Route.Help then
                        navigate Route.Main s
                    else
                        navigate Route.Help s
            , onEvent CycleTestView "Cycle test results view" do
                modify \s -> case currentRoute s of
                    Route.Tests ->
                        if s.testFilter == maxBound then
                            navigate Route.Main s {testFilter = minBound}
                        else
                            s {testFilter = cycleTestFilter s.testFilter}
                    _ -> navigate Route.Tests s
            , onEvent ExitView "Exit or go back" do
                gets (.route) >>= \case
                    Route.Main -> halt
                    _ -> modify $ navigate Route.Main
            , onEvent ScrollUp "Scroll up" do
                mvp <- gets (viewToViewport . currentRoute)
                case mvp of
                    Just vp -> vScrollBy (viewportScroll vp) (-1)
                    Nothing -> pure ()
            , onEvent ScrollDown "Scroll down" do
                mvp <- gets (viewToViewport . currentRoute)
                case mvp of
                    Just vp ->
                        vScrollBy (viewportScroll vp) 1
                    Nothing -> pure ()
            , onEvent Quit "Exit" do
                halt
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
viewEventAndTriggers kc eventName triggers =
    hBox
        [ warn $ txt $ eventName <> ": "
        , txt $ showBindings $ mconcat $ getBindings <$> triggers
        ]
  where
    showBindings = T.intercalate ", " . fmap ppBinding . sort . toList
    getBindings = \case
        ByKey k -> Set.singleton k
        ByEvent e -> Set.fromList $ allActiveBindings kc e


keybindForRoute :: KeyConfig KeyEvent -> Route -> Maybe Binding
keybindForRoute kc = \case
    Route.Main -> Nothing
    Route.DaemonInfo -> firstActiveBinding kc ToggleDaemonInfoView
    Route.Help -> firstActiveBinding kc ToggleHelp
    Route.Tests -> firstActiveBinding kc CycleTestView
