module Unit.Tricorder.BuilderSpec (spec_Builder) where

import Data.Default (def)
import Data.IORef (IORef)
import Data.Time (UTCTime (..), addUTCTime, fromGregorian)
import Effectful (IOE, runEff, runPureEff)
import Effectful.Concurrent (runConcurrent)
import Effectful.Dispatch.Dynamic (interpret_)
import Effectful.Error.Static (runErrorNoCallStack, throwError)
import Effectful.Reader.Static (runReader)
import Effectful.State.Static.Shared (evalState, execState, runState)
import Effectful.Writer.Static.Shared (execWriter, runWriter)
import Test.Hspec (Spec, describe, it, shouldBe, shouldMatchList)

import Data.IORef qualified as IORef
import Data.Map.Strict qualified as Map
import Data.Set qualified as Set

import Atelier.Effects.Chan (runChan)
import Atelier.Effects.Clock (runClockConst)
import Atelier.Effects.Conc (runConc)
import Atelier.Effects.Delay (runDelay)
import Atelier.Effects.FileWatcher (FileEvent (..))
import Atelier.Effects.Input (runInputConst)
import Atelier.Effects.Log (runLogNoOp)
import Atelier.Effects.Monitoring.Tracing (runTracingNoOp)
import Atelier.Effects.Publishing (Pub, publish, runPubSub, runPubWriter)
import Atelier.Time (Millisecond)
import Tricorder.BuildState
    ( BuildId (..)
    , BuildPhase (..)
    , BuildResult (..)
    , BuildState (..)
    , DaemonInfo (..)
    , Diagnostic (..)
    , EnteredNewPhase (..)
    , EnteringNewPhase (..)
    , Severity (..)
    , SourceChangeDetected (..)
    , TestRun (..)
    , TestRunCompletion (..)
    )
import Tricorder.Builder
    ( BuilderSession (..)
    , KnownTargetNames (..)
    , NewLoadResult (..)
    , compileLoadResultsIntoBuildResults
    , fileMatchesAnyTarget
    , filterToWatchDirs
    , mergeDiagnostics
    , onRestart
    , reloadOnSourceChange
    , requestTestRunsForNewBuildResults
    , resolveKnownTargets
    , setNewPhase
    )
import Tricorder.Effects.GhciSession (Controls (..), LoadResult (..), LoadedModule (..), extractTitle)
import Tricorder.Effects.SessionStore
    ( SessionStore (..)
    , SessionStoreReloaded (..)
    )
import Tricorder.Effects.TestRunner (runTestRunnerScripted)
import Tricorder.Runtime (ProjectRoot (..))
import Tricorder.Session (Session (..))

import Atelier.Effects.Delay qualified as Delay
import Atelier.Types.Semaphore qualified as Sem
import Tricorder.BuildState qualified as BuildState
import Tricorder.Builder qualified as Builder
import Tricorder.Effects.BuildStore qualified as BuildStore
import Tricorder.Effects.SessionStore qualified as SessionStore


spec_Builder :: Spec
spec_Builder = do
    describe "mergeDiagnostics" testMergeDiagnostics
    describe "filterToWatchDirs" testFilterToWatchDirs
    describe "extractTitle" testExtractTitle
    describe "compileLoadResultsIntoBuildResults" testCompileLoadResultsIntoBuildResults
    describe "requestTestRunsForNewBuildResults" testRequestTestRunsForNewBuildResults
    describe "setNewPhase" testSetNewPhase
    describe "restartOnCabalChange" testRestartOnCabalChange
    describe "rebuildOnChange (cabal reload)" testRebuildOnCabalReload
    describe "reloadOnSourceChange" testReloadOnSourceChange
    describe "resolveKnownTargets" testResolveKnownTargets
    describe "fileMatchesAnyTarget" testFileMatchesAnyTarget


testRestartOnCabalChange :: Spec
testRestartOnCabalChange = do
    it "should publish that it is building" $ run do
        (phases, _) <- runTest
        liftIO $ phases `shouldBe` [EnteringNewPhase (BuildId 1) $ Building Nothing]

    it "should increment the build ID" $ run do
        (_, buildId) <- runTest
        liftIO $ buildId `shouldBe` BuildId 2
  where
    runTest =
        runState (BuildId 1)
            . execWriter
            . runPubWriter @EnteringNewPhase
            $ onRestart

    run = runEff . runConcurrent . runLogNoOp


-- | Reproduces the hpack/cabal-reload bug: when a cabal file change leaves
-- 'BuilderSession's projected fields (command, targets, testTargets, watchDirs)
-- unchanged, 'reloader.reload' silently no-ops and the builder action is never
-- restarted. In the live daemon this manifests as the UI staying on the
-- previous build's "Done" with no rebuild kicked off after hpack rewrites
-- @tricorder.cabal@.
testRebuildOnCabalReload :: Spec
testRebuildOnCabalReload = do
    it "restarts the builder action when a cabal reload arrives" do
        runsRef <- IORef.newIORef (0 :: Int)
        -- Two sessions with identical BuilderSession projections, differing
        -- only in a field that the projection ignores (outputFile). Mirrors
        -- the real scenario where hpack rewrites the cabal file without
        -- changing GHCi targets.
        let baseSession = mkSession Nothing
            sameProjection = mkSession (Just "/other")
        sessionRef <- IORef.newIORef baseSession

        _ <- runMutable sessionRef do
            Builder.withBuilderSession baseSession \reloader _cfg -> do
                n <- liftIO $ IORef.atomicModifyIORef' runsRef (\x -> (x + 1, x + 1))
                if n == 1 then do
                    -- Let the inner Iter.fromEvents iterator subscribe.
                    Delay.wait (1 :: Millisecond)
                    liftIO $ IORef.writeIORef sessionRef sameProjection
                    reloader.reload
                    -- Give the restart a chance to fire (it won't, with the bug).
                    Delay.wait (1 :: Millisecond)
                    throwError StopSignal
                else
                    throwError StopSignal

        runs <- IORef.readIORef runsRef
        runs `shouldBe` 2
  where
    -- Constructor syntax avoids the -Wambiguous-fields warning that record
    -- update would trigger (Session and Config in Tricorder.Session share
    -- field names).
    mkSession outputFile =
        Session
            { command = "cmd"
            , targets = []
            , testTargets = []
            , watchDirs = []
            , outputFile
            , replBuildDir = "/tmp"
            , testTimeout = 10
            }

    runMutable ref =
        runEff
            . runConcurrent
            . runTracingNoOp
            . runClockConst epoch
            . runChan
            . runDelay
            . runPubSub @SessionStoreReloaded
            . runSessionStoreMutable ref
            . runErrorNoCallStack @StopSignal
            . runConc


--------------------------------------------------------------------------------
-- Effect stack for integration tests
--------------------------------------------------------------------------------

data StopSignal = StopSignal
    deriving stock (Show)


runSessionStoreMutable
    :: (IOE :> es, Pub SessionStoreReloaded :> es)
    => IORef Session
    -> Eff (SessionStore : es) a
    -> Eff es a
runSessionStoreMutable ref = interpret_ \case
    Get -> liftIO $ IORef.readIORef ref
    RawReload -> do
        session <- liftIO $ IORef.readIORef ref
        publish (SessionStoreReloaded session)


testReloadOnSourceChange :: Spec
testReloadOnSourceChange = do
    describe "Modified" do
        describe "when the file is loaded in GHCi" do
            it "publishes that it is building" do
                (_, phases) <- runTest knownFoo noTargets distinctCtrls (SourceChangeDetected "/abs/path/Foo.hs" Modified)
                phases `shouldMatchList` [EnteringNewPhase (BuildId 1) $ Building Nothing]

            it "calls controls.reload" do
                (results, _) <- runTest knownFoo noTargets distinctCtrls (SourceChangeDetected "/abs/path/Foo.hs" Modified)
                results `shouldMatchList` [NewLoadResult epoch epoch reloadLr]

        describe "when the file is not loaded in GHCi" do
            it "calls controls.add (the editor just wrote a new file)" do
                (results, _) <- runTest Map.empty noTargets distinctCtrls (SourceChangeDetected "/abs/path/New.hs" Modified)
                results `shouldMatchList` [NewLoadResult epoch epoch addLr]

        -- Regression test for stale-diagnostics bug: cold-start with a
        -- pre-existing error then fix it. Foo is in :show targets but
        -- not :show modules, so dispatch must consult KnownTargetNames to
        -- avoid issuing a no-op :add.
        describe "when the file is a known target that failed on initial load" do
            it "calls controls.reload, not controls.add" do
                (results, _) <-
                    runTest
                        Map.empty
                        (KnownTargetNames (Set.singleton "Foo"))
                        distinctCtrls
                        (SourceChangeDetected "/abs/src/Foo.hs" Modified)
                results `shouldMatchList` [NewLoadResult epoch epoch reloadLr]

    describe "Added" do
        describe "when the file is not loaded" $ it "calls controls.add" do
            (results, _) <- runTest Map.empty noTargets distinctCtrls (SourceChangeDetected "/abs/path/Foo.hs" Added)
            results `shouldMatchList` [NewLoadResult epoch epoch addLr]

        describe "when the file is already loaded" $ it "calls controls.reload (re-add is a reload)" do
            (results, _) <- runTest knownFoo noTargets distinctCtrls (SourceChangeDetected "/abs/path/Foo.hs" Added)
            results `shouldMatchList` [NewLoadResult epoch epoch reloadLr]

    describe "Removed" do
        describe "when the file is loaded" $ it "calls controls.unadd" do
            (results, _) <- runTest knownFoo noTargets distinctCtrls (SourceChangeDetected "/abs/path/Foo.hs" Removed)
            results `shouldMatchList` [NewLoadResult epoch epoch unaddLr]

        describe "when the file is not loaded" $ it "is a no-op" do
            (results, phases) <- runTest Map.empty noTargets distinctCtrls (SourceChangeDetected "/abs/path/Unknown.hs" Removed)
            results `shouldMatchList` []
            phases `shouldMatchList` []
  where
    runTest initialModuleMap initialTargets ctrls event = do
        runEff
            . runConcurrent
            . runClockConst epoch
            . evalState (BuildId 1)
            . evalState @(Map FilePath LoadedModule) initialModuleMap
            . evalState @KnownTargetNames initialTargets
            . runLogNoOp
            . runWriter
            . runPubWriter @EnteringNewPhase
            . execWriter
            . runPubWriter @NewLoadResult
            $ do
                sem <- Sem.newSet
                reloadOnSourceChange sem ctrls event

    noTargets = KnownTargetNames Set.empty

    distinctCtrls =
        Controls
            { reload = pure reloadLr
            , interrupt = pure ()
            , add = \_ -> pure addLr
            , unadd = \_ -> pure unaddLr
            }

    knownFoo =
        Map.fromList
            [
                ( "/abs/path/Foo.hs"
                , LoadedModule {relPath = "./src/Foo.hs", moduleName = "MyModule"}
                )
            ]

    -- Distinct LoadResults so tests can identify which control was invoked.
    mkLr :: Int -> LoadResult
    mkLr n =
        LoadResult
            { moduleCount = n
            , compiledFiles = Set.singleton errMsg.file
            , loadedModules = Map.empty
            , targetNames = []
            , diagnostics = []
            }
    reloadLr = mkLr 10
    addLr = mkLr 20
    unaddLr = mkLr 30


testSetNewPhase :: Spec
testSetNewPhase = do
    it "should set build phase" do
        (state, pubs) <- runEff
            . runConcurrent
            . runDelay
            . runWriter
            . runPubWriter
            . runInputConst emptyDaemonInfo
            . BuildStore.runBuildStore
            $ do
                setNewPhase $ EnteringNewPhase (BuildId 1) (Building Nothing)
                BuildStore.getState
        state
            `shouldBe` BuildState
                { buildId = BuildId 1
                , phase = Building Nothing
                , daemonInfo = emptyDaemonInfo
                }
        pubs `shouldMatchList` [EnteredNewPhase (BuildId 1) (Building Nothing)]


testCompileLoadResultsIntoBuildResults :: Spec
testCompileLoadResultsIntoBuildResults = do
    it "uses NewLoadResult's times to calculate duration" do
        let (_, r) =
                runTest
                    mempty
                    NewLoadResult
                        { startTime = addUTCTime 10 epoch
                        , endTime = addUTCTime 20 epoch
                        , loadResult =
                            LoadResult
                                { moduleCount = 2
                                , compiledFiles = Set.singleton errMsg.file
                                , loadedModules = Map.empty
                                , targetNames = []
                                , diagnostics = []
                                }
                        }
        fmap (.duration) r `shouldMatchList` [10_000]
    it "merges with existing results" do
        let (m, _) =
                runTest (Map.fromList [(errMsg.file, [errMsg])])
                    $ NewLoadResult
                        { startTime = epoch
                        , endTime = epoch
                        , loadResult =
                            LoadResult
                                { moduleCount = 2
                                , compiledFiles = Set.singleton warnMsg.file
                                , loadedModules = Map.empty
                                , targetNames = []
                                , diagnostics = [warnMsg]
                                }
                        }
        m
            `shouldBe` fromList
                [ (warnMsg.file, [warnMsg])
                , (errMsg.file, [errMsg])
                ]

    it "publishes a BuildResult" do
        let (_, rs) =
                runTest mempty
                    $ NewLoadResult
                        { startTime = epoch
                        , endTime = addUTCTime 10 epoch
                        , loadResult =
                            LoadResult
                                { moduleCount = 2
                                , compiledFiles = Set.singleton warnMsg.file
                                , loadedModules = Map.empty
                                , targetNames = []
                                , diagnostics = [warnMsg]
                                }
                        }
            expected =
                BuildResult
                    { completedAt = addUTCTime 10 epoch
                    , duration = 10_000
                    , moduleCount = 2
                    , diagnostics = [warnMsg]
                    , testRuns = []
                    }
        rs `shouldMatchList` [expected]
  where
    runTest acc =
        runPureEff
            . runWriter
            . runPubWriter
            . runReader (ProjectRoot "/")
            . execState acc
            . compileLoadResultsIntoBuildResults (def {Builder.watchDirs = ["/src"]})


testRequestTestRunsForNewBuildResults :: Spec
testRequestTestRunsForNewBuildResults = do
    describe "when there are no test targets" $ it "should skip testing" do
        phases <- runTest [] [] expected
        length phases `shouldBe` 1
        phases `shouldMatchList` [EnteringNewPhase (BuildId 1) $ Done expected]

    describe "when there are errors" $ it "should skip testing" do
        let expected' = expected {BuildState.diagnostics = [errMsg]}
        phases <- runTest ["test:foo"] [] expected'
        length phases `shouldBe` 1
        phases `shouldMatchList` [EnteringNewPhase (BuildId 1) $ Done expected']

    it "should emit EnteringNewPhase events for each test target" do
        phases <-
            runTest
                ["test:foo", "test:bar"]
                [ Right $ mkTestRun "test:foo"
                , Right $ mkTestRun "test:bar"
                ]
                expected
        length phases `shouldBe` 4
        let expectedPhases =
                [ mkTesting . buildWithTests
                    $ [ TestRunning "test:foo"
                      , TestRunning "test:bar"
                      ]
                , mkTesting . buildWithTests
                    $ [ mkTestRun "test:foo"
                      , TestRunning "test:bar"
                      ]
                , mkTesting . buildWithTests
                    $ [ mkTestRun "test:foo"
                      , mkTestRun "test:bar"
                      ]
                , mkDone . buildWithTests
                    $ [ mkTestRun "test:foo"
                      , mkTestRun "test:bar"
                      ]
                ]
        phases `shouldMatchList` expectedPhases
  where
    runTest testTargets script =
        runEff
            . runLogNoOp
            . evalState (BuildId 1)
            . execWriter
            . runPubWriter
            . runTestRunnerScripted script
            . requestTestRunsForNewBuildResults
                BuilderSession {command = "", targets = [], testTargets, watchDirs = []}

    mkPhase = EnteringNewPhase (BuildId 1)
    mkTesting = mkPhase . Testing
    mkDone = mkPhase . Done
    buildWithTests testRuns = expected {testRuns}

    expected =
        BuildResult
            { completedAt = addUTCTime 10 epoch
            , duration = 10_000
            , moduleCount = 2
            , diagnostics = [warnMsg]
            , testRuns = []
            }

    mkTestRun target =
        TestRunCompleted
            $ TestRunCompletion
                { target
                , passed = True
                , output = ""
                , testCases = []
                , duration = Nothing
                }


--------------------------------------------------------------------------------
-- resolveKnownTargets tests
--------------------------------------------------------------------------------

testResolveKnownTargets :: Spec
testResolveKnownTargets = do
    it "uses :show modules as the primary source for path↔name mapping" do
        let result =
                emptyLr
                    { loadedModules =
                        Map.fromList
                            [
                                ( "/abs/src/Foo.hs"
                                , LoadedModule {relPath = "./src/Foo.hs", moduleName = "Foo"}
                                )
                            ]
                    , targetNames = ["Foo"]
                    }
        resolveKnownTargets Map.empty result
            `shouldBe` Map.fromList
                [
                    ( "/abs/src/Foo.hs"
                    , LoadedModule {relPath = "./src/Foo.hs", moduleName = "Foo"}
                    )
                ]

    -- Regression test for the stale-results bug. After a failed compile, the
    -- module disappears from :show modules but stays in :show targets. The
    -- prior state's entry must be carried over so the dispatcher continues to
    -- see the file as "known" and issues :reload (not :add) when the user
    -- fixes the error.
    it "carries over prior state for targets that are no longer in :show modules" do
        let prev =
                Map.fromList
                    [
                        ( "/abs/src/Foo.hs"
                        , LoadedModule {relPath = "./src/Foo.hs", moduleName = "Foo"}
                        )
                    ]
            result =
                emptyLr
                    { loadedModules = Map.empty -- Foo failed to compile
                    , targetNames = ["Foo"] -- but is still a target
                    }
        resolveKnownTargets prev result `shouldBe` prev

    it "drops targets that are no longer in :show targets" do
        let prev =
                Map.fromList
                    [
                        ( "/abs/src/Foo.hs"
                        , LoadedModule {relPath = "./src/Foo.hs", moduleName = "Foo"}
                        )
                    ]
            result = emptyLr {loadedModules = Map.empty, targetNames = []}
        resolveKnownTargets prev result `shouldBe` Map.empty

    -- Dropped from the path-keyed map because we have no path↔name entry;
    -- the dispatcher still handles them via 'KnownTargetNames'.
    it "drops targets that have neither a current :show modules entry nor prior state" do
        let result = emptyLr {loadedModules = Map.empty, targetNames = ["BrandNew"]}
        resolveKnownTargets Map.empty result `shouldBe` Map.empty
  where
    emptyLr =
        LoadResult
            { moduleCount = 0
            , compiledFiles = Set.empty
            , loadedModules = Map.empty
            , targetNames = []
            , diagnostics = []
            }


--------------------------------------------------------------------------------
-- fileMatchesAnyTarget tests
--------------------------------------------------------------------------------

testFileMatchesAnyTarget :: Spec
testFileMatchesAnyTarget = do
    it "matches when the path's uppercase-suffix equals a target" do
        fileMatchesAnyTarget
            (KnownTargetNames (Set.singleton "Tricorder.Version"))
            "./tricorder/src/Tricorder/Version.hs"
            `shouldBe` True

    it "matches a single-segment module" do
        fileMatchesAnyTarget
            (KnownTargetNames (Set.singleton "Main"))
            "./app/Main.hs"
            `shouldBe` True

    it "does not match when no uppercase-suffix equals a target" do
        fileMatchesAnyTarget
            (KnownTargetNames (Set.singleton "Other.Module"))
            "./tricorder/src/Tricorder/Version.hs"
            `shouldBe` False

    it "does not match a lowercase-prefix even if textually contained" do
        fileMatchesAnyTarget
            (KnownTargetNames (Set.singleton "src.Tricorder.Version"))
            "./tricorder/src/Tricorder/Version.hs"
            `shouldBe` False

    it "handles .lhs extension" do
        fileMatchesAnyTarget
            (KnownTargetNames (Set.singleton "Foo.Bar"))
            "./src/Foo/Bar.lhs"
            `shouldBe` True


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
                    , loadedModules = Map.empty
                    , targetNames = []
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
                    , loadedModules = Map.empty
                    , targetNames = []
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
                    , loadedModules = Map.empty
                    , targetNames = []
                    , diagnostics = [newErr]
                    }
        let merged = mergeDiagnostics prev result
        Map.lookup errMsg.file merged `shouldBe` Just [newErr]

    it "accumulates diagnostics for newly seen files" do
        let result =
                LoadResult
                    { moduleCount = 1
                    , compiledFiles = Set.singleton warnMsg.file
                    , loadedModules = Map.empty
                    , targetNames = []
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
            [ "src/Tricorder/Config.hs:39:20: error: [GHC-83865]"
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
            [ "src/Tricorder/Config.hs:38:26: warning: [GHC-55631] [-Wmissing-deriving-strategies]"
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

errMsg :: Diagnostic
errMsg =
    Diagnostic
        { severity = SError
        , file = "./src/Foo.hs"
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
        , file = "./src/Bar.hs"
        , line = 10
        , col = 3
        , endLine = 10
        , endCol = 8
        , title = "Unused import"
        , text = "Unused import"
        }


epoch :: UTCTime
epoch = UTCTime (fromGregorian 1970 1 1) 0


emptyDaemonInfo :: DaemonInfo
emptyDaemonInfo =
    DaemonInfo
        { targets = []
        , watchDirs = []
        , sockPath = ""
        , logFile = ""
        , metricsPort = Nothing
        }
