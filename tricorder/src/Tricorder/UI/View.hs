module Tricorder.UI.View (view) where

import Brick
    ( AttrName
    , VScrollBarOrientation (..)
    , ViewportType (..)
    , Widget
    , attrName
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
    , txt
    , txtWrap
    , withClickableVScrollBars
    , withDefAttr
    , withVScrollBarHandles
    , withVScrollBars
    )
import Data.Time (UTCTime, defaultTimeLocale, formatTime, utcToLocalTime)
import System.FilePath (isAbsolute)

import Data.Text qualified as T

import Atelier.Effects.Clock (TimeZone)
import Tricorder.BuildState
    ( BuildPhase (..)
    , BuildProgress (..)
    , BuildResult (..)
    , BuildState (..)
    , DaemonInfo (..)
    , Diagnostic (..)
    , Severity (..)
    , TestRun (..)
    , TestRunCompletion (..)
    , TestRunError (..)
    )
import Tricorder.UI.Event (viewKeybindings)
import Tricorder.UI.Misc (emphasis, err, hBoxSpaced, ok, subtle, vBoxSpaced, warn)
import Tricorder.UI.State (Collapsible (..), Processed (..), State (..), Viewports (..))

import Tricorder.UI.Event qualified as Event


view :: State -> [Widget Viewports]
view ws =
    [ if ws.showHelp then
        viewHelp
      else case ws.buildState of
        Waiting ->
            vBoxSpaced
                1
                [ txt "Waiting for build..."
                , viewHint
                ]
        Failure reason ->
            vBoxSpaced
                1
                [ txt $ "Error when contacting daemon: " <> reason
                , viewHint
                ]
        Success bs ->
            viewBuildState ws bs
    ]


viewHelp :: Widget n
viewHelp =
    vBoxSpaced
        1
        [ ok $ txt "Keymap:"
        , viewKeybindings Event.keyConfig handlers
        , subtle $ txt "Press 'h' to go back"
        ]
  where
    handlers = (.khHandler) . snd <$> keyDispatcherToList Event.dispatcher


viewBuildState :: State -> BuildState -> Widget Viewports
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
viewHint = subtle $ txt "Press 'h' for help"


viewExpandedDaemonInfo :: DaemonInfo -> Widget n
viewExpandedDaemonInfo di =
    vBox
        $ [ viewTargets di.targets
          , viewWatchDirs di.watchDirs
          , viewApiUrl di.apiUrl
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


viewApiUrl :: Text -> Widget n
viewApiUrl url =
    hBoxSpaced 1 [emphasis $ txt "API:", txt url]


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


viewBuildPhase :: TimeZone -> BuildPhase -> Widget Viewports
viewBuildPhase tz = \case
    Building Nothing -> warn $ txt "Building..."
    Building (Just p) -> warn $ txt $ "Building (" <> show p.compiled <> "/" <> show p.total <> ")..."
    Restarting -> warn $ txt "Restarting..."
    Testing result -> vBoxSpaced 1 [viewBuildResult tz result, viewTestRuns result.testRuns]
    Done result -> vBoxSpaced 1 [viewBuildResult tz result, viewTestRuns result.testRuns]


viewBuildResult :: TimeZone -> BuildResult -> Widget Viewports
viewBuildResult tz result
    | null result.diagnostics =
        hBoxSpaced
            1
            [ ok $ txt "All good."
            , viewBuildSummary result.moduleCount result.durationMs
            , viewTimestamp tz result.completedAt
            ]
    | otherwise =
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
                , withClickableVScrollBars (\_ _ -> DiagnosticViewport)
                    $ withVScrollBarHandles
                    $ withVScrollBars OnRight
                    $ viewport DiagnosticViewport Vertical
                    $ vBox
                    $ viewDiagnostic <$> msgs
                ]


viewDiagnostic :: Diagnostic -> Widget n
viewDiagnostic m =
    vBox
        [ hBoxSpaced
            1
            [ severityLabel
            , txt $ toText loc
            ]
        , txtWrap m.text
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
viewTestRun (TestRunning t) = hBox [txt t, txt "  ", warn $ txt "running..."]
viewTestRun (TestRunErrored e) = hBox [txt e.target, txt "  ", err $ txt "error: ", txt e.message]
viewTestRun (TestRunCompleted c) =
    hBox [txt c.target, txt "  ", if c.passed then ok (txt "passed") else err (txt "failed")]


viewTimestamp :: TimeZone -> UTCTime -> Widget n
viewTimestamp tz t = txt $ "— " <> toText (formatTime defaultTimeLocale "%H:%M:%S" $ utcToLocalTime tz t)


viewBuildSummary :: Int -> Int -> Widget n
viewBuildSummary moduleCount durationMs =
    txt $ "(" <> show moduleCount <> " modules, " <> formatDuration durationMs <> ")"


formatDuration :: Int -> Text
formatDuration ms =
    if ms < 1000 then
        show ms <> "ms"
    else
        show (ms `div` 1000) <> "." <> show ((ms `mod` 1000) `div` 100) <> "s"
