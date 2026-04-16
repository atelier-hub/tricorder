module Unit.Tricorder.GhciSessionSpec (spec_GhciSession) where

import Control.Exception (ErrorCall (..))
import Data.Time (UTCTime (..), addUTCTime, fromGregorian)
import Effectful (IOE, runEff)
import Effectful.Concurrent (Concurrent, runConcurrent)
import Effectful.Exception (try)
import Test.Hspec

import Data.Map.Strict qualified as Map
import Data.Set qualified as Set

import Atelier.Effects.Clock (Clock, runClockList)
import Atelier.Effects.Conc (Conc, fork, runConc)
import Atelier.Effects.Delay (Delay, runDelay)
import Atelier.Effects.Log (Log, runLogNoOp)
import Tricorder.BuildState (BuildPhase (..), BuildResult (..), BuildState (..), Diagnostic (..), Severity (..))
import Tricorder.Effects.BuildStore (BuildStore, runBuildStoreSTM, waitUntilDone)
import Tricorder.Effects.GhciSession
    ( GhciSession
    , LoadResult (..)
    , extractTitle
    , reloadGhci
    , runGhciSessionScripted
    , startGhci
    , stopGhci
    )
import Tricorder.Effects.TestRunner (TestRunner, runTestRunnerScripted)
import Tricorder.GhciSession (filterToWatchDirs, mergeDiagnostics, sessionListener)


spec_GhciSession :: Spec
spec_GhciSession = do
    describe "runGhciSessionScripted" testScripted
    describe "sessionListener" testSessionListener
    describe "mergeDiagnostics" testMergeDiagnostics
    describe "filterToWatchDirs" testFilterToWatchDirs
    describe "extractTitle" testExtractTitle


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
                void $ fork $ sessionListener "cabal repl" "/" [] []
                waitUntilDone
            case result.phase of
                Done br -> br.durationMs `shouldBe` 2000
                _ -> expectationFailure "expected Done phase"

        it "records moduleCount from LoadResult" do
            result <- runListenerTest [epoch, epoch] [simpleResultWith 7 []] do
                void $ fork $ sessionListener "cabal repl" "/" [] []
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
-- filterToWatchDirs tests
--------------------------------------------------------------------------------

testFilterToWatchDirs :: Spec
testFilterToWatchDirs = do
    let root = "/project"
        watchDirs = ["/project/src"]

    it "keeps diagnostics under a watched directory" do
        -- ./src/Foo.hs is what toRelative produces for an absolute project file
        let d = errMsg {file = "./src/Foo.hs"}
        filterToWatchDirs root watchDirs [d] `shouldBe` [d]

    it "drops diagnostics from outside the project (e.g. Nix store .h files)" do
        let d = errMsg {file = "/nix/store/abc123/ghcautoconf.h"}
        filterToWatchDirs root watchDirs [d] `shouldBe` []

    it "drops diagnostics with mangled CPP filenames" do
        -- The ghcid parser produces "In file included from <path>" as the file
        -- field for GCC-style CPP include-chain messages.
        let d = errMsg {file = "In file included from src/Foo.hs"}
        filterToWatchDirs root watchDirs [d] `shouldBe` []

    it "drops mangled CPP filenames when watchDirs is [\".\"] (project root)" do
        -- With watchDirs=["."], the watch dir resolves to projectRoot itself.
        -- A mangled path joined onto projectRoot would incorrectly start with
        -- projectRoot+"/", so this case requires an explicit guard.
        let d = errMsg {file = "In file included from src/Foo.hs"}
        filterToWatchDirs root ["."] [d] `shouldBe` []

    it "passes everything through when watchDirs is empty" do
        let d = errMsg {file = "/nix/store/abc123/ghcautoconf.h"}
        filterToWatchDirs root [] [d] `shouldBe` [d]

    it "works with the '.' fallback watch dir (whole project root)" do
        let d = errMsg {file = "./src/Foo.hs"}
            nixD = errMsg {file = "/nix/store/abc123/ghcautoconf.h"}
        filterToWatchDirs root ["."] [d, nixD] `shouldBe` [d]


--------------------------------------------------------------------------------
-- extractTitle tests
--------------------------------------------------------------------------------

testExtractTitle :: Spec
testExtractTitle = do
    it "returns empty string for empty message" do
        extractTitle [] `shouldBe` ""

    -- New GHC style: header ends with [GHC-XXXXX], content on body lines.
    -- Captured from GHC 9.10.2 with -Weverything.
    it "extracts first body line for error with [GHC-XXXXX] code" do
        extractTitle
            [ "src/Ghcib/Config.hs:39:20: error: [GHC-83865]"
            , "    \8226 Couldn't match expected type 'Int' with actual type 'Bool'"
            , "    \8226 In the expression: True"
            , "      In an equation for '_deliberateError': _deliberateError = True"
            , "   |"
            , "39 | _deliberateError = True"
            , "   |                    ^^^^"
            ]
            `shouldBe` "\8226 Couldn't match expected type 'Int' with actual type 'Bool'"

    it "extracts first body line for warning with [GHC-XXXXX] [-Wfoo] codes" do
        extractTitle
            [ "src/Ghcib/Config.hs:38:26: warning: [GHC-55631] [-Wmissing-deriving-strategies]"
            , "    No deriving strategy specified. Did you want stock, newtype, or anyclass?"
            , "   |"
            , "38 | data TestWarn = TestWarn deriving (Eq)"
            , "   |                          ^^^^^^^^^^^^^"
            ]
            `shouldBe` "No deriving strategy specified. Did you want stock, newtype, or anyclass?"

    -- Old GHC style: message text is inline on the header line.
    it "extracts inline content for old-style single-line error" do
        extractTitle ["GHCi.hs:70:1: error: Parse error: naked expression at top level"]
            `shouldBe` "Parse error: naked expression at top level"

    it "extracts inline content for old-style Warning (capital W)" do
        extractTitle ["GHCi.hs:81:1: Warning: Defined but not used: \8216foo\8217"]
            `shouldBe` "Defined but not used: \8216foo\8217"

    -- Multi-line without any inline message: position-only or "Warning:" header.
    it "extracts first body line when header has position only" do
        extractTitle
            [ "GHCi.hs:72:13:"
            , "    No instance for (Num ([String] -> [String]))"
            , "      arising from the literal '1'"
            ]
            `shouldBe` "No instance for (Num ([String] -> [String]))"

    it "extracts first body line when header ends with 'Warning:'" do
        extractTitle
            [ "/src/TrieSpec.hs:(192,7)-(193,76): Warning:"
            , "    A do-notation statement discarded a result of type '[()]'"
            ]
            `shouldBe` "A do-notation statement discarded a result of type '[()]'"

    -- Source display lines (pipe/caret) must be skipped.
    it "skips source display lines when scanning body" do
        extractTitle
            [ "file.hs:1:1: error: [GHC-12345]"
            , "   |"
            , "1 | foo bar"
            , "   |     ^^^"
            , "    actual content here"
            ]
            `shouldBe` "actual content here"

    -- ANSI-escaped header (colour output): strip escapes before searching.
    it "handles ANSI-escaped headers" do
        extractTitle
            [ "\ESC[;1msrc/Types.hs:11:1: \ESC[35mwarning:\ESC[0m \ESC[35m[-Wunused-imports]\ESC[0m"
            , "    The import of 'Data.Data' is redundant"
            ]
            `shouldBe` "The import of 'Data.Data' is redundant"


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
    -> Eff '[GhciSession, TestRunner, Conc, Clock, BuildStore, Delay, Log, Concurrent, IOE] a
    -> IO a
runListenerTest times results =
    runEff
        . runConcurrent
        . runLogNoOp
        . runDelay
        . runBuildStoreSTM
        . runClockList times
        . runConc
        . runTestRunnerScripted []
        . runGhciSessionScripted results
