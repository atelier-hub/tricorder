module Unit.Atelier.Effects.ConcSpec (spec_Conc) where

import Control.Exception (ErrorCall (..), throwIO)
import Effectful (IOE, runEff)
import Effectful.Concurrent (Concurrent, runConcurrent)
import Hedgehog (forAll, (===))
import Test.Hspec (Spec, anyException, context, describe, it, shouldBe, shouldSatisfy, shouldThrow)
import Test.Hspec.Hedgehog (hedgehog)

import Data.IORef qualified as IORef
import Hedgehog.Gen qualified as Gen
import Hedgehog.Range qualified as Range

import Atelier.Effects.Conc (Conc, await, awaitAll, fork, forkTry, fork_, runConc, scoped)
import Atelier.Effects.Timeout (Timeout, runTimeout, timeout_)
import Atelier.Time (Millisecond)

import Atelier.Types.Semaphore qualified as Sem


spec_Conc :: Spec
spec_Conc = do
    describe "Thread cleanup" do
        context "without scoped" do
            it "demonstrates thread lifetime" $ runTest do
                -- This test shows threads live for the duration of their scope
                counter <- liftIO $ IORef.newIORef (0 :: Int)

                sem <- Sem.new

                -- Thread we fork here will live until the root scope (in
                -- 'runTest') exits.
                fork_ $ forever do
                    liftIO $ IORef.atomicModifyIORef' counter (\n -> (n + 1, ()))
                    Sem.wait sem

                -- Let it run once
                Sem.signal sem
                countAfter <- liftIO $ IORef.readIORef counter

                -- Let it run once more
                Sem.signal sem
                finalCount <- liftIO $ IORef.readIORef counter

                liftIO $ finalCount `shouldSatisfy` (> countAfter)

        context "with scoped" do
            it "kills nested threads when scope exits" $ runTest do
                counter <- liftIO $ IORef.newIORef (0 :: Int)

                sem <- Sem.new

                -- Create nested scope that will clean up its threads
                scoped $ do
                    fork_ $ forever $ do
                        liftIO $ IORef.atomicModifyIORef' counter (\n -> (n + 1, ()))
                        Sem.wait sem
                    -- Let it run once
                    Sem.signal sem
                -- Inner scope exits here - thread should be KILLED

                -- Capture count after scope exit
                countAfter <- liftIO $ IORef.readIORef counter

                -- Try to let it run again
                timeout_ (1 :: Millisecond) $ Sem.signal sem

                -- Count should NOT increase after scope exit
                finalCount <- liftIO $ IORef.readIORef counter

                liftIO $ finalCount `shouldBe` countAfter

    describe "fork and await" do
        it "returns the result of the forked computation" do
            result <- runTestSimple $ do
                t <- fork $ pure (42 :: Int)
                await t
            result `shouldBe` 42

        it "executes the forked action" do
            result <- runTestSimple $ do
                ref <- liftIO $ IORef.newIORef False
                t <- fork $ liftIO $ IORef.writeIORef ref True
                await t
                liftIO $ IORef.readIORef ref
            result `shouldBe` True

    describe "awaitAll" do
        it "waits for all forked threads to complete" $ hedgehog do
            n <- forAll $ Gen.int (Range.linear 1 20)
            result <- liftIO $ runTestSimple $ do
                ref <- liftIO $ IORef.newIORef (0 :: Int)
                replicateM_ n $ fork $ liftIO $ IORef.atomicModifyIORef' ref (\x -> (x + 1, ()))
                awaitAll
                liftIO $ IORef.readIORef ref
            result === n

    describe "forkTry" do
        it "returns Right for a successful computation" do
            result <- runTestSimple $ do
                t <- forkTry @ErrorCall $ pure (42 :: Int)
                await t
            result `shouldBe` Right 42

        it "returns Left when the forked thread throws" do
            result <- runTestSimple $ do
                t <- forkTry @ErrorCall $ liftIO $ throwIO $ ErrorCall "boom"
                await t
            (result :: Either ErrorCall Int) `shouldSatisfy` isLeft

    describe "exception propagation" do
        it "uncaught exception in forked thread propagates to the scope" do
            let action = runTestSimple $ do
                    _ <- fork $ liftIO $ throwIO $ ErrorCall "boom"
                    awaitAll
            action `shouldThrow` anyException


--------------------------------------------------------------------------------
-- Test Helpers
--------------------------------------------------------------------------------

runTest :: Eff '[Timeout, Conc, Concurrent, IOE] a -> IO a
runTest = runEff . runConcurrent . runConc . runTimeout


runTestSimple :: Eff '[Conc, Concurrent, IOE] a -> IO a
runTestSimple = runEff . runConcurrent . runConc
