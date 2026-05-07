module Tricorder.TestOutput (parseHspecOutput) where

import Data.Text qualified as T

import Tricorder.BuildState (TestCase (..), TestCaseOutcome (..))


-- | Parse hspec output into individual test case results.
--
-- Recognises lines ending with @OK@ or @FAIL@ (right-aligned, space-padded).
-- For failing tests, collects the indented detail lines that follow as the
-- failure message.
parseHspecOutput :: Text -> [TestCase]
parseHspecOutput = go . T.lines
  where
    go [] = []
    go (l : ls)
        | T.isSuffixOf "OK" (T.stripEnd l) =
            TestCase {description = extractDesc "OK" l, outcome = TestCasePassed}
                : go ls
        | T.isSuffixOf "FAIL" (T.stripEnd l) =
            let (detailLines, rest) = span (\dl -> indentOf dl > indentOf l) ls
                details = T.intercalate "\n" $ filter (not . T.null) $ map T.strip detailLines
            in  TestCase {description = extractDesc "FAIL" l, outcome = TestCaseFailed details}
                    : go rest
        | otherwise = go ls

    extractDesc suffix l =
        T.strip $ T.dropEnd (T.length suffix) $ T.stripEnd l

    indentOf = T.length . T.takeWhile (== ' ')
