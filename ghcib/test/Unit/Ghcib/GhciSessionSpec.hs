module Unit.Ghcib.GhciSessionSpec (spec_GhciSession) where

import Control.Exception (ErrorCall (..))
import Effectful (IOE, runEff)
import Effectful.Exception (try)
import Test.Hspec

import Ghcib.BuildState (Message (..), Severity (..))
import Ghcib.Effects.GhciSession
    ( GhciSession
    , LoadResult (..)
    , reloadGhci
    , runGhciSessionScripted
    , startGhci
    , stopGhci
    )


spec_GhciSession :: Spec
spec_GhciSession = do
    describe "runGhciSessionScripted" testScripted


--------------------------------------------------------------------------------
-- Scripted interpreter tests
--------------------------------------------------------------------------------

testScripted :: Spec
testScripted = do
    describe "startGhci" do
        it "returns scripted messages" do
            LoadResult {messages = msgs} <-
                runScripted [Right [errMsg]]
                    $ startGhci "cabal repl" "/"
            msgs `shouldBe` [errMsg]

        it "returns empty list when scripted result has no messages" do
            LoadResult {messages = msgs} <-
                runScripted [Right []]
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
            LoadResult {messages = msgs} <- runScripted [Right [warnMsg]] reloadGhci
            msgs `shouldBe` [warnMsg]

        it "throws when scripted result is Left" do
            result <-
                runScripted [Left (toException boom)]
                    $ try @ErrorCall reloadGhci
            result `shouldBe` Left boom

    describe "stopGhci" do
        it "is always a no-op and does not consume from the queue" do
            LoadResult {messages = msgs} <- runScripted [Right [errMsg]] do
                stopGhci
                startGhci "cabal repl" "/"
            msgs `shouldBe` [errMsg]

    describe "sequencing" do
        it "consumes results in order across mixed operations" do
            (a, b) <- runScripted [Right [errMsg], Right [warnMsg]] do
                LoadResult {messages = a} <- startGhci "cabal repl" "/"
                LoadResult {messages = b} <- reloadGhci
                pure (a, b)
            a `shouldBe` [errMsg]
            b `shouldBe` [warnMsg]

        it "recover scenario: error then success" do
            result <- runScripted [Left (toException boom), Right []] do
                r1 <- try @ErrorCall $ startGhci "cabal repl" "/"
                LoadResult {messages = r2} <- startGhci "cabal repl" "/"
                pure (r1, r2)
            fst result `shouldSatisfy` isLeft
            snd result `shouldBe` []


--------------------------------------------------------------------------------
-- Helpers
--------------------------------------------------------------------------------

boom :: ErrorCall
boom = ErrorCall "simulated GHCi crash"


errMsg :: Message
errMsg =
    Message
        { severity = SError
        , file = "src/Foo.hs"
        , line = 1
        , col = 1
        , endLine = 1
        , endCol = 5
        , text = "Variable not in scope: foo"
        }


warnMsg :: Message
warnMsg =
    Message
        { severity = SWarning
        , file = "src/Bar.hs"
        , line = 10
        , col = 3
        , endLine = 10
        , endCol = 8
        , text = "Unused import"
        }


runScripted :: [Either SomeException [Message]] -> Eff '[GhciSession, IOE] a -> IO a
runScripted results = runEff . runGhciSessionScripted results
