module Tricorder.TestOutput (parseHspecOutput, parseHspecDuration, stripGhciNoise) where

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


-- | Extract the test suite duration from hspec summary output.
-- Matches non-indented summary lines ending with @"(Xs)"@,
-- e.g. @"All 160 tests passed (0.33s)"@ or @"1 out of 177 tests failed (0.06s)"@.
parseHspecDuration :: Text -> Maybe Int
parseHspecDuration output =
    listToMaybe $ mapMaybe extractMs (T.lines output)
  where
    extractMs line = do
        guard $ not (T.isPrefixOf " " line)
        guard $ T.isSuffixOf "s)" line
        let numStr = T.takeWhileEnd (/= '(') (T.dropEnd 2 line)
        secs <- readMaybe (T.unpack numStr) :: Maybe Double
        pure $ round (secs * 1000)


-- | Strip GHCi/cabal startup and shutdown noise from captured output lines.
stripGhciNoise :: [Text] -> [Text]
stripGhciNoise ls =
    case dropWhile (not . T.isPrefixOf "ghci> ") ls of
        [] -> ls
        _ : afterPrompt -> reverse $ dropWhile isGhciNoiseLine $ reverse afterPrompt


isGhciNoiseLine :: Text -> Bool
isGhciNoiseLine l =
    T.isPrefixOf "ghci>" l
        || l == "Leaving GHCi."
        || T.isPrefixOf "*** Exception: " l
