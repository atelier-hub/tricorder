module Unit.Tricorder.TestOutputSpec (spec_TestOutput) where

import Test.Hspec

import Tricorder.BuildState (TestCase (..), TestCaseOutcome (..))
import Tricorder.TestOutput (parseHspecOutput)


spec_TestOutput :: Spec
spec_TestOutput = do
    describe "parseHspecOutput" do
        it "returns empty list for empty output" do
            parseHspecOutput "" `shouldBe` []

        it "parses a passing test" do
            let output = "  foo\n    bar baz:                                      OK\n"
            parseHspecOutput output
                `shouldBe` [TestCase {description = "bar baz:", outcome = TestCasePassed}]

        it "parses a failing test" do
            let output = "  foo\n    bar baz:                                      FAIL\n"
            parseHspecOutput output
                `shouldBe` [TestCase {description = "bar baz:", outcome = TestCaseFailed ""}]

        it "captures failure details" do
            let output =
                    "    a test:                                            FAIL\n"
                        <> "      expected: 1\n"
                        <> "       but got: 2\n"
                        <> "    another test:                                       OK\n"
            parseHspecOutput output
                `shouldBe` [ TestCase
                                { description = "a test:"
                                , outcome = TestCaseFailed "expected: 1\nbut got: 2"
                                }
                           , TestCase {description = "another test:", outcome = TestCasePassed}
                           ]

        it "stops collecting details when indentation returns to test level" do
            let output =
                    "    failing:                                           FAIL\n"
                        <> "      detail line\n"
                        <> "    passing:                                          OK\n"
            let cases = parseHspecOutput output
            length cases `shouldBe` 2
            case cases of
                (c : _) -> c.outcome `shouldBe` TestCaseFailed "detail line"
                [] -> expectationFailure "expected at least one test case"

        it "skips group header lines" do
            let output =
                    "  MyModule\n"
                        <> "    someFunction\n"
                        <> "      does the thing:                                  OK\n"
            parseHspecOutput output
                `shouldBe` [TestCase {description = "does the thing:", outcome = TestCasePassed}]

        it "parses mixed passing and failing tests" do
            let output =
                    "  Suite\n"
                        <> "    passes:                                            OK\n"
                        <> "    fails:                                             FAIL\n"
                        <> "      reason\n"
                        <> "    also passes:                                       OK\n"
            parseHspecOutput output
                `shouldBe` [ TestCase {description = "passes:", outcome = TestCasePassed}
                           , TestCase {description = "fails:", outcome = TestCaseFailed "reason"}
                           , TestCase {description = "also passes:", outcome = TestCasePassed}
                           ]
