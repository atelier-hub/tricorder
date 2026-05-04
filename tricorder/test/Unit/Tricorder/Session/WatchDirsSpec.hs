module Unit.Tricorder.Session.WatchDirsSpec (spec_WatchDirs) where

import Test.Hspec (Spec, describe, it, shouldBe)

import Tricorder.Session.WatchDirs (sourceDirsForTarget)
import Unit.Tricorder.Cabal (gpd)


spec_WatchDirs :: Spec
spec_WatchDirs = do
    describe "sourceDirsForTarget" do
        describe "lib:" do
            it "returns main library source dirs" do
                sourceDirsForTarget gpd "lib:" `shouldBe` ["src"]

        describe "lib:<package-name>" do
            it "returns main library source dirs when name matches package name" do
                sourceDirsForTarget gpd "lib:myapp" `shouldBe` ["src"]

        describe "lib:<sub-library>" do
            it "returns sub-library source dirs" do
                sourceDirsForTarget gpd "lib:myapp-utils" `shouldBe` ["utils"]

            it "returns empty list for unknown sub-library" do
                sourceDirsForTarget gpd "lib:nonexistent" `shouldBe` []

        describe "exe:<name>" do
            it "returns executable source dirs" do
                sourceDirsForTarget gpd "exe:myapp-exe" `shouldBe` ["app"]

        describe "test:<name>" do
            it "returns test suite source dirs" do
                sourceDirsForTarget gpd "test:myapp-test" `shouldBe` ["test"]

        describe "unknown target" do
            it "returns empty list" do
                sourceDirsForTarget gpd "unknown" `shouldBe` []
