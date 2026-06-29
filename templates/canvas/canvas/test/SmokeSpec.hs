module SmokeSpec (spec_Smoke) where

import Test.Hspec


spec_Smoke :: Spec
spec_Smoke =
    describe "canvas scaffold" do
        it "is wired up" do
            (1 + 1 :: Int) `shouldBe` 2
