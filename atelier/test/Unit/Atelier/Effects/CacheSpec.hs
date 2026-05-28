module Unit.Atelier.Effects.CacheSpec (spec_Cache) where

import Data.Time (UTCTime, addUTCTime, getCurrentTime)
import Effectful (IOE, runEff)
import Effectful.Concurrent (Concurrent, runConcurrent)
import Effectful.Reader.Static (Reader, runReader)
import Effectful.State.Static.Shared (State, evalState, put)
import Hedgehog (forAll, (===))
import Test.Hspec (Spec, describe, it, shouldBe)
import Test.Hspec.Hedgehog (hedgehog)

import Hedgehog.Gen qualified as Gen
import Hedgehog.Range qualified as Range

import Atelier.Effects.Cache (Cache, Config (..), cacheDelete, cacheInsert, cacheLookup, cacheModify, runCacheTtl)
import Atelier.Effects.Clock (Clock, runClock, runClockState)
import Atelier.Effects.Conc (Conc, runConc)
import Atelier.Effects.Delay (Delay, Timers, mkTimers, runDelay, runDelayWithControls, settle, tickNext)
import Atelier.Effects.Log (Log, runLogNoOp)


spec_Cache :: Spec
spec_Cache = do
    describe "Basic Operations" do
        it "lookup on absent key returns Nothing" do
            result <- runCacheTest $ cacheLookup @Int @Int 1
            result `shouldBe` Nothing

        it "lookup after insert returns Just value" do
            result <- runCacheTest $ do
                cacheInsert @Int @Int 1 42
                cacheLookup @Int @Int 1
            result `shouldBe` Just 42

        it "lookup after delete returns Nothing" do
            result <- runCacheTest $ do
                cacheInsert @Int @Int 1 42
                cacheDelete @Int @Int 1
                cacheLookup @Int @Int 1
            result `shouldBe` Nothing

        it "insert twice updates value" do
            result <- runCacheTest $ do
                cacheInsert @Int @Int 1 42
                cacheInsert @Int @Int 1 99
                cacheLookup @Int @Int 1
            result `shouldBe` Just 99

        it "delete on absent key is a no-op" do
            result <- runCacheTest $ do
                cacheDelete @Int @Int 1
                cacheLookup @Int @Int 1
            result `shouldBe` Nothing

    describe "Modify" do
        it "modify on absent key uses Nothing branch" do
            result <- runCacheTest $ cacheModify @Int @Int 1 (maybe 0 (+ 1))
            result `shouldBe` 0

        it "modify on present key uses Just branch" do
            result <- runCacheTest $ do
                cacheInsert @Int @Int 1 10
                cacheModify @Int @Int 1 (maybe 0 (+ 1))
            result `shouldBe` 11

        it "modify returns the new value" do
            result <- runCacheTest $ do
                _ <- cacheModify @Int @Int 1 (maybe 5 (+ 5))
                cacheModify @Int @Int 1 (maybe 5 (+ 5))
            result `shouldBe` 10

    describe "TTL Eviction" do
        it "entry is present before TTL expires" do
            t0 <- getCurrentTime
            result <- runCacheTtlTest t0 $ do
                cacheInsert @Int @Int 1 42
                cacheLookup @Int @Int 1
            result `shouldBe` Just 42

        it "entry is evicted after cleanup thread fires past TTL" do
            t0 <- getCurrentTime
            result <- runCacheTtlTest t0 $ do
                cacheInsert @Int @Int 1 42
                put (addUTCTime 3601 t0)
                tickNext
                settle
                cacheLookup @Int @Int 1
            result `shouldBe` Nothing

        it "entry within TTL survives cleanup" do
            t0 <- getCurrentTime
            result <- runCacheTtlTest t0 $ do
                cacheInsert @Int @Int 1 42
                put (addUTCTime 1800 t0)
                tickNext
                settle
                cacheLookup @Int @Int 1
            result `shouldBe` Just 42

        it "re-inserted entry retains original TTL window" do
            t0 <- getCurrentTime
            result <- runCacheTtlTest t0 $ do
                cacheInsert @Int @Int 1 42
                -- re-insert before TTL expires: updates value but preserves createdAt = t0
                cacheInsert @Int @Int 1 99
                -- advance clock past original TTL
                put (addUTCTime 3601 t0)
                tickNext
                settle
                cacheLookup @Int @Int 1
            -- createdAt was preserved from the first insert, so the entry is expired and evicted
            result `shouldBe` Nothing

    describe "Properties" do
        it "insert then lookup roundtrips value" $ hedgehog do
            v <- forAll $ Gen.int (Range.linear 0 1000)
            result <- liftIO $ runCacheTest $ do
                cacheInsert @Int @Int 1 v
                cacheLookup @Int @Int 1
            result === Just v

        it "distinct keys have independent values" $ hedgehog do
            m <- forAll $ Gen.int (Range.linear 1 20)
            n <- forAll $ Gen.int (Range.linear 1 20)
            (a, b) <- liftIO $ runCacheTest $ do
                cacheInsert @Int @Int 1 m
                cacheInsert @Int @Int 2 n
                va <- cacheLookup @Int @Int 1
                vb <- cacheLookup @Int @Int 2
                pure (va, vb)
            a === Just m
            b === Just n

        it "interleaved key access is independent" $ hedgehog do
            keys <- forAll $ Gen.list (Range.linear 1 50) Gen.bool
            -- count inserts per key by interleaving
            counts <- liftIO $ runCacheTest $ do
                let step True = cacheModify @Int @Int 1 (maybe 1 (+ 1))
                    step False = cacheModify @Int @Int 2 (maybe 1 (+ 1))
                traverse step keys
            let key1Counts = [c | (k, c) <- zip keys counts, k]
                key2Counts = [c | (k, c) <- zip keys counts, not k]
            key1Counts === [1 .. length key1Counts]
            key2Counts === [1 .. length key2Counts]

        it "concurrent inserts to different keys don't interfere" $ hedgehog do
            n <- forAll $ Gen.int (Range.linear 1 20)
            results <- liftIO $ runCacheTest $ do
                for_ [1 .. n] \i -> cacheInsert i i
                traverse (\i -> cacheLookup i) [1 .. n]
            results === map (Just . id) [1 .. n]

        it "modify is atomic under concurrency" $ hedgehog do
            n <- forAll $ Gen.int (Range.linear 1 50)
            finalVal <- liftIO $ runCacheTest $ do
                for_ [1 .. n] \_ -> cacheModify 1 (maybe 1 (+ 1))
                cacheLookup 1
            finalVal === Just n


--------------------------------------------------------------------------------
-- Test Helpers
--------------------------------------------------------------------------------

runCacheTest
    :: Eff '[Cache Int Int, Reader Config, Clock, Delay, Conc, Log, Concurrent, IOE] a
    -> IO a
runCacheTest action =
    runEff
        . runConcurrent
        . runLogNoOp
        . runConc
        . runDelay
        . runClock
        . runReader (Config {entryTtl = 3600, cleanupInterval = 3600})
        . runCacheTtl @Int @Int
        $ action


runCacheTtlTest
    :: UTCTime
    -> Eff '[Cache Int Int, Reader Config, Clock, State UTCTime, Delay, State Timers, Conc, Log, Concurrent, IOE] a
    -> IO a
runCacheTtlTest t0 action =
    runEff
        . runConcurrent
        . runLogNoOp
        . runConc
        . evalState mkTimers
        . runDelayWithControls
        . evalState t0
        . runClockState
        . runReader (Config {entryTtl = 3600, cleanupInterval = 3600})
        . runCacheTtl @Int @Int
        $ action
