module Tricorder.Watch.View (view) where

import Brick
    ( AttrName
    , ViewportType (..)
    , Widget
    , attrName
    , str
    , vBox
    , viewport
    )
import Brick.Keybindings (KeyHandler (..), keyDispatcherToList)
import Brick.Widgets.Core
    ( Padding (..)
    , emptyWidget
    , hBox
    , padBottom
    , padLeft
    , padTop
    , txt
    , txtWrap
    , withDefAttr
    )
import Data.Time (UTCTime, defaultTimeLocale, formatTime, utcToLocalTime)
import System.FilePath (isAbsolute)

import Data.Text qualified as T

import Atelier.Effects.Clock (TimeZone)
import Tricorder.BuildState
    ( BuildPhase (..)
    , BuildResult (..)
    , BuildState (..)
    , DaemonInfo (..)
    , Diagnostic (..)
    , Severity (..)
    , TestOutcome (..)
    , TestRun (..)
    )
import Tricorder.Watch.Event (viewKeybindings)
import Tricorder.Watch.State (Collapsible (..), Name (..), State (..))

import Tricorder.Watch.Event qualified as Event


view :: State -> [Widget Name]
view ws =
    [ case ws.buildState of
        Nothing -> str "Waiting for build..."
        Just bs ->
            viewport Watcher Vertical
                $ if ws.showHelp then
                    viewHelp
                else
                    viewBuildState ws bs
    ]


viewHelp :: Widget n
viewHelp =
    vBoxSpaced
        1
        [ txt "Keymap:"
        , viewKeybindings Event.keyConfig handlers
        , txt "Press h to go back"
        ]
  where
    handlers = (.khHandler) . snd <$> keyDispatcherToList Event.dispatcher


viewBuildState :: State -> BuildState -> Widget n
viewBuildState state bs =
    vBoxSpaced
        1
        [ viewBuildPhase state.timeZone bs.phase
        , viewDaemonInfo state bs.daemonInfo
        ]


viewDaemonInfo :: State -> DaemonInfo -> Widget n
viewDaemonInfo state di =
    vBox
        [ case state.daemonInfoView of
            Expanded ->
                padBottom (Pad 1)
                    $ viewExpandedDaemonInfo di
            Collapsed ->
                emptyWidget
        , viewHint
        ]
viewHint :: Widget n
viewHint = txt "Press 'h' for help"


viewExpandedDaemonInfo :: DaemonInfo -> Widget n
viewExpandedDaemonInfo di =
    vBox
        $ [ viewTargets di.targets
          , viewWatchDirs di.watchDirs
          , viewSockPath di.sockPath
          , viewLogFile di.logFile
          , viewMetrics di.metricsPort
          ]


viewTargets :: [Text] -> Widget n
viewTargets targets =
    hBoxSpaced
        1
        [ emphasis $ txt "Targets:"
        , if null targets then
            txt "(all)"
          else
            txtWrap (T.intercalate " " targets)
        ]


viewMetrics :: Maybe Int -> Widget n
viewMetrics Nothing =
    hBoxSpaced
        1
        [ emphasis $ txt "Metrics:"
        , warn $ txt "disabled"
        ]
viewMetrics (Just port) =
    hBoxSpaced
        1
        [ emphasis $ txt "Metrics:"
        , ok $ txt $ "http://localhost:" <> show port <> "/metrics"
        ]


viewLogFile :: Maybe FilePath -> Widget n
viewLogFile = \case
    Nothing -> emptyWidget
    Just p -> hBoxSpaced 1 [emphasis $ txt "Log:", txt $ toText p]


viewSockPath :: FilePath -> Widget n
viewSockPath sockPath =
    hBoxSpaced 1 [emphasis $ txt "Socket:", txt $ toText sockPath]


viewWatchDirs :: [FilePath] -> Widget n
viewWatchDirs watchDirs =
    vBox
        [ emphasis $ txt "Watching:"
        , padLeft (Pad 2)
            $ vBox
            $ viewWatchDir <$> watchDirs
        ]


viewWatchDir :: FilePath -> Widget n
viewWatchDir dir = hBox [txt "- ", txt $ toText displayDir]
  where
    displayDir
        | isAbsolute dir = dir
        | dir == "." = "./"
        | otherwise = "./" <> dir


viewBuildPhase :: TimeZone -> BuildPhase -> Widget n
viewBuildPhase tz = \case
    Building -> warn $ txt "Building..."
    Testing -> warn $ txt "Testing..."
    Done result
        | null result.diagnostics ->
            vBoxSpaced
                1
                [ hBoxSpaced
                    1
                    [ ok $ txt "All good."
                    , viewBuildSummary result.moduleCount result.durationMs
                    , viewTimestamp tz result.completedAt
                    ]
                , viewTestRuns result.testRuns
                ]
    Done result ->
        let msgs = result.diagnostics
            errCount = length $ filter (\m -> m.severity == SError) msgs
            warnCount = length $ filter (\m -> m.severity == SWarning) msgs
            header =
                if errCount > 0 then
                    err $ txt $ show errCount <> " error(s), " <> show warnCount <> " warning(s)"
                else
                    warn $ txt $ show warnCount <> " warning(s)"
        in  vBoxSpaced
                1
                [ hBoxSpaced
                    1
                    [ header
                    , viewDuration result.durationMs
                    , viewTimestamp tz result.completedAt
                    ]
                , vBox $ viewDiagnostic <$> msgs
                , viewTestRuns result.testRuns
                ]


viewDiagnostic :: Diagnostic -> Widget n
viewDiagnostic m =
    vBox
        [ hBoxSpaced
            1
            [ severityLabel
            , txt $ toText loc
            ]
        , txt m.text
        ]
  where
    loc = m.file <> ":" <> show m.line <> ":" <> show m.col
    severityLabel = withDefAttr (severityToAttrName m.severity) $ txt $ case m.severity of
        SError -> "error:"
        SWarning -> "warning:"


severityToAttrName :: Severity -> AttrName
severityToAttrName SError = attrName "error"
severityToAttrName SWarning = attrName "warning"


viewDuration :: Int -> Widget n
viewDuration ms = txt $ "(" <> formatDuration ms <> ")"


viewTestRuns :: [TestRun] -> Widget n
viewTestRuns [] = emptyWidget
viewTestRuns runs = vBox $ viewTestRun <$> runs


viewTestRun :: TestRun -> Widget n
viewTestRun tr = hBox [txt tr.target, txt "  ", viewTestOutcome tr.outcome]


viewTestOutcome :: TestOutcome -> Widget n
viewTestOutcome TestsPassed = ok $ txt "passed"
viewTestOutcome TestsFailed = err $ txt "failed"
viewTestOutcome (TestsError msg) = hBox [err $ txt "error:", txt msg]


viewTimestamp :: TimeZone -> UTCTime -> Widget n
viewTimestamp tz t = txt $ "— " <> toText (formatTime defaultTimeLocale "%H:%M:%S" $ utcToLocalTime tz t)


viewBuildSummary :: Int -> Int -> Widget n
viewBuildSummary moduleCount durationMs =
    txt $ "(" <> show moduleCount <> " modules, " <> formatDuration durationMs <> ")"


err :: Widget n -> Widget n
err = withDefAttr $ attrName "error"


warn :: Widget n -> Widget n
warn = withDefAttr $ attrName "warning"


ok :: Widget n -> Widget n
ok = withDefAttr $ attrName "ok"


emphasis :: Widget n -> Widget n
emphasis = withDefAttr $ attrName "emphasis"


formatDuration :: Int -> Text
formatDuration ms =
    if ms < 1000 then
        show ms <> "ms"
    else
        show (ms `div` 1000) <> "." <> show ((ms `mod` 1000) `div` 100) <> "s"


hBoxSpaced :: Int -> [Widget n] -> Widget n
hBoxSpaced _ [] = hBox []
hBoxSpaced pad (x : xs) = hBox $ x : (padLeft (Pad pad) <$> xs)


vBoxSpaced :: Int -> [Widget n] -> Widget n
vBoxSpaced _ [] = vBox []
vBoxSpaced pad (x : xs) = vBox $ x : (padTop (Pad pad) <$> xs)
