module Unit.Tricorder.BuildStoreSpec (spec_BuildStore) where

import Control.Concurrent (threadDelay)
import Data.Time (UTCTime (..), fromGregorian)
import Effectful (IOE, runEff, runPureEff)
import Effectful.Concurrent (Concurrent, runConcurrent)
import Test.Hspec

import Atelier.Effects.Conc (Conc, runConc)
import Atelier.Effects.Delay (Delay, runDelay)
import Atelier.Effects.Input (Input, runInputConst)
import Tricorder.BuildState (BuildId (..), BuildPhase (..), BuildResult (..), BuildState (..), DaemonInfo (..))
import Tricorder.Effects.BuildStore
    ( BuildStore
    , getState
    , putState
    , runBuildStore
    , runBuildStoreScripted
    , waitForNext
    , waitUntilDone
    )

import Atelier.Effects.Conc qualified as Conc


spec_BuildStore :: Spec
spec_BuildStore = do
    describe "runBuildStoreScripted" testScripted
    describe "runBuildStoreSTM" testSTM


--------------------------------------------------------------------------------
-- Scripted interpreter tests (pure, no IO)
--------------------------------------------------------------------------------

testScripted :: Spec
testScripted = do
    describe "getState" do
        it "returns the head of the state list" do
            let result = runScripted [buildingAt 0, doneAt 1] getState
            result.buildId `shouldBe` BuildId 0

        it "does not consume the state" do
            let result = runScripted [doneAt 1] do
                    _ <- getState
                    getState
            result.buildId `shouldBe` BuildId 1

    describe "putState" do
        it "makes the new state the current head" do
            let result = runScripted [] do
                    putState (doneAt 1)
                    getState
            result.buildId `shouldBe` BuildId 1

    describe "waitUntilDone" do
        it "returns immediately when head is already Done" do
            let result = runScripted [doneAt 1, doneAt 2] waitUntilDone
            result.buildId `shouldBe` BuildId 1

        it "skips Building states and returns the first Done" do
            let result = runScripted [buildingAt 0, buildingAt 0, doneAt 1] waitUntilDone
            result.buildId `shouldBe` BuildId 1

        it "consumes states up to and including the matched Done" do
            let result = runScripted [buildingAt 0, doneAt 1, doneAt 2] do
                    _ <- waitUntilDone
                    waitUntilDone
            result.buildId `shouldBe` BuildId 2

    describe "waitForNext" do
        it "skips states with the same buildId" do
            let result = runScripted [doneAt 1, doneAt 2] (waitForNext (BuildId 1))
            result.buildId `shouldBe` BuildId 2

        it "skips Building states regardless of buildId" do
            let result = runScripted [buildingAt 2, doneAt 2] (waitForNext (BuildId 1))
            result.buildId `shouldBe` BuildId 2

        it "skips Building and same-id Done before returning next Done" do
            let states = [buildingAt 1, doneAt 1, buildingAt 2, doneAt 2]
            let result = runScripted states (waitForNext (BuildId 1))
            result.buildId `shouldBe` BuildId 2


--------------------------------------------------------------------------------
-- STM interpreter tests (concurrent)
--------------------------------------------------------------------------------

testSTM :: Spec
testSTM = do
    describe "getState" do
        it "returns the initial Building state" do
            result <- runStm getState
            result `shouldBe` buildingAt 0

    describe "putState / getState" do
        it "reflects a written state" do
            result <- runStm do
                putState (doneAt 1)
                getState
            result `shouldBe` doneAt 1

    describe "waitUntilDone" do
        it "returns immediately when state is already Done" do
            result <- runStm do
                putState (doneAt 1)
                waitUntilDone
            result.buildId `shouldBe` BuildId 1

        it "blocks until putState Done is called from another thread" do
            result <- runStmConc do
                void $ Conc.fork do
                    liftIO (threadDelay 10_000)
                    putState (doneAt 1)
                waitUntilDone
            result.buildId `shouldBe` BuildId 1

    describe "waitForNext" do
        it "blocks until a Done state with a different buildId appears" do
            result <- runStmConc do
                putState (doneAt 1)
                void $ Conc.fork do
                    liftIO (threadDelay 10_000)
                    putState (doneAt 2)
                waitForNext (BuildId 1)
            result.buildId `shouldBe` BuildId 2

    -- Regression for the bug behind the user's "status --wait waits until
    -- the LAST cycle finishes" report: a polling-based 'waitUntilDone'
    -- could miss a transient 'Done' state if the next 'Building' phase
    -- overwrote the TVar within the poll interval, and an STM-retry
    -- version still races against the scheduler's wake-up latency. The
    -- broadcast 'TChan' of transitions makes every phase change a
    -- discrete message that can't be overwritten — so even if
    -- 'putState Done >> putState Building' happens back-to-back, the
    -- waiter observes the Done.
    describe "atomic transition capture" do
        it "observes a transient Done even if Building immediately follows" do
            result <- runStmConc do
                putState (buildingAt 1)
                -- The publisher thread fires Done and then immediately
                -- overwrites it with Building (N+1), the exact pattern the
                -- coalescing worker produces between two queued cycles.
                void $ Conc.fork do
                    liftIO (threadDelay 5_000)
                    putState (doneAt 1)
                    putState (buildingAt 2)
                waitUntilDone
            -- The waiter must report Done(1), NOT skip past it and report
            -- the later Done(2) (or block forever).
            result.buildId `shouldBe` BuildId 1
            case result.phase of
                Done _ -> pure ()
                p -> expectationFailure $ "expected Done phase, got: " <> show p


--------------------------------------------------------------------------------
-- Helpers
--------------------------------------------------------------------------------

emptyDaemonInfo :: DaemonInfo
emptyDaemonInfo = DaemonInfo {targets = [], watchDirs = [], sockPath = "", logFile = "", metricsPort = Nothing}


buildingAt :: Int -> BuildState
buildingAt n = BuildState (BuildId n) (Building Nothing) emptyDaemonInfo


doneAt :: Int -> BuildState
doneAt n = BuildState (BuildId n) (Done (BuildResult {completedAt = epoch, duration = 0, moduleCount = 0, diagnostics = [], testRuns = []})) emptyDaemonInfo


epoch :: UTCTime
epoch = UTCTime (fromGregorian 1970 1 1) 0


runScripted :: [BuildState] -> Eff '[BuildStore] a -> a
runScripted states = runPureEff . runBuildStoreScripted states


runStm :: Eff '[BuildStore, Input DaemonInfo, Delay, Concurrent, IOE] a -> IO a
runStm = runEff . runConcurrent . runDelay . runInputConst emptyDaemonInfo . runBuildStore


runStmConc :: Eff '[Conc, BuildStore, Input DaemonInfo, Delay, Concurrent, IOE] a -> IO a
runStmConc = runEff . runConcurrent . runDelay . runInputConst emptyDaemonInfo . runBuildStore . runConc
