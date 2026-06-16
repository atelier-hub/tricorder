module Unit.Tricorder.GhcPkgSpec (spec_GhcPkg) where

import Effectful (runPureEff)
import Test.Hspec

import Tricorder.Effects.GhcPkg (GhcPkg, GhcPkgScript (..), findModule, getHaddockHtml, runGhcPkgScripted)


spec_GhcPkg :: Spec
spec_GhcPkg = do
    describe "findModule" testFindModule
    describe "getHaddockHtml" testGetHaddockHtml


testFindModule :: Spec
testFindModule = do
    it "returns Just pkgId when module is known" do
        let result = runScripted [NextFindModule (Just "base-4.18")] $ findModule "Prelude"
        result `shouldBe` Just "base-4.18"

    it "returns Nothing for an unknown module" do
        let result = runScripted [NextFindModule Nothing] $ findModule "No.Such.Module"
        result `shouldBe` Nothing

    it "returns the first scripted result" do
        let result = runScripted [NextFindModule (Just "pkg-1.0"), NextFindModule (Just "pkg-2.0")] $ findModule "Foo"
        result `shouldBe` Just "pkg-1.0"


testGetHaddockHtml :: Spec
testGetHaddockHtml = do
    it "returns Just path when haddock-html is set" do
        let result = runScripted [NextGetHaddockHtml (Just "/nix/store/abc/share/doc/html")] $ getHaddockHtml "base-4.18"
        result `shouldBe` Just "/nix/store/abc/share/doc/html"

    it "returns Nothing when haddock-html is not set" do
        let result = runScripted [NextGetHaddockHtml Nothing] $ getHaddockHtml "base-4.18"
        result `shouldBe` Nothing

    it "returns the first scripted result" do
        let result =
                runScripted
                    [NextGetHaddockHtml (Just "/path/one"), NextGetHaddockHtml (Just "/path/two")]
                    $ getHaddockHtml "pkg-1.0"
        result `shouldBe` Just "/path/one"


runScripted :: [GhcPkgScript] -> Eff '[GhcPkg] a -> a
runScripted script = runPureEff . runGhcPkgScripted script
