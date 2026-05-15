module Unit.Atelier.Effects.Cache.SingleflightSpec (spec_Singleflight) where

import Control.Concurrent (threadDelay)
import Effectful (IOE, Limit (..), Persistence (..), UnliftStrategy (..), runEff, withEffToIO)
import Effectful.Concurrent (Concurrent, runConcurrent)
import Effectful.Exception (catch, throwIO)
import Effectful.State.Static.Shared (State, modify, runState)
import Test.Hspec (Spec, describe, it, shouldBe, shouldThrow)

import Control.Concurrent.Async qualified as Async

import Atelier.Effects.Cache.Singleflight (Singleflight, runSingleflight, updateCache, withCache)
import Atelier.Effects.Monitoring.Tracing (Tracing, runTracingNoOp)
import Atelier.Types.Semaphore (Semaphore)

import Atelier.Types.Semaphore qualified as Sem


-- | Test exception type
data TestException = TestException Text
    deriving stock (Eq, Show)
    deriving anyclass (Exception)


-- | Run a Singleflight test with execution counter
runSingleflightTest
    :: Eff [Singleflight Int Int, State Int, Tracing, Concurrent, IOE] a
    -> IO (a, Int)
runSingleflightTest action =
    runEff
        . runConcurrent
        . runTracingNoOp
        . runState @Int 0
        . runSingleflight @Int @Int
        $ action


runSem :: Eff '[Concurrent, IOE] a -> IO a
runSem = runEff . runConcurrent


-- | A computation that increments the execution counter and returns a value
compute :: (State Int :> es) => Int -> Eff es Int
compute value = do
    modify @Int (+ 1)
    pure value


-- | A slow computation that increments the counter
slowCompute :: (Concurrent :> es, State Int :> es) => Semaphore -> Int -> Eff es Int
slowCompute sem value = do
    Sem.wait sem
    modify @Int (+ 1)
    pure value


spec_Singleflight :: Spec
spec_Singleflight = do
    describe "Basic Behaviors" $ do
        describe "First request executes computation" $ do
            it "executes the computation on first request" $ do
                (result, execCount) <- runSingleflightTest $ do
                    withCache 1 (compute 42)
                result `shouldBe` 42
                execCount `shouldBe` 1

        describe "Cached value returned on second request" $ do
            it "returns cached value without re-executing" $ do
                (result, execCount) <- runSingleflightTest $ do
                    r1 <- withCache 1 (compute 42)
                    r2 <- withCache 1 (compute 42)
                    pure (r1, r2)
                result `shouldBe` (42, 42)
                execCount `shouldBe` 1

            it "returns cached value across multiple sequential requests" $ do
                (results, execCount) <- runSingleflightTest $ do
                    r1 <- withCache 1 (compute 42)
                    r2 <- withCache 1 (compute 42)
                    r3 <- withCache 1 (compute 42)
                    pure [r1, r2, r3]
                results `shouldBe` [42, 42, 42]
                execCount `shouldBe` 1

        describe "Concurrent requests are deduplicated" $ do
            it "executes computation once for concurrent requests" $ do
                (results, execCount) <- runSingleflightTest $ do
                    withEffToIO (ConcUnlift Persistent Unlimited) $ \unlift -> do
                        -- Launch 10 concurrent requests for the same key
                        asyncs <- replicateM 10 do
                            sem <- runSem Sem.newSet
                            async <- Async.async $ unlift $ withCache 1 (slowCompute sem 42)
                            pure (sem, async)
                        traverse_ (runSem . Sem.unset) $ fst <$> asyncs
                        traverse Async.wait $ snd <$> asyncs
                all (== 42) results `shouldBe` True
                length results `shouldBe` 10
                execCount `shouldBe` 1

            it "all concurrent waiters receive the same result" $ do
                (results, execCount) <- runSingleflightTest $ do
                    withEffToIO (ConcUnlift Persistent Unlimited) $ \unlift -> do
                        sem <- runSem Sem.new
                        -- Launch concurrent requests with different delays
                        a1 <- Async.async $ unlift $ withCache 1 (slowCompute sem 99)
                        threadDelay 1000 -- Ensure first request starts
                        a2 <- Async.async $ unlift $ withCache 1 (compute 99)
                        a3 <- Async.async $ unlift $ withCache 1 (compute 99)
                        runSem $ Sem.signal sem -- Let first request continue
                        r1 <- liftIO $ Async.wait a1
                        r2 <- liftIO $ Async.wait a2
                        r3 <- liftIO $ Async.wait a3
                        pure [r1, r2, r3]
                results `shouldBe` [99, 99, 99]
                execCount `shouldBe` 1

        describe "Different keys execute independently" $ do
            it "executes separate computations for different keys" $ do
                (results, execCount) <- runSingleflightTest $ do
                    r1 <- withCache 1 (compute 10)
                    r2 <- withCache 2 (compute 20)
                    r3 <- withCache 3 (compute 30)
                    pure [r1, r2, r3]
                results `shouldBe` [10, 20, 30]
                execCount `shouldBe` 3

            it "different keys can run concurrently" $ do
                (results, execCount) <- runSingleflightTest $ do
                    withEffToIO (ConcUnlift Persistent Unlimited) $ \unlift -> do
                        sem <- runSem Sem.newSet
                        a1 <- Async.async $ unlift $ withCache 1 (slowCompute sem 10)
                        a2 <- Async.async $ unlift $ withCache 2 (slowCompute sem 20)
                        a3 <- Async.async $ unlift $ withCache 3 (slowCompute sem 30)
                        runSem $ replicateM_ 3 $ Sem.signal sem
                        r1 <- liftIO $ Async.wait a1
                        r2 <- liftIO $ Async.wait a2
                        r3 <- liftIO $ Async.wait a3
                        pure [r1, r2, r3]
                all (\r -> r `elem` [10, 20, 30]) results `shouldBe` True
                execCount `shouldBe` 3

        describe "UpdateCache pre-populates the cache" $ do
            it "returns pre-populated value without executing computation" $ do
                (result, execCount) <- runSingleflightTest $ do
                    updateCache [(1, 99)]
                    withCache 1 (compute 42)
                result `shouldBe` 99
                execCount `shouldBe` 0

            it "pre-populated values are returned by subsequent requests" $ do
                (results, execCount) <- runSingleflightTest $ do
                    updateCache [(1, 99)]
                    r1 <- withCache 1 (compute 42)
                    r2 <- withCache 1 (compute 42)
                    pure [r1, r2]
                results `shouldBe` [99, 99]
                execCount `shouldBe` 0

        describe "UpdateCache handles multiple entries" $ do
            it "correctly handles multiple key-value pairs" $ do
                (results, execCount) <- runSingleflightTest $ do
                    updateCache [(1, 10), (2, 20), (3, 30)]
                    r1 <- withCache 1 (compute 99)
                    r2 <- withCache 2 (compute 99)
                    r3 <- withCache 3 (compute 99)
                    pure [r1, r2, r3]
                results `shouldBe` [10, 20, 30]
                execCount `shouldBe` 0

        describe "All concurrent waiters receive the result" $ do
            it "broadcasts result to all waiting requests" $ do
                (results, execCount) <- runSingleflightTest $ do
                    withEffToIO (ConcUnlift Persistent Unlimited) $ \unlift -> do
                        -- Start one slow computation and many fast waiters
                        asyncs <- replicateM 20 do
                            sem <- runSem Sem.new
                            async <- Async.async $ unlift $ withCache 1 (slowCompute sem 777)
                            pure (sem, async)
                        traverse_ (runSem . Sem.signal) $ fst <$> asyncs
                        traverse Async.wait $ snd <$> asyncs
                all (== 777) results `shouldBe` True
                length results `shouldBe` 20
                execCount `shouldBe` 1

    describe "Edge Cases" $ do
        describe "Computation throws exception" $ do
            it "propagates exception to the first caller" $ do
                let action = runSingleflightTest $ do
                        withCache @Int @Int 1 (throwIO $ TestException "boom")
                action `shouldThrow` (\(TestException msg) -> msg == "boom")

            it "exception does not get cached" $ do
                (result, execCount) <- runSingleflightTest $ do
                    -- First request throws
                    _ <-
                        (withCache @Int @Int 1 (throwIO $ TestException "boom"))
                            `catch` \(_ :: TestException) -> pure 0
                    -- Second request should re-execute
                    withCache 1 (compute 42)
                result `shouldBe` 42
                execCount `shouldBe` 1

            it "propagates exception to all concurrent waiters" $ do
                let action = runSingleflightTest $ do
                        withEffToIO (ConcUnlift Persistent Unlimited) $ \unlift -> do
                            sem <- runSem Sem.new
                            a1 <- Async.async $ unlift $ withCache @Int @Int 1 (slowCompute sem 42 >> throwIO (TestException "concurrent-boom"))
                            threadDelay 1000
                            a2 <- Async.async $ unlift $ withCache @Int @Int 1 (compute 99)
                            runSem $ Sem.signal sem
                            _ <- Async.wait a1
                            Async.wait a2
                action `shouldThrow` (\(TestException msg) -> msg == "concurrent-boom")

        describe "UpdateCache on in-flight computation" $ do
            it "overrides result of in-flight computation" $ do
                (result, execCount) <- runSingleflightTest $ do
                    withEffToIO (ConcUnlift Persistent Unlimited) $ \unlift -> do
                        sem <- runSem Sem.new
                        -- Start slow computation
                        a1 <- Async.async $ unlift $ withCache 1 (slowCompute sem 42)
                        threadDelay 1000 -- Let it start
                        -- Update cache while computation is running
                        unlift $ updateCache [(1, 999)]
                        -- Both should get the updated value
                        runSem $ Sem.signal sem
                        Async.wait a1
                result `shouldBe` 999
                execCount `shouldBe` 1

            it "waiting requests receive updated value" $ do
                (results, execCount) <- runSingleflightTest $ do
                    withEffToIO (ConcUnlift Persistent Unlimited) $ \unlift -> do
                        sem <- runSem Sem.new
                        -- Start slow computation and waiters
                        a1 <- Async.async $ unlift $ withCache 1 (slowCompute sem 42)
                        threadDelay 1000
                        a2 <- Async.async $ unlift $ withCache 1 (compute 42)
                        threadDelay 1000
                        -- Update while they're all waiting/running
                        unlift $ updateCache [(1, 888)]
                        runSem $ Sem.signal sem
                        r1 <- Async.wait a1
                        r2 <- Async.wait a2
                        pure [r1, r2]
                all (== 888) results `shouldBe` True
                execCount `shouldBe` 1
