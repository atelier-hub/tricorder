module Unit.Ghcib.WatchSpec (spec_Watch) where

import Data.Time (UTCTime (..), fromGregorian)
import Data.Time.Units (fromMicroseconds)
import Prettyprinter (Doc, defaultLayoutOptions, layoutPretty)
import Prettyprinter.Render.Text (renderStrict)
import Test.Hspec

import Atelier.Time (Millisecond)
import Ghcib.BuildState
    ( BuildId (..)
    , BuildPhase (..)
    , BuildState (..)
    , DaemonInfo (..)
    , Message (..)
    , Severity (..)
    )
import Ghcib.Effects.Display (Style)
import Ghcib.Render (buildStateDoc, daemonInfoDoc, messageDoc)


spec_Watch :: Spec
spec_Watch = do
    describe "buildStateDoc" do
        describe "Building" do
            it "shows 'Building...'" do
                render (buildStateDoc buildingState) `shouldContain` "Building..."

        describe "Done, no messages" do
            it "shows 'All good.'" do
                render (buildStateDoc (doneState [])) `shouldContain` "All good."

            it "shows duration" do
                render (buildStateDoc (doneState [])) `shouldContain` "500ms"

            it "includes daemon info" do
                render (buildStateDoc (doneState [])) `shouldContain` "Targets:"

        describe "Done, errors only" do
            it "shows error count" do
                render (buildStateDoc (doneState [errMsg])) `shouldContain` "1 error(s)"

            it "shows zero warnings" do
                render (buildStateDoc (doneState [errMsg])) `shouldContain` "0 warning(s)"

            it "includes the message location" do
                render (buildStateDoc (doneState [errMsg])) `shouldContain` "Foo.hs:10:1"

        describe "Done, warnings only" do
            it "shows warning count without error count" do
                let rendered = render (buildStateDoc (doneState [warnMsg]))
                rendered `shouldContain` "1 warning(s)"
                rendered `shouldNotContain` "error(s)"

        describe "Done, mixed" do
            it "shows both counts" do
                let rendered = render (buildStateDoc (doneState [errMsg, warnMsg]))
                rendered `shouldContain` "1 error(s)"
                rendered `shouldContain` "1 warning(s)"

    describe "messageDoc" do
        it "shows file location" do
            render (messageDoc errMsg) `shouldContain` "Foo.hs:10:1"

        it "shows 'error:' for SError" do
            render (messageDoc errMsg) `shouldContain` "error:"

        it "shows 'warning:' for SWarning" do
            render (messageDoc warnMsg) `shouldContain` "warning:"

        it "shows message text" do
            render (messageDoc errMsg) `shouldContain` "type mismatch"

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


halfSecond :: Millisecond
halfSecond = fromMicroseconds 500_000


emptyDaemonInfo :: DaemonInfo
emptyDaemonInfo = DaemonInfo {targets = [], watchDirs = [], sockPath = "", logFile = Nothing}


buildingState :: BuildState
buildingState = BuildState (BuildId 1) Building emptyDaemonInfo


doneState :: [Message] -> BuildState
doneState msgs = BuildState (BuildId 1) (Done epoch halfSecond msgs) emptyDaemonInfo


epoch :: UTCTime
epoch = UTCTime (fromGregorian 1970 1 1) 0


errMsg :: Message
errMsg =
    Message
        { severity = SError
        , file = "Foo.hs"
        , line = 10
        , col = 1
        , endLine = 10
        , endCol = 5
        , text = "type mismatch"
        }


warnMsg :: Message
warnMsg =
    Message
        { severity = SWarning
        , file = "Bar.hs"
        , line = 3
        , col = 1
        , endLine = 3
        , endCol = 10
        , text = "unused import"
        }
