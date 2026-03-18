module Unit.Atelier.Effects.PublishingSpec (spec_Pub) where

import Effectful (runPureEff)
import Effectful.Writer.Static.Shared (runWriter)
import Test.Hspec (Spec, context, describe, expectationFailure, it, shouldBe)

import Atelier.Effects.Publishing (publish, runPubWriter)


data TestEvent = TestEvent Text
    deriving stock (Show)


spec_Pub :: Spec
spec_Pub = do
    describe "Writer implementation" $ do
        context "no events published" do
            it "doesn't record events" $ do
                let ((), events) = runPureEff . runWriter . runPubWriter @TestEvent $ do
                        pure ()

                length events `shouldBe` 0

        context "events published" do
            it "records events" $ do
                let ((), events) = runPureEff . runWriter . runPubWriter @TestEvent $ do
                        publish $ TestEvent "payload"
                        pure ()

                length events `shouldBe` 1
                case events of
                    [TestEvent payload] ->
                        payload `shouldBe` "payload"
                    xs ->
                        expectationFailure $ "Expected 1 TestEvent event, got: " <> show (length xs)
