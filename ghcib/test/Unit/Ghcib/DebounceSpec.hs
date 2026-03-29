module Unit.Ghcib.DebounceSpec (spec_Debounce) where

import Control.Concurrent (threadDelay)
import Control.Concurrent.MVar (modifyMVar_, newMVar, readMVar)
import Effectful (runEff)
import Effectful.Concurrent (runConcurrent)
import Effectful.Timeout (runTimeout)
import Test.Hspec

import Atelier.Effects.Chan (runChan)
import Atelier.Effects.Conc (runConc)
import Atelier.Time (Millisecond)
import Ghcib.Debounce (debounced)

import Atelier.Effects.Chan qualified as Chan
import Atelier.Effects.Conc qualified as Conc


spec_Debounce :: Spec
spec_Debounce = do
    describe "debounced" testDebounced


testDebounced :: Spec
testDebounced = do
    it "does not emit before any triggers arrive" do
        counter <- newMVar (0 :: Int)
        runEff
            . runConcurrent
            . runChan
            . runConc
            . runTimeout
            $ do
                (_trigIn, trigOut) <- Chan.newChan
                debouncedOut <- debounced (50 :: Millisecond) trigOut
                Conc.fork_ $ forever $ do
                    Chan.readChan debouncedOut
                    liftIO $ modifyMVar_ counter (pure . (+ 1))
                liftIO $ threadDelay 150_000
        count <- readMVar counter
        count `shouldBe` 0

    it "emits once after a burst of triggers" do
        counter <- newMVar (0 :: Int)
        runEff
            . runConcurrent
            . runChan
            . runConc
            . runTimeout
            $ do
                (trigIn, trigOut) <- Chan.newChan
                -- 50ms settle time
                debouncedOut <- debounced (50 :: Millisecond) trigOut
                -- Write three rapid triggers
                Chan.writeChan trigIn ()
                Chan.writeChan trigIn ()
                Chan.writeChan trigIn ()
                -- Read from debounced channel in a fork
                Conc.fork_ $ forever $ do
                    Chan.readChan debouncedOut
                    liftIO $ modifyMVar_ counter (pure . (+ 1))
                -- Wait for settling
                liftIO $ threadDelay 200_000
        count <- readMVar counter
        count `shouldBe` 1

    it "emits once per burst for multiple separated bursts" do
        counter <- newMVar (0 :: Int)
        runEff
            . runConcurrent
            . runChan
            . runConc
            . runTimeout
            $ do
                (trigIn, trigOut) <- Chan.newChan
                debouncedOut <- debounced (50 :: Millisecond) trigOut
                Conc.fork_ $ forever $ do
                    Chan.readChan debouncedOut
                    liftIO $ modifyMVar_ counter (pure . (+ 1))
                -- First burst
                Chan.writeChan trigIn ()
                Chan.writeChan trigIn ()
                liftIO $ threadDelay 150_000
                -- Second burst
                Chan.writeChan trigIn ()
                Chan.writeChan trigIn ()
                liftIO $ threadDelay 150_000
        count <- readMVar counter
        count `shouldBe` 2
