module Unit.Atelier.Effects.DelaySpec (spec_Delay) where

import Effectful (runEff)
import Effectful.Concurrent (runConcurrent)
import Effectful.Prim (runPrim)
import Effectful.Prim.IORef (atomicModifyIORef, newIORef, readIORef)
import Effectful.State.Static.Shared (evalState, execState, gets)
import Test.Hspec

import Effectful.Concurrent.Async qualified as Async
import Effectful.Prim.IORef qualified as IORef

import Atelier.Effects.Delay (mkTimers, runDelayWithControls)
import Atelier.Time (Microsecond)

import Atelier.Effects.Conc qualified as Conc
import Atelier.Effects.Delay qualified as Delay


spec_Delay :: Spec
spec_Delay = do
    describe "runDelayWithControls" testRunDelayWithControls
    describe "withTimeout" testWithTimeout


testRunDelayWithControls :: Spec
testRunDelayWithControls = do
    describe "with no calls to Wait or Every" do
        it "should return immediately with no timers" do
            timers <-
                runEff
                    . runConcurrent
                    . execState mkTimers
                    . runDelayWithControls
                    $ pure ()
            length timers `shouldBe` 0

    describe "with calls to Wait" do
        describe "without using tick" do
            it "should not release the wait" do
                runTest do
                    ref <- newRef
                    _ <- Conc.fork do
                        incRef ref
                        Delay.wait (10 :: Microsecond)
                        incRef ref
                    Delay.settle
                    count <- IORef.readIORef ref
                    liftIO $ count `shouldBe` 1

        describe "when progressing time by less than the wait duration" do
            it "should not release the wait" do
                runTest do
                    ref <- newRef
                    _ <- Conc.fork do
                        incRef ref
                        Delay.wait (10 :: Microsecond)
                        incRef ref
                    Delay.tick (9 :: Microsecond)
                    count <- readIORef ref
                    liftIO $ count `shouldBe` 1

        describe "when progressing time by more than the wait duration" do
            it "should release the wait" do
                runTest do
                    ref <- newRef
                    _ <- Conc.fork do
                        incRef ref
                        Delay.wait (10 :: Microsecond)
                        incRef ref
                    Delay.tick (20 :: Microsecond)
                    count <- readIORef ref
                    liftIO $ count `shouldBe` 2

        describe "when accumulating multiple ticks" do
            it "should release once combined time reaches the wait duration" do
                runTest do
                    ref <- newRef
                    _ <- Conc.fork do
                        incRef ref
                        Delay.wait (10 :: Microsecond)
                        incRef ref
                    Delay.tick (5 :: Microsecond)
                    c1 <- readIORef ref
                    liftIO $ c1 `shouldBe` 1
                    Delay.tick (5 :: Microsecond)
                    c2 <- readIORef ref
                    liftIO $ c2 `shouldBe` 2

        describe "with multiple concurrent Wait calls" do
            it "creates a timer for each" do
                runTest do
                    _ <- Conc.fork $ Delay.wait (10 :: Microsecond)
                    _ <- Conc.fork $ Delay.wait (20 :: Microsecond)
                    Delay.settle
                    tc <- gets length
                    liftIO $ tc `shouldBe` 2

            it "releases each wait independently" do
                runTest do
                    ref1 <- newRef
                    ref2 <- newRef
                    _ <- Conc.fork do
                        Delay.wait (10 :: Microsecond)
                        incRef ref1
                    _ <- Conc.fork do
                        Delay.wait (20 :: Microsecond)
                        incRef ref2
                    Delay.tick (10 :: Microsecond)
                    c1 <- readIORef ref1
                    c2 <- readIORef ref2
                    liftIO $ c1 `shouldBe` 1
                    liftIO $ c2 `shouldBe` 0
                    Delay.tick (10 :: Microsecond)
                    c1' <- readIORef ref1
                    c2' <- readIORef ref2
                    liftIO $ c1' `shouldBe` 1
                    liftIO $ c2' `shouldBe` 1

    describe "with tickNext" do
        describe "with no timers" do
            it "does nothing" do
                runTest do
                    Delay.tickNext
                    tc <- gets length
                    liftIO $ tc `shouldBe` 0

        describe "with a single Wait timer" do
            it "advances time to the timer and releases it" do
                runTest do
                    ref <- newRef
                    _ <- Conc.fork do
                        Delay.wait (100 :: Microsecond)
                        incRef ref
                    Delay.tickNext
                    count <- readIORef ref
                    liftIO $ count `shouldBe` 1

        describe "with multiple timers" do
            it "fires the earliest timer first" do
                runTest do
                    ref1 <- newRef
                    ref2 <- newRef
                    _ <- Conc.fork do
                        Delay.wait (20 :: Microsecond)
                        incRef ref1
                    _ <- Conc.fork do
                        Delay.wait (10 :: Microsecond)
                        incRef ref2
                    Delay.tickNext
                    c1 <- readIORef ref1
                    c2 <- readIORef ref2
                    liftIO $ c1 `shouldBe` 0
                    liftIO $ c2 `shouldBe` 1

    describe "with calls to Every" do
        describe "without using tick" do
            it "runs the action once then waits" do
                runTest do
                    ref <- newRef
                    _ <-
                        Conc.fork
                            $ Delay.every (10 :: Microsecond)
                            $ incRef ref
                    Delay.settle
                    count <- readIORef ref
                    liftIO $ count `shouldBe` 1

        describe "when ticking once" do
            it "runs the action twice" do
                runTest do
                    ref <- newRef
                    _ <-
                        Conc.fork
                            $ Delay.every (10 :: Microsecond)
                            $ incRef ref
                    Delay.tick (10 :: Microsecond)
                    count <- readIORef ref
                    liftIO $ count `shouldBe` 2

        describe "when ticking multiple times" do
            it "runs the action once per tick plus the initial run" do
                runTest do
                    ref <- newRef
                    _ <-
                        Conc.fork
                            $ Delay.every (10 :: Microsecond)
                            $ incRef ref
                    Delay.tick (10 :: Microsecond)
                    Delay.tick (10 :: Microsecond)
                    Delay.tick (10 :: Microsecond)
                    count <- readIORef ref
                    liftIO $ count `shouldBe` 4

        describe "timer lifetime" do
            it "re-registers the Interval timer after each fire" do
                runTest do
                    _ <-
                        Conc.fork
                            $ Delay.every (10 :: Microsecond)
                            $ pure ()
                    Delay.settle
                    tc1 <- gets length
                    liftIO $ tc1 `shouldBe` 1
                    Delay.tick (10 :: Microsecond)
                    tc2 <- gets length
                    liftIO $ tc2 `shouldBe` 1
  where
    runTest = runEff . runPrim . runConcurrent . Conc.runConc . evalState mkTimers . runDelayWithControls
    newRef = newIORef (0 :: Int)
    incRef ref = atomicModifyIORef ref $ (,()) . (+ 1)


testWithTimeout :: Spec
testWithTimeout = do
    it "instant action returns Right" do
        result <- runTest $ Delay.withTimeout (100 :: Microsecond) (pure ())
        result `shouldBe` Right ()

    it "action finishes before deadline returns Right" do
        result <- runTest do
            a <- Async.async $ Delay.withTimeout (100 :: Microsecond) (Delay.wait (10 :: Microsecond))
            Delay.tickNext
            Async.wait a
        result `shouldBe` Right ()

    it "deadline fires before action returns Left" do
        result <- runTest do
            a <- Async.async $ Delay.withTimeout (10 :: Microsecond) (Delay.wait (100 :: Microsecond))
            Delay.tickNext
            Async.wait a
        result `shouldBe` Left ()
  where
    runTest = runEff . runPrim . runConcurrent . Conc.runConc . evalState mkTimers . runDelayWithControls
