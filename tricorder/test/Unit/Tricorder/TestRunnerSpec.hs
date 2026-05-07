module Unit.Tricorder.TestRunnerSpec (spec_TestRunner) where

import Control.Exception (ErrorCall (..))
import Effectful (IOE, runEff)
import Effectful.Exception (try)
import Test.Hspec

import Tricorder.BuildState (TestOutcome (..), TestRun (..))
import Tricorder.Effects.TestRunner
    ( TestRunner
    , detectOutcome
    , runTestRunnerScripted
    , runTestSuite
    )


spec_TestRunner :: Spec
spec_TestRunner = do
    describe "detectOutcome" testDetectOutcome
    describe "runTestRunnerScripted" testScripted


--------------------------------------------------------------------------------
-- detectOutcome tests
--------------------------------------------------------------------------------

testDetectOutcome :: Spec
testDetectOutcome = do
    describe "no exception line" do
        it "treats empty output as pass" do
            detectOutcome "" `shouldBe` TestsPassed

        it "treats output with no exception as pass" do
            detectOutcome "2 examples, 0 failures\n" `shouldBe` TestsPassed

        it "does not match 'ExitSuccess' without the exception prefix" do
            detectOutcome "ExitSuccess\n" `shouldBe` TestsPassed

    describe "ExitSuccess" do
        it "detects ExitSuccess as pass" do
            detectOutcome "*** Exception: ExitSuccess\n" `shouldBe` TestsPassed

        it "detects ExitSuccess anywhere in output" do
            detectOutcome "All tests passed\n*** Exception: ExitSuccess\n"
                `shouldBe` TestsPassed

    describe "ExitFailure" do
        it "detects ExitFailure 1 as fail" do
            detectOutcome "1 failure\n*** Exception: ExitFailure 1\n"
                `shouldBe` TestsFailed

        it "detects ExitFailure with any exit code as fail" do
            detectOutcome "*** Exception: ExitFailure 42\n" `shouldBe` TestsFailed

        it "detects ExitFailure anywhere in output" do
            detectOutcome "Some output\n*** Exception: ExitFailure 1\nMore output\n"
                `shouldBe` TestsFailed

    describe "other exception" do
        it "classifies unknown exception as error with message" do
            detectOutcome "*** Exception: SomeException \"oops\"\n"
                `shouldBe` TestsError "SomeException \"oops\""

        it "trims trailing whitespace from the error message" do
            detectOutcome "*** Exception: Crashed  \n"
                `shouldBe` TestsError "Crashed"


--------------------------------------------------------------------------------
-- Scripted interpreter tests
--------------------------------------------------------------------------------

testScripted :: Spec
testScripted = do
    it "returns scripted TestRun" do
        result <- runScripted [Right passingRun] $ runTestSuite "test:foo"
        result `shouldBe` passingRun

    it "ignores the target name argument" do
        result <- runScripted [Right failingRun] $ runTestSuite "test:anything"
        result `shouldBe` failingRun

    it "throws when scripted result is Left" do
        result <-
            runScripted [Left (toException boom)]
                $ try @ErrorCall
                $ runTestSuite "test:foo"
        result `shouldBe` Left boom

    describe "sequencing" do
        it "consumes results in order across multiple calls" do
            (a, b) <- runScripted [Right passingRun, Right failingRun] do
                a <- runTestSuite "test:foo"
                b <- runTestSuite "test:bar"
                pure (a, b)
            a `shouldBe` passingRun
            b `shouldBe` failingRun

        it "recover scenario: error then success" do
            result <- runScripted [Left (toException boom), Right passingRun] do
                r1 <- try @ErrorCall $ runTestSuite "test:foo"
                r2 <- runTestSuite "test:bar"
                pure (r1, r2)
            fst result `shouldBe` Left boom
            snd result `shouldBe` passingRun


--------------------------------------------------------------------------------
-- Helpers
--------------------------------------------------------------------------------

boom :: ErrorCall
boom = ErrorCall "simulated process crash"


passingRun :: TestRun
passingRun = TestRun {target = "test:foo", outcome = TestsPassed, output = "2 examples, 0 failures\n", testCases = []}


failingRun :: TestRun
failingRun = TestRun {target = "test:bar", outcome = TestsFailed, output = "1 example, 1 failure\n", testCases = []}


runScripted :: [Either SomeException TestRun] -> Eff '[TestRunner, IOE] a -> IO a
runScripted results = runEff . runTestRunnerScripted results
