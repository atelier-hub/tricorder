module Unit.Tricorder.Session.TargetsSpec (spec_Targets) where

import Test.Hspec (Spec, describe, it, shouldBe, shouldContain)

import Tricorder.Session.Targets (allComponentTargets)
import Unit.Tricorder.Cabal (gpd)


spec_Targets :: Spec
spec_Targets = do
    describe "allComponentTargets" do
        it "includes the main library as lib:<package-name>" do
            allComponentTargets gpd `shouldContain` ["lib:myapp"]

        it "includes sub-libraries" do
            allComponentTargets gpd `shouldContain` ["lib:myapp-utils"]

        it "includes executables" do
            allComponentTargets gpd `shouldContain` ["exe:myapp-exe"]

        it "includes test suites" do
            allComponentTargets gpd `shouldContain` ["test:myapp-test"]

        it "returns all four components for the fixture" do
            allComponentTargets gpd
                `shouldBe` ["lib:myapp", "lib:myapp-utils", "exe:myapp-exe", "test:myapp-test"]
