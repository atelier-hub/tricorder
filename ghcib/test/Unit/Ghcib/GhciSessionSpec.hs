module Unit.Ghcib.GhciSessionSpec (spec_GhciSession) where

import Control.Exception (ErrorCall (..))
import Data.Time (UTCTime (..), addUTCTime, fromGregorian)
import Effectful (IOE, runEff)
import Effectful.Concurrent (Concurrent, runConcurrent)
import Effectful.Exception (try)
import Test.Hspec

import Data.Map.Strict qualified as Map
import Data.Set qualified as Set

import Atelier.Effects.Chan (Chan, newChan, runChan)
import Atelier.Effects.Clock (Clock, runClockList)
import Atelier.Effects.Conc (Conc, fork, runConc)
import Atelier.Effects.Delay (Delay, runDelay)
import Atelier.Effects.Log (Log, runLogNoOp)
import Ghcib.BuildState (BuildPhase (..), BuildResult (..), BuildState (..), Diagnostic (..), Severity (..))
import Ghcib.Effects.BuildStore (BuildStore, runBuildStoreSTM, waitUntilDone)
import Ghcib.Effects.GhciSession
    ( GhciSession
    , LoadResult (..)
    , reloadGhci
    , runGhciSessionScripted
    , startGhci
    , stopGhci
    )
import Ghcib.GhciSession (mergeDiagnostics, sessionListener)
import Ghcib.Watcher (ReloadRequest)


spec_GhciSession :: Spec
spec_GhciSession = do
    describe "runGhciSessionScripted" testScripted
    describe "sessionListener" testSessionListener
    describe "mergeDiagnostics" testMergeDiagnostics


--------------------------------------------------------------------------------
-- Scripted interpreter tests
--------------------------------------------------------------------------------

testScripted :: Spec
testScripted = do
    describe "startGhci" do
        it "returns scripted messages" do
            LoadResult {diagnostics = msgs} <-
                runScripted [simpleResult [errMsg]]
                    $ startGhci "cabal repl" "/"
            msgs `shouldBe` [errMsg]

        it "returns empty list when scripted result has no messages" do
            LoadResult {diagnostics = msgs} <-
                runScripted [simpleResult []]
                    $ startGhci "cabal repl" "/"
            msgs `shouldBe` []

        it "throws when scripted result is Left" do
            result <-
                runScripted [Left (toException boom)]
                    $ try @ErrorCall
                    $ startGhci "cabal repl" "/"
            result `shouldBe` Left boom

    describe "reloadGhci" do
        it "returns scripted messages" do
            LoadResult {diagnostics = msgs} <- runScripted [simpleResult [warnMsg]] reloadGhci
            msgs `shouldBe` [warnMsg]

        it "throws when scripted result is Left" do
            result <-
                runScripted [Left (toException boom)]
                    $ try @ErrorCall reloadGhci
            result `shouldBe` Left boom

    describe "stopGhci" do
        it "is always a no-op and does not consume from the queue" do
            LoadResult {diagnostics = msgs} <- runScripted [simpleResult [errMsg]] do
                stopGhci
                startGhci "cabal repl" "/"
            msgs `shouldBe` [errMsg]

    describe "sequencing" do
        it "consumes results in order across mixed operations" do
            (a, b) <- runScripted [simpleResult [errMsg], simpleResult [warnMsg]] do
                LoadResult {diagnostics = a} <- startGhci "cabal repl" "/"
                LoadResult {diagnostics = b} <- reloadGhci
                pure (a, b)
            a `shouldBe` [errMsg]
            b `shouldBe` [warnMsg]

        it "recover scenario: error then success" do
            result <- runScripted [Left (toException boom), simpleResult []] do
                r1 <- try @ErrorCall $ startGhci "cabal repl" "/"
                LoadResult {diagnostics = r2} <- startGhci "cabal repl" "/"
                pure (r1, r2)
            fst result `shouldSatisfy` isLeft
            snd result `shouldBe` []


--------------------------------------------------------------------------------
-- sessionListener tests
--------------------------------------------------------------------------------

testSessionListener :: Spec
testSessionListener = do
    describe "startSession" do
        it "records elapsed time in durationMs" do
            let t0 = epoch
                t1 = addUTCTime 2 epoch -- 2 seconds later
            result <- runListenerTest [t0, t1] [simpleResult []] do
                (_, reloadOut) <- newChan @ReloadRequest
                void $ fork $ sessionListener "cabal repl" "/" reloadOut
                waitUntilDone
            case result.phase of
                Done br -> br.durationMs `shouldBe` 2000
                _ -> expectationFailure "expected Done phase"

        it "records moduleCount from LoadResult" do
            result <- runListenerTest [epoch, epoch] [simpleResultWith 7 []] do
                (_, reloadOut) <- newChan @ReloadRequest
                void $ fork $ sessionListener "cabal repl" "/" reloadOut
                waitUntilDone
            case result.phase of
                Done br -> br.moduleCount `shouldBe` 7
                _ -> expectationFailure "expected Done phase"


--------------------------------------------------------------------------------
-- mergeDiagnostics tests
--------------------------------------------------------------------------------

testMergeDiagnostics :: Spec
testMergeDiagnostics = do
    it "retains diagnostics from files not in compiledFiles" do
        -- Foo has an error, Bar has a warning.
        -- Only Foo is recompiled (and fixed). Bar is unchanged, so Bar's
        -- warning must survive.
        let prev = Map.fromList [(errMsg.file, [errMsg]), (warnMsg.file, [warnMsg])]
            result =
                LoadResult
                    { moduleCount = 2
                    , compiledFiles = Set.singleton errMsg.file
                    , diagnostics = []
                    }
        let merged = mergeDiagnostics prev result
        Map.lookup warnMsg.file merged `shouldBe` Just [warnMsg]

    it "clears diagnostics when a recompiled file now has no issues" do
        let prev = Map.fromList [(errMsg.file, [errMsg])]
            result =
                LoadResult
                    { moduleCount = 1
                    , compiledFiles = Set.singleton errMsg.file
                    , diagnostics = []
                    }
        let merged = mergeDiagnostics prev result
        Map.lookup errMsg.file merged `shouldBe` Nothing

    it "replaces diagnostics for recompiled files" do
        let newErr = errMsg {title = "new error", text = "new error\n"}
            prev = Map.fromList [(errMsg.file, [errMsg])]
            result =
                LoadResult
                    { moduleCount = 1
                    , compiledFiles = Set.singleton errMsg.file
                    , diagnostics = [newErr]
                    }
        let merged = mergeDiagnostics prev result
        Map.lookup errMsg.file merged `shouldBe` Just [newErr]

    it "accumulates diagnostics for newly seen files" do
        let result =
                LoadResult
                    { moduleCount = 1
                    , compiledFiles = Set.singleton warnMsg.file
                    , diagnostics = [warnMsg]
                    }
        let merged = mergeDiagnostics Map.empty result
        Map.lookup warnMsg.file merged `shouldBe` Just [warnMsg]


--------------------------------------------------------------------------------
-- Helpers
--------------------------------------------------------------------------------

boom :: ErrorCall
boom = ErrorCall "simulated GHCi crash"


errMsg :: Diagnostic
errMsg =
    Diagnostic
        { severity = SError
        , file = "src/Foo.hs"
        , line = 1
        , col = 1
        , endLine = 1
        , endCol = 5
        , title = "Variable not in scope: foo"
        , text = "Variable not in scope: foo"
        }


warnMsg :: Diagnostic
warnMsg =
    Diagnostic
        { severity = SWarning
        , file = "src/Bar.hs"
        , line = 10
        , col = 3
        , endLine = 10
        , endCol = 8
        , title = "Unused import"
        , text = "Unused import"
        }


epoch :: UTCTime
epoch = UTCTime (fromGregorian 1970 1 1) 0


-- | Convenience constructor: a scripted result with no compiled-file info.
simpleResult :: [Diagnostic] -> Either SomeException LoadResult
simpleResult msgs = Right LoadResult {moduleCount = 0, compiledFiles = Set.empty, diagnostics = msgs}


simpleResultWith :: Int -> [Diagnostic] -> Either SomeException LoadResult
simpleResultWith n msgs = Right LoadResult {moduleCount = n, compiledFiles = Set.empty, diagnostics = msgs}


runScripted :: [Either SomeException LoadResult] -> Eff '[GhciSession, IOE] a -> IO a
runScripted results = runEff . runGhciSessionScripted results


runListenerTest
    :: [UTCTime]
    -> [Either SomeException LoadResult]
    -> Eff '[GhciSession, Conc, Clock, Chan, BuildStore, Delay, Log, Concurrent, IOE] a
    -> IO a
runListenerTest times results =
    runEff
        . runConcurrent
        . runLogNoOp
        . runDelay
        . runBuildStoreSTM
        . runChan
        . runClockList times
        . runConc
        . runGhciSessionScripted results
