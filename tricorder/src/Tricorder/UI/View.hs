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
import Brick.Keybindings (KeyConfig, KeyHandler (..), keyDispatcherToList)
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
import Atelier.Time (Millisecond, toMicroseconds)
import Tricorder.BuildState
    ( BuildPhase (..)
    , BuildProgress (..)
    , BuildResult (..)
    , BuildState (..)
    , DaemonInfo (..)
    , Diagnostic (..)
    , Severity (..)
    , TestCase (..)
    , TestCaseOutcome (..)
    , TestRun (..)
    , TestRunCompletion (..)
    , TestRunError (..)
    )
import Tricorder.TestOutput (stripGhciNoise)
import Tricorder.UI.Keys (KeyEvent, viewKeybindings)
import Tricorder.UI.Misc (emphasis, err, hBoxSpaced, ok, subtle, vBoxSpaced, warn)
import Tricorder.UI.State (ActiveView (..), Processed (..), State (..), TestView (..), Viewports (..), currentView)

import Tricorder.UI.Keys qualified as Keys
import Tricorder.Version qualified as Version


view :: KeyConfig KeyEvent -> State -> [Widget Viewports]
view kc ws =
    [ case currentView ws of
        Just ViewHelp ->
            viewHelp kc
        Just ViewDaemonInfo ->
            withHint $ withBuildState ws (viewDaemonInfoPanel ws.timeZone)
        Just (ViewTestResults tv) ->
            withHint $ withBuildState ws (viewTestResultsPanel ws.timeZone tv)
        Nothing ->
            withHint $ withBuildState ws (viewDefaultPanel ws.timeZone)
    ]


withBuildState :: State -> (BuildState -> Widget Viewports) -> Widget Viewports
withBuildState ws render =
    case ws.buildState of
        Waiting ->
            txt "Waiting for build..."
        Failure reason ->
            txt $ "Error when contacting daemon: " <> reason
        Success bs ->
            render bs


withHint :: Widget n -> Widget n
withHint content = vBox [padBottom Max content, viewHint]


viewHelp :: KeyConfig KeyEvent -> Widget n
viewHelp kc =
    vBox
        [ padBottom Max $ vBoxSpaced 1 [ok $ txt "Keymap:", viewKeybindings kc handlers]
        , subtle $ txt "Press 'h' to go back"
        ]
  where
    handlers = (.khHandler) . snd <$> keyDispatcherToList (Keys.dispatcher kc)


viewDefaultPanel :: TimeZone -> BuildState -> Widget Viewports
viewDefaultPanel tz bs = viewBuildPhase tz bs.phase


viewDaemonInfoPanel :: TimeZone -> BuildState -> Widget Viewports
viewDaemonInfoPanel tz bs =
    vBoxSpaced
        1
        [ viewBuildPhaseLine tz bs.phase
        , viewExpandedDaemonInfo bs.daemonInfo
        ]


viewTestResultsPanel :: TimeZone -> TestView -> BuildState -> Widget Viewports
viewTestResultsPanel tz tv bs =
    vBoxSpaced
        1
        [ viewBuildPhaseLine tz bs.phase
        , viewTestPanel tv (phaseTestRuns bs.phase)
        ]


viewHint :: Widget n
viewHint = subtle $ txt "Press 'h' for help"


viewExpandedDaemonInfo :: DaemonInfo -> Widget n
viewExpandedDaemonInfo di =
    vBox
        [ viewVersion
        , viewTargets di.targets
        , viewWatchDirs di.watchDirs
        , viewSockPath di.sockPath
        , viewLogFile di.logFile
        , viewMetrics di.metricsPort
        ]


viewVersion :: Widget n
viewVersion =
    hBoxSpaced
        1
        [ emphasis $ txt "Client version:"
        , txt Version.gitHash
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


viewLogFile :: FilePath -> Widget n
viewLogFile p = hBoxSpaced 1 [emphasis $ txt "Log:", txt $ toText p]


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
            , viewBuildSummary result.moduleCount result.duration
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
                    , viewDuration result.duration
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


viewDuration :: Millisecond -> Widget n
viewDuration d = txt $ "(" <> formatDuration d <> ")"


viewTestRuns :: [TestRun] -> Widget n
viewTestRuns [] = emptyWidget
viewTestRuns runs = vBox $ viewTestRun <$> runs


viewTestRun :: TestRun -> Widget n
viewTestRun (TestRunning t Nothing) = hBox [txt t, txt "  ", warn $ txt "running..."]
viewTestRun (TestRunning t (Just p)) =
    hBox [txt t, txt "  ", warn $ txt $ "running... (" <> show p.compiled <> "/" <> show p.total <> ")"]
viewTestRun (TestRunErrored e) = hBox [txt e.target, txt "  ", err $ txt "error: ", txt e.message]
viewTestRun (TestRunCompleted c) = hBox [txt c.target, txt "  ", viewCompletionStatus c]


viewCompletionStatus :: TestRunCompletion -> Widget n
viewCompletionStatus c = case c.duration of
    Nothing -> statusWidget
    Just d -> hBoxSpaced 1 [statusWidget, subtle $ viewDuration d]
  where
    statusWidget
        | null c.testCases = if c.passed then ok (txt "passed") else err (txt "failed")
        | otherwise =
            let total = length c.testCases
                failed = length $ filter isCaseFailed c.testCases
            in  if failed == 0 then
                    ok $ txt $ "passed (" <> show total <> ")"
                else
                    err $ txt $ show failed <> "/" <> show total <> " failed"


viewTimestamp :: TimeZone -> UTCTime -> Widget n
viewTimestamp tz t = txt $ "— " <> toText (formatTime defaultTimeLocale "%H:%M:%S" $ utcToLocalTime tz t)


viewBuildSummary :: Int -> Millisecond -> Widget n
viewBuildSummary moduleCount duration =
    txt $ "(" <> show moduleCount <> " modules, " <> formatDuration duration <> ")"


formatDuration :: Millisecond -> Text
formatDuration d =
    let ms = toMicroseconds d `div` 1000
    in  if ms < 1000 then
            show ms <> "ms"
        else
            show (ms `div` 1000) <> "." <> show ((ms `mod` 1000) `div` 100) <> "s"


-- | Single-line build status with no scrollable diagnostics list, used as a
-- compact header when a secondary panel (test results, daemon info) is open.
viewBuildPhaseLine :: TimeZone -> BuildPhase -> Widget n
viewBuildPhaseLine tz = \case
    Building Nothing -> warn $ txt "Building..."
    Building (Just p) -> warn $ txt $ "Building (" <> show p.compiled <> "/" <> show p.total <> ")..."
    Restarting -> warn $ txt "Restarting..."
    Testing result -> viewBuildResultLine tz result
    Done result -> viewBuildResultLine tz result


viewBuildResultLine :: TimeZone -> BuildResult -> Widget n
viewBuildResultLine tz result
    | null result.diagnostics =
        hBoxSpaced
            1
            [ ok $ txt "All good."
            , viewBuildSummary result.moduleCount result.duration
            , viewTimestamp tz result.completedAt
            ]
    | otherwise =
        let errCount = length $ filter (\m -> m.severity == SError) result.diagnostics
            warnCount = length $ filter (\m -> m.severity == SWarning) result.diagnostics
            header =
                if errCount > 0 then
                    err $ txt $ show errCount <> " error(s), " <> show warnCount <> " warning(s)"
                else
                    warn $ txt $ show warnCount <> " warning(s)"
        in  hBoxSpaced 1 [header, viewDuration result.duration, viewTimestamp tz result.completedAt]


phaseTestRuns :: BuildPhase -> [TestRun]
phaseTestRuns (Testing r) = r.testRuns
phaseTestRuns (Done r) = r.testRuns
phaseTestRuns _ = []


viewTestPanel :: TestView -> [TestRun] -> Widget Viewports
viewTestPanel _ [] = subtle $ txt "No test results."
viewTestPanel tv runs = scrollableRuns tv runs


scrollableRuns :: TestView -> [TestRun] -> Widget Viewports
scrollableRuns tv runs =
    withClickableVScrollBars (\_ _ -> TestViewport)
        $ withVScrollBarHandles
        $ withVScrollBars OnRight
        $ viewport TestViewport Vertical
        $ vBox
        $ viewTestRunDetail tv <$> runs


viewTestRunDetail :: TestView -> TestRun -> Widget n
viewTestRunDetail _ (TestRunning t Nothing) = hBox [txt t, txt "  ", warn $ txt "running..."]
viewTestRunDetail _ (TestRunning t (Just p)) =
    hBox [txt t, txt "  ", warn $ txt $ "running... (" <> show p.compiled <> "/" <> show p.total <> ")"]
viewTestRunDetail _ (TestRunErrored e) = hBoxSpaced 1 [txt e.target, err $ txt "error:", txt e.message]
viewTestRunDetail tv (TestRunCompleted c) =
    vBox
        [ hBox [txt c.target, txt "  ", viewCompletionStatus c]
        , viewTestOutput tv c
        ]


viewTestOutput :: TestView -> TestRunCompletion -> Widget n
viewTestOutput TestViewFull c =
    padLeft (Pad 2) $ vBox $ txt <$> stripGhciNoise (T.lines c.output)
viewTestOutput TestViewFailOnly c
    | not (any isCaseFailed c.testCases) && c.passed = emptyWidget
    | null c.testCases =
        padLeft (Pad 2)
            $ vBox
                [ subtle $ txt "(unrecognised test runner — showing full output)"
                , vBox $ txt <$> stripGhciNoise (T.lines c.output)
                ]
    | otherwise =
        padLeft (Pad 2) $ vBox $ viewFailedCase <$> filter isCaseFailed c.testCases


isCaseFailed :: TestCase -> Bool
isCaseFailed (TestCase _ (TestCaseFailed _)) = True
isCaseFailed _ = False


viewFailedCase :: TestCase -> Widget n
viewFailedCase tc =
    vBox
        [ err $ txt tc.description
        , case tc.outcome of
            TestCaseFailed details -> padLeft (Pad 2) $ txtWrap details
            TestCasePassed -> emptyWidget
        ]
