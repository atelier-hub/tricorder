module Unit.Atelier.Effects.PublishingSpec (spec_Pub) where

import Control.Concurrent.MVar (newEmptyMVar, putMVar, takeMVar)
import Data.Time (UTCTime, getCurrentTime)
import Effectful (IOE, runEff, runPureEff)
import Effectful.Concurrent (Concurrent, runConcurrent)
import Effectful.Writer.Static.Shared (runWriter)
import Test.Hspec (Spec, context, describe, expectationFailure, it, shouldBe)

import Atelier.Effects.Chan (Chan, runChan)
import Atelier.Effects.Clock (Clock, runClock, runClockConst)
import Atelier.Effects.Conc (Conc, runConc)
import Atelier.Effects.Monitoring.Tracing (Tracing, runTracingNoOp)
import Atelier.Effects.Publishing (Pub, Sub, forkListener, forkListener_, publish, runPubSub, runPubWriter)


data TestEvent = TestEvent Text
    deriving stock (Eq, Show)


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

    describe "PubSub implementation" do
        it "listener receives a published event" do
            result <- runPubSubTest $ do
                received <- liftIO newEmptyMVar
                forkListener_ @TestEvent \event ->
                    liftIO $ putMVar received event
                publish (TestEvent "hello")
                liftIO $ takeMVar received
            result `shouldBe` TestEvent "hello"

        it "event timestamp matches Clock at publish time" do
            t0 <- getCurrentTime
            result <- runPubSubTestWithClock t0 $ do
                received <- liftIO newEmptyMVar
                forkListener @TestEvent \ts _event ->
                    liftIO $ putMVar received ts
                publish (TestEvent "hello")
                liftIO $ takeMVar received
            result `shouldBe` t0

        it "multiple listeners each receive the published event" do
            result <- runPubSubTest $ do
                recv1 <- liftIO newEmptyMVar
                recv2 <- liftIO newEmptyMVar
                forkListener_ @TestEvent \event -> liftIO $ putMVar recv1 event
                forkListener_ @TestEvent \event -> liftIO $ putMVar recv2 event
                publish (TestEvent "hello")
                e1 <- liftIO $ takeMVar recv1
                e2 <- liftIO $ takeMVar recv2
                pure (e1, e2)
            result `shouldBe` (TestEvent "hello", TestEvent "hello")


--------------------------------------------------------------------------------
-- Test Helpers
--------------------------------------------------------------------------------

runPubSubTest
    :: Eff '[Pub TestEvent, Sub TestEvent, Chan, Clock, Tracing, Conc, Concurrent, IOE] a
    -> IO a
runPubSubTest =
    runEff
        . runConcurrent
        . runConc
        . runTracingNoOp
        . runClock
        . runChan
        . runPubSub @TestEvent


runPubSubTestWithClock
    :: UTCTime
    -> Eff '[Pub TestEvent, Sub TestEvent, Chan, Clock, Tracing, Conc, Concurrent, IOE] a
    -> IO a
runPubSubTestWithClock t =
    runEff
        . runConcurrent
        . runConc
        . runTracingNoOp
        . runClockConst t
        . runChan
        . runPubSub @TestEvent
