module Unit.Ghcib.WatchSpec (spec_Watch) where

import Data.Time (UTCTime (..), fromGregorian)
import Data.Time.LocalTime (utc)
import Prettyprinter (Doc, defaultLayoutOptions, layoutPretty)
import Prettyprinter.Render.Text (renderStrict)
import Test.Hspec

import Ghcib.BuildState
    ( BuildId (..)
    , BuildPhase (..)
    , BuildResult (..)
    , BuildState (..)
    , DaemonInfo (..)
    , Diagnostic (..)
    , Severity (..)
    )
import Ghcib.Effects.Display (Style)
import Ghcib.Render (buildStateDoc, daemonInfoDoc, diagnosticBlock, diagnosticDoc)


spec_Watch :: Spec
spec_Watch = do
    describe "buildStateDoc" do
        describe "Building" do
            it "shows 'Building...'" do
                render (buildStateDoc utc buildingState) `shouldContain` "Building..."

        describe "Done, no messages" do
            it "shows 'All good.'" do
                render (buildStateDoc utc (doneState 0 [])) `shouldContain` "All good."

            it "shows duration" do
                render (buildStateDoc utc (doneState 0 [])) `shouldContain` "500ms"

            it "shows module count" do
                render (buildStateDoc utc (doneState 42 [])) `shouldContain` "42 modules"

            it "includes daemon info" do
                render (buildStateDoc utc (doneState 0 [])) `shouldContain` "Targets:"

        describe "Done, errors only" do
            it "shows error count" do
                render (buildStateDoc utc (doneState 0 [errMsg])) `shouldContain` "1 error(s)"

            it "shows zero warnings" do
                render (buildStateDoc utc (doneState 0 [errMsg])) `shouldContain` "0 warning(s)"

            it "includes the message location" do
                render (buildStateDoc utc (doneState 0 [errMsg])) `shouldContain` "Foo.hs:10:1"

        describe "Done, warnings only" do
            it "shows warning count without error count" do
                let rendered = render (buildStateDoc utc (doneState 0 [warnMsg]))
                rendered `shouldContain` "1 warning(s)"
                rendered `shouldNotContain` "error(s)"

        describe "Done, mixed" do
            it "shows both counts" do
                let rendered = render (buildStateDoc utc (doneState 0 [errMsg, warnMsg]))
                rendered `shouldContain` "1 error(s)"
                rendered `shouldContain` "1 warning(s)"

    describe "diagnosticDoc" do
        it "shows file location" do
            render (diagnosticDoc errMsg) `shouldContain` "Foo.hs:10:1"

        it "shows 'error:' for SError" do
            render (diagnosticDoc errMsg) `shouldContain` "error:"

        it "shows 'warning:' for SWarning" do
            render (diagnosticDoc warnMsg) `shouldContain` "warning:"

        it "shows message text" do
            render (diagnosticDoc errMsg) `shouldContain` "type mismatch"

    describe "diagnosticBlock" do
        it "includes the one-liner prefix for an error" do
            diagnosticBlock errMsg `shouldContain` "E Foo.hs:10 type mismatch"

        it "includes the full text body after the first line" do
            diagnosticBlock errMsg `shouldContain` "\ntype mismatch"

        it "uses 'W' prefix for warnings" do
            diagnosticBlock warnMsg `shouldContain` "W Bar.hs:3 unused import"

        it "contains both title and text when they differ" do
            let d = mixedMsg
            diagnosticBlock d `shouldContain` "short title"
            diagnosticBlock d `shouldContain` "full body of the message"

    describe "daemonInfoDoc" do
        it "shows '(all)' when targets is empty" do
            render (daemonInfoDoc emptyDaemonInfo) `shouldContain` "(all)"

        it "shows configured targets" do
            let di = emptyDaemonInfo {targets = ["lib:foo", "exe:bar"]}
            render (daemonInfoDoc di) `shouldContain` "lib:foo exe:bar"

        it "shows watch directories" do
            let di = emptyDaemonInfo {watchDirs = ["src", "app"]}
            let rendered = render (daemonInfoDoc di)
            rendered `shouldContain` "- ./src"
            rendered `shouldContain` "- ./app"

        it "shows socket path" do
            let di = emptyDaemonInfo {sockPath = "/run/user/1000/ghcib/abc.sock"}
            render (daemonInfoDoc di) `shouldContain` "/run/user/1000/ghcib/abc.sock"

        it "omits Log line when logFile is Nothing" do
            render (daemonInfoDoc emptyDaemonInfo) `shouldNotContain` "Log:"

        it "shows log file path when configured" do
            let di = emptyDaemonInfo {logFile = Just "/tmp/ghcib.log"}
            render (daemonInfoDoc di) `shouldContain` "/tmp/ghcib.log"


--------------------------------------------------------------------------------
-- Helpers
--------------------------------------------------------------------------------

render :: Doc Style -> String
render = toString . renderStrict . layoutPretty defaultLayoutOptions


emptyDaemonInfo :: DaemonInfo
emptyDaemonInfo = DaemonInfo {targets = [], watchDirs = [], sockPath = "", logFile = Nothing}


buildingState :: BuildState
buildingState = BuildState (BuildId 1) Building emptyDaemonInfo


doneState :: Int -> [Diagnostic] -> BuildState
doneState mods msgs = BuildState (BuildId 1) (Done (BuildResult {completedAt = epoch, durationMs = 500, moduleCount = mods, diagnostics = msgs})) emptyDaemonInfo


epoch :: UTCTime
epoch = UTCTime (fromGregorian 1970 1 1) 0


errMsg :: Diagnostic
errMsg =
    Diagnostic
        { severity = SError
        , file = "Foo.hs"
        , line = 10
        , col = 1
        , endLine = 10
        , endCol = 5
        , title = "type mismatch"
        , text = "type mismatch"
        }


warnMsg :: Diagnostic
warnMsg =
    Diagnostic
        { severity = SWarning
        , file = "Bar.hs"
        , line = 3
        , col = 1
        , endLine = 3
        , endCol = 10
        , title = "unused import"
        , text = "unused import"
        }


mixedMsg :: Diagnostic
mixedMsg =
    Diagnostic
        { severity = SError
        , file = "Baz.hs"
        , line = 5
        , col = 1
        , endLine = 5
        , endCol = 20
        , title = "short title"
        , text = "full body of the message"
        }
