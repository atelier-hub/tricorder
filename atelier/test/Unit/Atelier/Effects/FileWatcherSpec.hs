module Unit.Atelier.Effects.FileWatcherSpec (spec_FileWatcher) where

import Hedgehog (Gen, PropertyT, forAll, (===))
import Test.Hspec (Spec, describe, it, shouldBe)
import Test.Hspec.Hedgehog (hedgehog)

import Hedgehog.Gen qualified as Gen
import Hedgehog.Range qualified as Range

import Atelier.Effects.FileWatcher (deduplicateDirs)


spec_FileWatcher :: Spec
spec_FileWatcher = do
    describe "deduplicateDirs" do
        describe "properties" do
            it "result is an antichain: no element is an ancestor of another"
                $ hedgehog propAntichain
            it "result covers all inputs: every input has an ancestor-or-equal in the result"
                $ hedgehog propCoverage
            it "is idempotent"
                $ hedgehog propIdempotent
            it "result is a subset of the input"
                $ hedgehog propSubset

        describe "edge cases" do
            it "returns empty list unchanged" do
                deduplicateDirs [] `shouldBe` []

            it "does not treat a dir as an ancestor of a similarly named dir" do
                deduplicateDirs ["/src", "/srcover"] `shouldBe` ["/src", "/srcover"]


--------------------------------------------------------------------------------
-- Properties
--------------------------------------------------------------------------------

propAntichain :: PropertyT IO ()
propAntichain = do
    dirs <- forAll genDirs
    let result = deduplicateDirs dirs
    let pairs = [(a, b) | a <- result, b <- result, a /= b]
    all (\(a, b) -> not (isStrictAncestor a b)) pairs === True


propCoverage :: PropertyT IO ()
propCoverage = do
    dirs <- forAll genDirs
    let result = deduplicateDirs dirs
    all (isCoveredBy result) dirs === True


propIdempotent :: PropertyT IO ()
propIdempotent = do
    dirs <- forAll genDirs
    deduplicateDirs (deduplicateDirs dirs) === deduplicateDirs dirs


propSubset :: PropertyT IO ()
propSubset = do
    dirs <- forAll genDirs
    let result = deduplicateDirs dirs
    all (`elem` dirs) result === True


--------------------------------------------------------------------------------
-- Generators
--------------------------------------------------------------------------------

genDirs :: Gen [FilePath]
genDirs = Gen.list (Range.linear 0 10) genAbsDir


-- Generates absolute paths like /a/b/c using short segments to encourage
-- overlaps between generated paths.
genAbsDir :: Gen FilePath
genAbsDir = do
    segments <- Gen.list (Range.linear 1 4) genSegment
    pure $ "/" <> intercalate "/" segments


genSegment :: Gen String
genSegment = Gen.string (Range.linear 1 3) (Gen.element ['a', 'b', 'c', 'd'])


--------------------------------------------------------------------------------
-- Helpers (mirror of FileWatcher internals)
--------------------------------------------------------------------------------

isStrictAncestor :: FilePath -> FilePath -> Bool
isStrictAncestor parent child = (parent <> "/") `isPrefixOf` child


isCoveredBy :: [FilePath] -> FilePath -> Bool
isCoveredBy result d = any (\r -> r == d || isStrictAncestor r d) result
