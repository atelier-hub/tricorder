module Unit.Atelier.Effects.DebounceSpec (spec_Debounce) where

import Control.Concurrent.MVar (modifyMVar_, newMVar, readMVar)
import Data.Dynamic (fromDynamic, toDyn)
import Effectful (runEff)
import Effectful.Concurrent (runConcurrent)
import Effectful.Concurrent.STM (atomically)
import Test.Hspec

import Data.IORef qualified as IORef
import Effectful.Concurrent.STM qualified as STM
import StmContainers.Map qualified as Map

import Atelier.Effects.Conc (runConc)
import Atelier.Effects.Debounce
    ( Entry (..)
    , debounced
    , debouncedWith
    , ensureCallback
    , ensureEntry
    , runDebounce
    )
import Atelier.Effects.Delay (runDelay)
import Atelier.Effects.Timeout (runTimeout)
import Atelier.Time (Millisecond)

import Atelier.Effects.Conc qualified as Conc
import Atelier.Effects.Console qualified as Console
import Atelier.Effects.Delay qualified as Delay
import Atelier.Types.Semaphore.STM qualified as Sem


spec_Debounce :: Spec
spec_Debounce = do
    describe "runDebounce" testRunDebounce
    describe "ensureEntry" testEnsureEntry
    describe "ensureCallback" testEnsureCallback


testEnsureEntry :: Spec
testEnsureEntry = do
    describe "new key" do
        it "gets generation 0" do
            state <- runSTM Map.new
            entry <- runSTM $ mkEntry 1 42 state (+)
            entry.generation `shouldBe` 0

        it "stores value as arg" do
            state <- runSTM Map.new
            entry <- runSTM $ mkEntry 1 42 state (+)
            (entry.arg >>= fromDynamic) `shouldBe` Just @Int 42

        it "starts with empty waiting TMVar" do
            state <- runSTM Map.new
            entry <- runSTM $ mkEntry 1 42 state (+)
            result <- runSTM $ Sem.peek entry.cancelled
            result `shouldBe` False

    describe "existing key" do
        it "increments generation" do
            state <- runSTM Map.new
            _ <- runSTM $ mkEntry 1 2 state (+)
            entry <- runSTM $ mkEntry 1 3 state (+)
            entry.generation `shouldBe` 1

        it "applies merge function to old and new value" do
            state <- runSTM Map.new
            _ <- runSTM $ mkEntry 1 5 state (+)
            entry <- runSTM $ mkEntry 1 10 state (+)
            (entry.arg >>= fromDynamic) `shouldBe` Just @Int 15

        it "signals old waiting TMVar" do
            state <- runSTM Map.new
            entry1 <- runSTM $ mkEntry 1 42 state (+)
            _ <- runSTM $ mkEntry 1 99 state (+)
            result <- runSTM $ Sem.peek entry1.cancelled
            result `shouldBe` True

        it "new waiting TMVar is empty" do
            state <- runSTM Map.new
            _ <- runSTM $ mkEntry 1 42 state (+)
            entry2 <- runSTM $ mkEntry 1 99 state (+)
            result <- runSTM $ Sem.peek entry2.cancelled
            result `shouldBe` False

    describe "multiple updates" do
        it "accumulates generation" do
            state <- runSTM Map.new
            _ <- runSTM $ mkEntry 1 1 state (+)
            _ <- runSTM $ mkEntry 1 2 state (+)
            entry <- runSTM $ mkEntry 1 3 state (+)
            entry.generation `shouldBe` 2

        it "applies merge cumulatively" do
            state <- runSTM Map.new
            _ <- runSTM $ mkEntry 1 1 state (+)
            _ <- runSTM $ mkEntry 1 2 state (+)
            entry <- runSTM $ mkEntry 1 3 state (+)
            (entry.arg >>= fromDynamic) `shouldBe` Just @Int 6

    describe "independent keys" do
        it "do not interfere with each other" do
            state <- runSTM Map.new
            entryA <- runSTM $ mkEntry 1 10 state (+)
            entryB <- runSTM $ mkEntry 2 20 state (+)
            (entryA.arg >>= fromDynamic) `shouldBe` Just @Int 10
            (entryB.arg >>= fromDynamic) `shouldBe` Just @Int 20
            entryA.generation `shouldBe` 0
            entryB.generation `shouldBe` 0
  where
    mkEntry = ensureEntry @Int @Int
    runSTM action = runEff . runConcurrent $ STM.atomically action


testEnsureCallback :: Spec
testEnsureCallback = do
    it "fires callback after settle delay" do
        actual <- runCallbackTest do
            cancelled <- atomically Sem.new
            ref <- liftIO $ IORef.newIORef @Int 0
            t <- Conc.fork $ ensureCallback 1 (entry cancelled) $ liftIO . IORef.writeIORef ref
            Delay.wait @Millisecond 5
            Conc.await t
            liftIO $ IORef.readIORef ref
        actual `shouldBe` 10
    it "can be cancelled" do
        runCallbackTest do
            cancelled <- atomically Sem.newSet
            ensureCallback @Int 100 (entry cancelled) \_ ->
                liftIO $ False `shouldBe` True
            Delay.wait @Millisecond 150
  where
    runCallbackTest =
        runEff
            . runConcurrent
            . Console.runConsole
            . Delay.runDelay
            . runConc
            . runTimeout
    entry cancelled =
        Entry
            { generation = 0
            , cancelled
            , arg = Just $ toDyn @Int 10
            }


testRunDebounce :: Spec
testRunDebounce = do
    describe "debounced" do
        describe "when invoked once" $ it "fires once" do
            counter <- newMVar @Int 0
            let inc = liftIO $ modifyMVar_ counter (pure . (+ 1))
            runTest do
                debounced 50 () inc
                Delay.wait @Millisecond 100
            readMVar counter >>= (`shouldBe` 1)

        describe "when invoked multiple times" $ it "fires once" do
            counter <- newMVar @Int 0
            let inc = liftIO $ modifyMVar_ counter (pure . (+ 1))
            runTest do
                debounced 50 () inc
                debounced 50 () inc
                debounced 50 () inc
                Delay.wait @Millisecond 200
            readMVar counter >>= (`shouldBe` 1)

        describe "when invoked multiple times with a delay between" $ it "fires once per burst" do
            counter <- newMVar @Int 0
            let inc = liftIO $ modifyMVar_ counter (pure . (+ 1))
            runTest do
                debounced 50 () inc
                debounced 50 () inc
                Delay.wait @Millisecond 150
                debounced 50 () inc
                debounced 50 () inc
                Delay.wait @Millisecond 150
            readMVar counter >>= (`shouldBe` 2)

        describe "when invoked many times" $ it "should not crash" do
            counter <- newMVar @Int 0
            let inc = liftIO $ modifyMVar_ counter (pure . (+ 1))
            runTest do
                replicateM_ 10_000 $ debounced 50 () inc
                Delay.wait @Millisecond 500
            readMVar counter >>= (`shouldBe` 1)

    describe "debouncedWith" do
        describe "when invoked once" $ it "fires callback with the provided arg" do
            result <- newMVar @(Maybe Int) Nothing
            runTest do
                debouncedWith 50 (+) () (42 :: Int) $ \v ->
                    liftIO $ modifyMVar_ result (\_ -> pure (Just v))
                Delay.wait @Millisecond 100
            readMVar result >>= (`shouldBe` Just 42)

        describe "when invoked multiple times rapidly" do
            it "fires once" do
                counter <- newMVar @Int 0
                runTest do
                    debouncedWith 50 (+) () (1 :: Int) $ \_ ->
                        liftIO $ modifyMVar_ counter (pure . (+ 1))
                    debouncedWith 50 (+) () (2 :: Int) $ \_ ->
                        liftIO $ modifyMVar_ counter (pure . (+ 1))
                    debouncedWith 50 (+) () (3 :: Int) $ \_ ->
                        liftIO $ modifyMVar_ counter (pure . (+ 1))
                    Delay.wait @Millisecond 200
                readMVar counter >>= (`shouldBe` 1)

            it "fires callback with merged arg" do
                result <- newMVar @Int 0
                runTest do
                    debouncedWith 50 (+) () (1 :: Int) $ \v ->
                        liftIO $ modifyMVar_ result (\_ -> pure v)
                    debouncedWith 50 (+) () (2 :: Int) $ \v ->
                        liftIO $ modifyMVar_ result (\_ -> pure v)
                    debouncedWith 50 (+) () (3 :: Int) $ \v ->
                        liftIO $ modifyMVar_ result (\_ -> pure v)
                    Delay.wait @Millisecond 200
                readMVar result >>= (`shouldBe` 6)

        describe "when invoked multiple times with a delay between" $ it "fires once per burst with merged arg" do
            ref <- IORef.newIORef @[Int] []
            runTest do
                debouncedWith 50 (+) () (1 :: Int) $ \v ->
                    liftIO $ IORef.modifyIORef ref (++ [v])
                debouncedWith 50 (+) () (2 :: Int) $ \v ->
                    liftIO $ IORef.modifyIORef ref (++ [v])
                Delay.wait @Millisecond 150
                debouncedWith 50 (+) () (10 :: Int) $ \v ->
                    liftIO $ IORef.modifyIORef ref (++ [v])
                debouncedWith 50 (+) () (20 :: Int) $ \v ->
                    liftIO $ IORef.modifyIORef ref (++ [v])
                Delay.wait @Millisecond 150
            IORef.readIORef ref >>= (`shouldBe` [3, 30])
  where
    runTest =
        runEff
            . runConcurrent
            . runConc
            . runDelay
            . runTimeout
            . runDebounce
