module Unit.Atelier.Effects.DebounceSpec (spec_Debounce) where

import Data.Dynamic (fromDynamic, toDyn)
import Data.Maybe (fromJust)
import Effectful (runEff)
import Effectful.Concurrent (runConcurrent)
import Effectful.Concurrent.MVar (Concurrent, MVar, newEmptyMVar, putMVar)
import Effectful.Concurrent.STM (atomically)
import Test.Hspec

import Data.IORef qualified as IORef
import Effectful.Concurrent.MVar qualified as MVar
import StmContainers.Map qualified as Map

import Atelier.Effects.Conc (runConc)
import Atelier.Effects.Debounce
    ( Entry (..)
    , debounced
    , debouncedWith
    , ensureCallback
    , ensureEntry
    , runDebounce
    , runDebounceWithMap
    )
import Atelier.Effects.Delay (runDelay)
import Atelier.Effects.Timeout (runTimeout, runTimeoutAlwaysTimesOut, runTimeoutMVar)
import Atelier.Time (Millisecond)

import Atelier.Effects.Conc qualified as Conc
import Atelier.Effects.Console qualified as Console
import Atelier.Effects.Delay qualified as Delay
import Atelier.Types.Semaphore qualified as Sem


spec_Debounce :: Spec
spec_Debounce = do
    describe "runDebounce" testRunDebounce
    describe "ensureEntry" testEnsureEntry
    describe "ensureCallback" testEnsureCallback


testEnsureEntry :: Spec
testEnsureEntry = do
    describe "new key" do
        it "gets generation 0" $ runTest do
            state <- atomically Map.new
            entry <- atomically $ mkEntry 1 42 state (+)
            liftIO $ entry.generation `shouldBe` 0

        it "stores value as arg" $ runTest do
            state <- atomically Map.new
            entry <- atomically $ mkEntry 1 42 state (+)
            liftIO $ (entry.arg >>= fromDynamic) `shouldBe` Just @Int 42

        it "starts with empty waiting TMVar" $ runTest do
            state <- atomically Map.new
            entry <- atomically $ mkEntry 1 42 state (+)
            result <- Sem.peek entry.cancelled
            liftIO $ result `shouldBe` False

    describe "existing key" do
        it "increments generation" $ runTest do
            state <- atomically Map.new
            _ <- atomically $ mkEntry 1 2 state (+)
            entry <- atomically $ mkEntry 1 3 state (+)
            liftIO $ entry.generation `shouldBe` 1

        it "applies merge function to old and new value" $ runTest do
            state <- atomically Map.new
            _ <- atomically $ mkEntry 1 5 state (+)
            entry <- atomically $ mkEntry 1 10 state (+)
            liftIO $ (entry.arg >>= fromDynamic) `shouldBe` Just @Int 15

        it "signals old waiting TMVar" $ runTest do
            state <- atomically Map.new
            entry1 <- atomically $ mkEntry 1 42 state (+)
            _ <- atomically $ mkEntry 1 99 state (+)
            result <- Sem.peek entry1.cancelled
            liftIO $ result `shouldBe` True

        it "new waiting TMVar is empty" $ runTest do
            state <- atomically Map.new
            _ <- atomically $ mkEntry 1 42 state (+)
            entry2 <- atomically $ mkEntry 1 99 state (+)
            result <- Sem.peek entry2.cancelled
            liftIO $ result `shouldBe` False

    describe "multiple updates" do
        it "accumulates generation" $ runTest do
            state <- atomically Map.new
            _ <- atomically $ mkEntry 1 1 state (+)
            _ <- atomically $ mkEntry 1 2 state (+)
            entry <- atomically $ mkEntry 1 3 state (+)
            liftIO $ entry.generation `shouldBe` 2

        it "applies merge cumulatively" $ runTest do
            state <- atomically Map.new
            _ <- atomically $ mkEntry 1 1 state (+)
            _ <- atomically $ mkEntry 1 2 state (+)
            entry <- atomically $ mkEntry 1 3 state (+)
            liftIO $ (entry.arg >>= fromDynamic) `shouldBe` Just @Int 6

    describe "independent keys" do
        it "do not interfere with each other" $ runTest do
            state <- atomically Map.new
            entryA <- atomically $ mkEntry 1 10 state (+)
            entryB <- atomically $ mkEntry 2 20 state (+)
            liftIO $ (entryA.arg >>= fromDynamic) `shouldBe` Just @Int 10
            liftIO $ (entryB.arg >>= fromDynamic) `shouldBe` Just @Int 20
            liftIO $ entryA.generation `shouldBe` 0
            liftIO $ entryB.generation `shouldBe` 0
  where
    mkEntry = ensureEntry @Int @Int
    runTest = runEff . runConcurrent


testEnsureCallback :: Spec
testEnsureCallback = do
    it "fires callback after settle delay" do
        actual <- runCallbackTest do
            cancelled <- Sem.new
            ref <- liftIO $ IORef.newIORef @Int 0
            t <- Conc.fork $ ensureCallback 1 (entry cancelled) $ liftIO . IORef.writeIORef ref
            Delay.wait @Millisecond 5
            Conc.await t
            liftIO $ IORef.readIORef ref
        actual `shouldBe` 10
    it "can be cancelled" do
        runCallbackTest do
            cancelled <- Sem.newSet
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
        describe "when invoked once" $ it "fires once" $ runTest do
            counter <- newMVar 0
            let inc = modifyMVar_ counter (pure . (+ 1))
            runDebounceSimple do
                debounced 50 () inc
                Delay.wait @Millisecond 1
            readMVar counter >>= liftIO . (`shouldBe` 1)

        describe "when invoked multiple times" $ it "fires once" $ runTest do
            counter <- newMVar 0
            let inc = modifyMVar_ counter (pure . (+ 1))
            state <- atomically Map.new
            var <- newEmptyMVar
            runTimeoutMVar var $ runDebounceWithMap state do
                debounced 50 () inc
                putMVar var True
                cancelEntry () state
                debounced 50 () inc
                putMVar var True
                cancelEntry () state
                debounced 50 () inc
                putMVar var False
                Delay.wait @Millisecond 1
            readMVar counter >>= liftIO . (`shouldBe` 1)

        describe "when invoked multiple times with a delay between" $ it "fires once per burst" $ runTest do
            counter <- newMVar 0
            let inc = modifyMVar_ counter (pure . (+ 1))
            state <- atomically Map.new
            var <- newEmptyMVar
            runTimeoutMVar var $ runDebounceWithMap state do
                debounced 50 () inc
                putMVar var True
                cancelEntry () state
                debounced 50 () inc
                putMVar var False
                Delay.wait @Millisecond 1
                debounced 50 () inc
                putMVar var True
                cancelEntry () state
                debounced 50 () inc
                putMVar var False
                Delay.wait @Millisecond 1
            readMVar counter >>= liftIO . (`shouldBe` 2)

        describe "when invoked many times" $ it "should not crash" $ runTest do
            counter <- newMVar 0
            let inc = modifyMVar_ counter (pure . (+ 1))
            var <- newEmptyMVar
            state <- atomically Map.new
            runTimeoutMVar var $ runDebounceWithMap state do
                replicateM_ 10_000 do
                    debounced 50 () inc
                    putMVar var True
                    cancelEntry () state
                debounced 50 () inc
                putMVar var False
                Delay.wait @Millisecond 1
            readMVar counter >>= liftIO . (`shouldBe` 1)

    describe "debouncedWith" do
        describe "when invoked once" $ it "fires callback with the provided arg" $ runTest do
            result <- MVar.newMVar (Nothing :: Maybe Int)
            var <- newEmptyMVar
            state <- atomically Map.new
            runTimeoutMVar var $ runDebounceWithMap state do
                debouncedWith 50 (+) () (42 :: Int) $ \v ->
                    MVar.modifyMVar_ result (\_ -> pure (Just v))
                putMVar var False
                Delay.wait @Millisecond 1
            MVar.readMVar result >>= liftIO . (`shouldBe` Just 42)

        describe "when invoked multiple times rapidly" do
            it "fires once" $ runTest do
                counter <- newMVar 0
                state <- atomically Map.new
                var <- newEmptyMVar
                runTimeoutMVar var $ runDebounceWithMap state do
                    debouncedWith 50 (+) () (1 :: Int) $ \_ ->
                        modifyMVar_ counter (pure . (+ 1))
                    putMVar var True
                    cancelEntry () state
                    debouncedWith 50 (+) () (2 :: Int) $ \_ ->
                        modifyMVar_ counter (pure . (+ 1))
                    putMVar var True
                    cancelEntry () state
                    debouncedWith 50 (+) () (3 :: Int) $ \_ ->
                        modifyMVar_ counter (pure . (+ 1))
                    putMVar var False
                    Delay.wait @Millisecond 1
                readMVar counter >>= liftIO . (`shouldBe` 1)

            it "fires callback with merged arg" $ runTest do
                result <- newMVar 0
                state <- atomically Map.new
                var <- newEmptyMVar
                runTimeoutMVar var $ runDebounceWithMap state do
                    debouncedWith 50 (+) () (1 :: Int) $ \v ->
                        modifyMVar_ result (\_ -> pure v)
                    putMVar var True
                    cancelEntry () state
                    debouncedWith 50 (+) () (2 :: Int) $ \v ->
                        modifyMVar_ result (\_ -> pure v)
                    putMVar var True
                    cancelEntry () state
                    debouncedWith 50 (+) () (3 :: Int) $ \v ->
                        modifyMVar_ result (\_ -> pure v)
                    putMVar var False
                    Delay.wait @Millisecond 1
                readMVar result >>= liftIO . (`shouldBe` 6)

        describe "when invoked multiple times with a delay between" $ it "fires once per burst with merged arg" $ runTest do
            ref <- liftIO $ IORef.newIORef @[Int] []
            state <- atomically Map.new
            var <- newEmptyMVar
            runTimeoutMVar var $ runDebounceWithMap state do
                debouncedWith 50 (+) () (1 :: Int) $ \v ->
                    liftIO $ IORef.modifyIORef ref (++ [v])
                -- Tell Timeout that the action should run
                putMVar var True
                entry1 <- fmap fromJust $ atomically $ Map.lookup () state
                -- Signal to 'ensureCallback' that it was cancelled
                Sem.signal entry1.cancelled
                Delay.wait @Millisecond 1

                debouncedWith 50 (+) () (2 :: Int) $ \v ->
                    liftIO $ IORef.modifyIORef ref (++ [v])
                -- Tell Timeout to time out, which means the debounce settled
                putMVar var False
                Delay.wait @Millisecond 1

                debouncedWith 50 (+) () (10 :: Int) $ \v ->
                    liftIO $ IORef.modifyIORef ref (++ [v])
                -- Tell Timeout that the action should run
                putMVar var True
                entry2 <- fmap fromJust $ atomically $ Map.lookup () state
                -- Signal to 'ensureCallback' that it was cancelled
                Sem.signal entry2.cancelled
                Delay.wait @Millisecond 1
                debouncedWith 50 (+) () (20 :: Int) $ \v ->
                    liftIO $ IORef.modifyIORef ref (++ [v])
                -- Tell Timeout to time out, which means the debounce settled
                putMVar var False
                Delay.wait @Millisecond 1
            liftIO $ IORef.readIORef ref >>= (`shouldBe` [3, 30])
  where
    runTest =
        runEff
            . runConcurrent
            . runConc
            . runDelay
    runDebounceSimple = runTimeoutAlwaysTimesOut . runDebounce
    cancelEntry key state =
        atomically (Map.lookup key state) >>= Sem.signal . (.cancelled) . fromJust


newMVar :: (Concurrent :> es) => Int -> Eff es (MVar Int)
newMVar = MVar.newMVar


modifyMVar_ :: (Concurrent :> es) => MVar Int -> (Int -> Eff es Int) -> Eff es ()
modifyMVar_ = MVar.modifyMVar_


readMVar :: (Concurrent :> es) => MVar Int -> Eff es Int
readMVar = MVar.readMVar
