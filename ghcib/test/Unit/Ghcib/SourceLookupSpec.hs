module Unit.Ghcib.SourceLookupSpec (spec_SourceLookup) where

import Effectful (IOE, runEff)
import Effectful.Concurrent (Concurrent, runConcurrent)
import Effectful.Dispatch.Dynamic (interpret_)
import Test.Hspec

import Data.Map.Strict qualified as Map

import Atelier.Effects.Cache (Cache, runCacheForever)
import Atelier.Effects.FileSystem (FileSystem (..))
import Atelier.Effects.Log (Log, runLogNoOp)
import Ghcib.Effects.GhcPkg (GhcPkg, GhcPkgScript (..), runGhcPkgScripted)
import Ghcib.GhcPkg.Types (ModuleName, PackageId)
import Ghcib.SourceLookup (ModuleSourceResult (..), lookupModuleSource)


spec_SourceLookup :: Spec
spec_SourceLookup = do
    describe "lookupModuleSource" testLookupModuleSource


testLookupModuleSource :: Spec
testLookupModuleSource = do
    it "returns SourceFound when module, haddock-html, and file are present" do
        result <-
            runTest
                [ NextFindModule (Just "pkg-1.0")
                , NextGetHaddockHtml (Just "/haddock/pkg")
                ]
                (Map.singleton "/haddock/pkg/src/Foo.html" sampleHtml)
                (lookupModuleSource "Foo")
        result `shouldBe` SourceFound "Foo" "module Foo where"

    it "returns SourceFound on second call without re-querying GhcPkg (cache hit)" do
        -- Only one NextFindModule and one NextGetHaddockHtml in the script.
        -- The second call must come entirely from cache (no script pop).
        (r1, r2) <- runTest
            [ NextFindModule (Just "pkg-1.0")
            , NextGetHaddockHtml (Just "/haddock/pkg")
            ]
            (Map.singleton "/haddock/pkg/src/Foo.html" sampleHtml)
            $ do
                r1 <- lookupModuleSource "Foo"
                r2 <- lookupModuleSource "Foo"
                pure (r1, r2)
        r1 `shouldBe` SourceFound "Foo" "module Foo where"
        r2 `shouldBe` SourceFound "Foo" "module Foo where"

    it "returns SourceNotFound when findModule returns Nothing" do
        result <-
            runTest
                [NextFindModule Nothing]
                Map.empty
                (lookupModuleSource "Unknown")
        result `shouldBe` SourceNotFound "Unknown"

    it "returns SourceNoHaddock when getHaddockHtml returns Nothing" do
        result <-
            runTest
                [ NextFindModule (Just "no-docs-1.0")
                , NextGetHaddockHtml Nothing
                ]
                Map.empty
                (lookupModuleSource "Foo")
        result `shouldBe` SourceNoHaddock "Foo" "no-docs-1.0"

    it "returns SourceNoHaddock when the html file does not exist" do
        result <-
            runTest
                [ NextFindModule (Just "pkg-1.0")
                , NextGetHaddockHtml (Just "/haddock/pkg")
                ]
                Map.empty
                (lookupModuleSource "Foo")
        result `shouldBe` SourceNoHaddock "Foo" "pkg-1.0"

    it "handles two different module names independently" do
        (r1, r2) <- runTest
            [ NextFindModule (Just "pkg-a-1.0")
            , NextGetHaddockHtml (Just "/haddock/pkg-a")
            , NextFindModule (Just "pkg-b-1.0")
            , NextGetHaddockHtml (Just "/haddock/pkg-b")
            ]
            ( Map.fromList
                [ ("/haddock/pkg-a/src/Foo.html", sampleHtml)
                , ("/haddock/pkg-b/src/Bar.html", barHtml)
                ]
            )
            $ do
                r1 <- lookupModuleSource "Foo"
                r2 <- lookupModuleSource "Bar"
                pure (r1, r2)
        r1 `shouldBe` SourceFound "Foo" "module Foo where"
        r2 `shouldBe` SourceFound "Bar" "module Bar where"


--------------------------------------------------------------------------------
-- Fixtures
--------------------------------------------------------------------------------

sampleHtml :: LByteString
sampleHtml = "<html><body><pre id=\"src\"><span>module</span> Foo <span>where</span></pre></body></html>"


barHtml :: LByteString
barHtml = "<html><body><pre id=\"src\"><span>module</span> Bar <span>where</span></pre></body></html>"


--------------------------------------------------------------------------------
-- Helpers
--------------------------------------------------------------------------------

runFileSystemScripted :: Map FilePath LByteString -> Eff (FileSystem : es) a -> Eff es a
runFileSystemScripted files = interpret_ \case
    DoesFileExist path -> pure $ Map.member path files
    ReadFileLbs path -> pure $ fromMaybe "" (Map.lookup path files)
    _ -> error "FileSystemScripted: unexpected operation"


runTest
    :: [GhcPkgScript]
    -> Map FilePath LByteString
    -> Eff '[Cache ModuleName PackageId, Cache (PackageId, ModuleName) Text, FileSystem, GhcPkg, Log, Concurrent, IOE] a
    -> IO a
runTest pkgScript files action =
    runEff
        . runConcurrent
        . runLogNoOp
        . runGhcPkgScripted pkgScript
        . runFileSystemScripted files
        . runCacheForever @(PackageId, ModuleName) @Text
        . runCacheForever @ModuleName @PackageId
        $ action
