module Unit.Tricorder.Effects.GhciSessionSpec (spec_GhciSession) where

import Control.Exception (ErrorCall (..))
import Effectful (IOE, runEff)
import Effectful.Exception (try)
import Test.Hspec (Spec, describe, it, shouldBe, shouldSatisfy)

import Data.Set qualified as Set

import Tricorder.BuildState (Diagnostic (..), Severity (..))
import Tricorder.Effects.GhciSession
    ( GhciSession
    , LoadResult (..)
    , runGhciSessionScripted
    , withGhci
    )
import Tricorder.Runtime (ProjectRoot (..))


spec_GhciSession :: Spec
spec_GhciSession = do
    describe "runGhciSessionScripted" testScripted


--------------------------------------------------------------------------------
-- Scripted interpreter tests
--------------------------------------------------------------------------------

testScripted :: Spec
testScripted = do
    describe "withGhci" do
        describe "initial load" do
            it "returns scripted messages" do
                LoadResult {diagnostics = msgs} <-
                    runScripted [simpleResult [errMsg]]
                        $ withGhci "cabal repl" (ProjectRoot "/") \initial _ -> pure initial
                msgs `shouldBe` [errMsg]

            it "returns empty list when scripted result has no messages" do
                LoadResult {diagnostics = msgs} <-
                    runScripted [simpleResult []]
                        $ withGhci "cabal repl" (ProjectRoot "/") \initial _ -> pure initial
                msgs `shouldBe` []

            it "throws when scripted result is Left" do
                result <-
                    runScripted [Left (toException boom)]
                        $ try @ErrorCall
                        $ withGhci "cabal repl" (ProjectRoot "/") \initial _ -> pure initial
                result `shouldBe` Left boom

        describe "reloading" do
            it "returns scripted messages" do
                LoadResult {diagnostics = msgs} <-
                    runScripted [simpleResult [warnMsg], simpleResult [errMsg]]
                        $ withGhci "cabal repl" (ProjectRoot "/") \_ reload -> reload
                msgs `shouldBe` [errMsg]

            it "throws when scripted result is Left" do
                result <-
                    runScripted [Left (toException boom)]
                        $ try @ErrorCall
                        $ withGhci "cabal repl" (ProjectRoot "/") \_ reload -> reload
                result `shouldBe` Left boom

    describe "sequencing" do
        it "consumes results in order across mixed operations" do
            (a, b) <- runScripted [simpleResult [errMsg], simpleResult [warnMsg]] do
                withGhci "cabal repl" (ProjectRoot "/") \LoadResult {diagnostics = a} reload -> do
                    LoadResult {diagnostics = b} <- reload
                    pure (a, b)
            a `shouldBe` [errMsg]
            b `shouldBe` [warnMsg]

        it "recover scenario: error then success" do
            result <- runScripted [Left (toException boom), simpleResult []] do
                r1 <- try @ErrorCall $ withGhci "cabal repl" (ProjectRoot "/") \i _ -> pure i
                LoadResult {diagnostics = r2} <- withGhci "cabal repl" (ProjectRoot "/") \i _ -> pure i
                pure (r1, r2)
            fst result `shouldSatisfy` isLeft
            snd result `shouldBe` []


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


-- | Convenience constructor: a scripted result with no compiled-file info.
simpleResult :: [Diagnostic] -> Either SomeException LoadResult
simpleResult msgs = Right LoadResult {moduleCount = 0, compiledFiles = Set.empty, diagnostics = msgs}


runScripted :: [Either SomeException LoadResult] -> Eff '[GhciSession, IOE] a -> IO a
runScripted results = runEff . runGhciSessionScripted results
