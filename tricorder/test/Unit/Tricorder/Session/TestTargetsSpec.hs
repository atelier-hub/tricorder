module Unit.Tricorder.Session.TestTargetsSpec (spec_TestTargets) where

import Test.Hspec (Spec, describe, it, shouldBe)

import Tricorder.Session.Targets (Targets (..))
import Tricorder.Session.TestTargets (Config (..), TestTargets (..), resolveTestTargets)


spec_TestTargets :: Spec
spec_TestTargets = do
    describe "resolveTestTargets" testResolveTestTargets


testResolveTestTargets :: Spec
testResolveTestTargets = do
    describe "when testTargets is absent" $ it "infers test: components from targets" do
        let tgts = Targets ["lib:mylib", "test:mylib-test"]
            cfg = Config Nothing
        resolveTestTargets cfg tgts `shouldBe` TestTargets ["test:mylib-test"]

    it "returns empty list when no test: components in targets" do
        let tgts = Targets ["lib:mylib", "exe:myapp"]
            cfg = Config Nothing
        resolveTestTargets cfg tgts `shouldBe` TestTargets []

    it "uses explicit testTargets list when set" do
        let tgts = Targets ["lib:a", "test:a-test", "test:b-test"]
            cfg = Config $ Just ["test:b-test"]
        resolveTestTargets cfg tgts `shouldBe` TestTargets ["test:b-test"]

    it "returns empty list when testTargets is explicitly empty" do
        let tgts = Targets ["lib:a", "test:a-test"]
            cfg = Config $ Just []
        resolveTestTargets cfg tgts `shouldBe` TestTargets []

    it "infers multiple test: components" do
        let tgts = Targets ["lib:a", "test:a-test", "test:b-test"]
            cfg = Config Nothing
        resolveTestTargets cfg tgts `shouldBe` TestTargets ["test:a-test", "test:b-test"]
