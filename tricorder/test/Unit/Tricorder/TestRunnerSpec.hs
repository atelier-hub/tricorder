module Unit.Tricorder.TestRunnerSpec (spec_TestRunner) where

import Data.IORef (modifyIORef', newIORef, readIORef)
import Effectful (IOE, runEff)
import Test.Hspec

import Tricorder.BuildState (TestRun (..), TestRunCompletion (..))
import Tricorder.Effects.TestRunner
    ( BatchStatus (..)
    , GhciOutcome (..)
    , TestRunOutcome (..)
    , TestRunner
    , detectOutcome
    , runTestRunnerScripted
    , withBatch
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
            detectOutcome "" `shouldBe` GhciPassed

        it "treats output with no exception as pass" do
            detectOutcome "2 examples, 0 failures\n" `shouldBe` GhciPassed

        it "does not match 'ExitSuccess' without the exception prefix" do
            detectOutcome "ExitSuccess\n" `shouldBe` GhciPassed

    describe "ExitSuccess" do
        it "detects ExitSuccess as pass" do
            detectOutcome "*** Exception: ExitSuccess\n" `shouldBe` GhciPassed

        it "detects ExitSuccess anywhere in output" do
            detectOutcome "All tests passed\n*** Exception: ExitSuccess\n"
                `shouldBe` GhciPassed

    describe "ExitFailure" do
        it "detects ExitFailure 1 as fail" do
            detectOutcome "1 failure\n*** Exception: ExitFailure 1\n"
                `shouldBe` GhciFailed

        it "detects ExitFailure with any exit code as fail" do
            detectOutcome "*** Exception: ExitFailure 42\n" `shouldBe` GhciFailed

        it "detects ExitFailure anywhere in output" do
            detectOutcome "Some output\n*** Exception: ExitFailure 1\nMore output\n"
                `shouldBe` GhciFailed

    describe "other exception" do
        it "classifies unknown exception as error with message" do
            detectOutcome "*** Exception: SomeException \"oops\"\n"
                `shouldBe` GhciCrashed "SomeException \"oops\""

        it "trims trailing whitespace from the error message" do
            detectOutcome "*** Exception: Crashed  \n"
                `shouldBe` GhciCrashed "Crashed"

    describe "compile failure (no exception line, but GHC errors present)" do
        it "flags ':main not in scope' as crashed" do
            detectOutcome "<interactive>:1:1: error: [GHC-76037] Not in scope: 'main'\n"
                `shouldBe` GhciCrashed
                    "<interactive>:1:1: error: [GHC-76037] Not in scope: 'main'"

        it "flags a source-file compile error as crashed" do
            detectOutcome "src/Foo.hs:42:5: error: Variable not in scope: foo\n"
                `shouldBe` GhciCrashed "src/Foo.hs:42:5: error: Variable not in scope: foo"

        it "reports the first error line when multiple are present" do
            detectOutcome
                "src/Foo.hs:42:5: error: Variable not in scope: foo\nsrc/Bar.hs:10:1: error: Parse error\n"
                `shouldBe` GhciCrashed "src/Foo.hs:42:5: error: Variable not in scope: foo"

        it "prefers exit exception over compile-error heuristic when both appear" do
            -- A real failing run could plausibly mention 'error:' in its
            -- captured output (e.g. logged messages); the ExitFailure line
            -- still wins.
            detectOutcome "log: error: something happened\n*** Exception: ExitFailure 1\n"
                `shouldBe` GhciFailed


--------------------------------------------------------------------------------
-- Scripted interpreter tests
--------------------------------------------------------------------------------

testScripted :: Spec
testScripted = do
    it "returns BatchCompleted when all outcomes are TestCompleted" do
        (status, observed) <-
            runBatch
                [TestCompleted passingRun, TestCompleted failingRun]
                ["test:foo", "test:bar"]
        status `shouldBe` BatchCompleted
        observed
            `shouldBe` [ ("test:foo", TestCompleted passingRun)
                       , ("test:bar", TestCompleted failingRun)
                       ]

    it "stops the loop and returns BatchAborted on TestAborted" do
        (status, observed) <-
            runBatch
                [TestCompleted passingRun, TestAborted, TestCompleted failingRun]
                ["test:foo", "test:bar", "test:baz"]
        status `shouldBe` BatchAborted
        observed
            `shouldBe` [ ("test:foo", TestCompleted passingRun)
                       , ("test:bar", TestAborted)
                       ]

    it "delivers TestAborted to the callback before stopping" do
        (_, observed) <- runBatch [TestAborted] ["test:foo"]
        observed `shouldBe` [("test:foo", TestAborted)]

    it "returns BatchCompleted (vacuously) for an empty target list" do
        (status, observed) <- runBatch [] []
        status `shouldBe` BatchCompleted
        observed `shouldBe` []
  where
    -- Run withBatch with a script and target list, recording every
    -- (target, outcome) pair the callback sees.
    runBatch script targets = do
        ref <- newIORef []
        status <- runScripted script $ withBatch targets \target outcome ->
            liftIO $ modifyIORef' ref ((target, outcome) :)
        observed <- reverse <$> readIORef ref
        pure (status, observed)


--------------------------------------------------------------------------------
-- Helpers
--------------------------------------------------------------------------------

passingRun :: TestRun
passingRun =
    TestRunCompleted
        $ TestRunCompletion
            { target = "test:foo"
            , passed = True
            , output = "2 examples, 0 failures\n"
            , testCases = []
            , duration = Nothing
            }


failingRun :: TestRun
failingRun =
    TestRunCompleted
        $ TestRunCompletion
            { target = "test:bar"
            , passed = False
            , output = "1 example, 1 failure\n"
            , testCases = []
            , duration = Nothing
            }


runScripted :: [TestRunOutcome] -> Eff '[TestRunner, IOE] a -> IO a
runScripted outcomes = runEff . runTestRunnerScripted outcomes
