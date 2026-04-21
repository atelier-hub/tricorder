module Unit.Atelier.Effects.DebounceSpec (spec_Debounce) where

import Control.Concurrent (threadDelay)
import Control.Concurrent.MVar (modifyMVar_, newMVar, readMVar)
import Effectful (IOE, runEff)
import Effectful.Concurrent (Concurrent, runConcurrent)
import Test.Hspec

import Atelier.Effects.Conc (Conc, runConc)
import Atelier.Effects.Debounce (Debounce, debounced, runDebounce)
import Atelier.Effects.Delay (Delay, runDelay)


spec_Debounce :: Spec
spec_Debounce = describe "runDebounce" do
    it "does not fire before any events arrive" do
        counter <- newMVar (0 :: Int)
        runTest $ liftIO $ threadDelay 150_000
        readMVar counter >>= (`shouldBe` 0)

    it "fires once after a burst" do
        counter <- newMVar (0 :: Int)
        let inc = liftIO $ modifyMVar_ counter (pure . (+ 1))
        runTest do
            debounced 50 () inc
            debounced 50 () inc
            debounced 50 () inc
            liftIO $ threadDelay 200_000
        readMVar counter >>= (`shouldBe` 1)

    it "fires once per burst for multiple separated bursts" do
        counter <- newMVar (0 :: Int)
        let inc = liftIO $ modifyMVar_ counter (pure . (+ 1))
        runTest do
            debounced 50 () inc
            debounced 50 () inc
            liftIO $ threadDelay 150_000
            debounced 50 () inc
            debounced 50 () inc
            liftIO $ threadDelay 150_000
        readMVar counter >>= (`shouldBe` 2)


runTest :: Eff '[Debounce (), Delay, Conc, Concurrent, IOE] () -> IO ()
runTest = runEff . runConcurrent . runConc . runDelay . runDebounce
