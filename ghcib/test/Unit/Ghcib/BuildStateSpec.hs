module Unit.Ghcib.BuildStateSpec (spec_BuildState) where

import Data.Aeson (eitherDecode, encode)
import Data.Time (UTCTime (..), fromGregorian)
import Test.Hspec

import Ghcib.BuildState (BuildId (..), BuildPhase (..), BuildResult (..), BuildState (..), DaemonInfo (..), Diagnostic (..), Severity (..))


spec_BuildState :: Spec
spec_BuildState = do
    describe "JSON round-trip" do
        it "survives Unicode smart quotes in message text" do
            let msg =
                    Diagnostic
                        { severity = SWarning
                        , file = "<interactive>"
                        , line = 2
                        , col = 8
                        , endLine = 2
                        , endCol = 8
                        , title = "Found \8216qualified\8217 in prepositive position"
                        , text = "Found \8216qualified\8217 in prepositive position\n    Suggested fixes:\n      \8226 Place \8216qualified\8217 after the module name."
                        }
                bs = mkBuildState [msg]
            eitherDecode (encode bs) `shouldBe` Right bs

        it "survives control characters in message text" do
            let msg =
                    Diagnostic
                        { severity = SWarning
                        , file = "<interactive>"
                        , line = 1
                        , col = 1
                        , endLine = 1
                        , endCol = 1
                        , title = "text with \CAN control \EM chars and \ESC[1m ANSI \ESC[0m codes"
                        , text = "text with \CAN control \EM chars and \ESC[1m ANSI \ESC[0m codes"
                        }
                bs = mkBuildState [msg]
            eitherDecode (encode bs) `shouldBe` Right bs

        it "survives curly double quotes in message text" do
            let msg =
                    Diagnostic
                        { severity = SWarning
                        , file = "<interactive>"
                        , line = 1
                        , col = 1
                        , endLine = 1
                        , endCol = 1
                        , title = "\8220Place qualified after the module name.\8221"
                        , text = "\8220Place qualified after the module name.\8221"
                        }
                bs = mkBuildState [msg]
            eitherDecode (encode bs) `shouldBe` Right bs


mkBuildState :: [Diagnostic] -> BuildState
mkBuildState msgs =
    BuildState
        { buildId = BuildId 1
        , phase = Done (BuildResult {completedAt = epoch, durationMs = 0, moduleCount = 0, diagnostics = msgs, testRuns = []})
        , daemonInfo = DaemonInfo {targets = [], watchDirs = [], sockPath = "", logFile = Nothing, metricsPort = Nothing}
        }
  where
    epoch = UTCTime (fromGregorian 1970 1 1) 0
