module Tricorder.Effects.TestRunner
    ( -- * Effect
      TestRunner
    , runTestSuite
    , interruptCurrent
    , resetAbort
    , isAborted

      -- * Interpreters
    , runTestRunnerIO
    , runTestRunnerScripted

      -- * Parsing utilities
    , GhciOutcome (..)
    , detectOutcome
    ) where

import Control.Concurrent.STM (readTVar, writeTVar)
import Control.Exception (throwIO)
import Data.Default (def)
import Data.Time.Units (Second)
import Effectful (Effect, IOE)
import Effectful.Concurrent (Concurrent)
import Effectful.Concurrent.STM (atomically, newTVarIO)
import Effectful.Dispatch.Dynamic (interpretWith_, reinterpret)
import Effectful.Exception (bracket_, trySync)
import Effectful.Reader.Static (Reader, ask)
import Effectful.State.Static.Shared (State, evalState, get, put)
import Effectful.TH (makeEffect)

import Data.List qualified as List
import Data.Text qualified as T

import Atelier.Effects.Conc (Conc)
import Atelier.Effects.File (File)
import Atelier.Effects.Timeout (Timeout, timeout)
import Tricorder.BuildState
    ( BuildPhase (..)
    , BuildProgress (..)
    , BuildResult (..)
    , BuildState (..)
    , TestRun (..)
    , TestRunCompletion (..)
    , TestRunError (..)
    )
import Tricorder.Effects.BuildStore (BuildStore, getState, setPhase)
import Tricorder.Effects.GhciSession.GhciParser (GhciLoading (..))
import Tricorder.Effects.GhciSession.GhciProcess (GhciProcess, execGhci, interruptGhci, withGhciProcess)
import Tricorder.Effects.SessionStore (SessionStore)
import Tricorder.Runtime (ProjectRoot (..))
import Tricorder.Session (Session (..))
import Tricorder.TestOutput (parseHspecDuration, parseHspecOutput)

import Tricorder.Effects.SessionStore qualified as SessionStore


data TestRunner :: Effect where
    -- | Run a single test suite in a short-lived @cabal repl@ process and
    -- return the captured output and detected outcome.
    RunTestSuite :: Text -> TestRunner m TestRun
    -- | Interrupt the test currently in flight (if any) and latch an abort
    -- flag so that subsequent 'RunTestSuite' calls short-circuit until
    -- 'ResetAbort' is called.
    InterruptCurrent :: TestRunner m ()
    -- | Clear the abort flag. Call this at the start of a new test run.
    ResetAbort :: TestRunner m ()
    -- | Read the abort flag without clearing it.
    IsAborted :: TestRunner m Bool


makeEffect ''TestRunner


-- | Production interpreter that spawns a short-lived @cabal repl test:\<name\>@
-- process for each suite, feeds @:main\\n:quit\\n@ to stdin, captures combined
-- stdout+stderr, and detects the outcome via 'detectOutcome'.
runTestRunnerIO
    :: ( BuildStore :> es
       , Conc :> es
       , Concurrent :> es
       , File :> es
       , IOE :> es
       , Reader ProjectRoot :> es
       , SessionStore :> es
       , Timeout :> es
       )
    => Eff (TestRunner : es) a -> Eff es a
runTestRunnerIO act = do
    ProjectRoot projectRoot <- ask
    currentProcRef <- newTVarIO (Nothing :: Maybe GhciProcess)
    abortedRef <- newTVarIO False
    interpretWith_ act \case
        InterruptCurrent -> do
            mProc <- atomically do
                writeTVar abortedRef True
                readTVar currentProcRef
            for_ mProc interruptGhci
        ResetAbort -> atomically (writeTVar abortedRef False)
        IsAborted -> atomically (readTVar abortedRef)
        RunTestSuite target -> do
            alreadyAborted <- atomically (readTVar abortedRef)
            if alreadyAborted then
                pure $ TestRunErrored $ TestRunError {target, message = "Test run aborted"}
            else do
                Session {testTimeout} <- SessionStore.get
                let onProgress = reportTestProgress target
                    noProgress = \_ -> pure ()
                result <- trySync $ withGhciProcess def ("cabal repl " <> target) projectRoot onProgress \ghci _ ->
                    bracket_
                        (atomically (writeTVar currentProcRef (Just ghci)))
                        (atomically (writeTVar currentProcRef Nothing))
                        $ case testTimeout of
                            secs | secs <= 0 -> Right <$> execGhci ghci ":main" noProgress
                            secs ->
                                timeout (fromIntegral secs :: Second) (execGhci ghci ":main" noProgress) >>= \case
                                    Nothing -> pure (Left secs)
                                    Just ls -> pure (Right ls)
                pure $ case result of
                    Left ex ->
                        TestRunErrored $ TestRunError {target, message = show ex}
                    Right (Left secs) ->
                        TestRunErrored $ TestRunError {target, message = "Test suite timed out after " <> show secs <> "s"}
                    Right (Right mainLines) ->
                        let output = T.unlines mainLines
                        in  case detectOutcome output of
                                GhciCrashed msg ->
                                    TestRunErrored $ TestRunError {target, message = msg}
                                outcome ->
                                    TestRunCompleted
                                        $ TestRunCompletion
                                            { target
                                            , passed = outcome == GhciPassed
                                            , output
                                            , testCases = parseHspecOutput output
                                            , duration = parseHspecDuration output
                                            }


-- | Scripted interpreter for testing.
--
-- Each call to 'runTestSuite' pops the next result from the pre-loaded list.
-- 'Left' results are re-thrown as exceptions, simulating process failures.
runTestRunnerScripted
    :: forall es a
     . (IOE :> es)
    => [Either SomeException TestRun]
    -> Eff (TestRunner : es) a
    -> Eff es a
runTestRunnerScripted results = reinterpret (evalState results) $ \_ ->
    let popResult :: Eff (State [Either SomeException TestRun] : es) TestRun
        popResult =
            get >>= \case
                [] -> error "TestRunnerScripted: no more results in queue"
                Left ex : rest -> put rest >> liftIO (throwIO ex)
                Right r : rest -> put rest >> pure r
    in  \case
            RunTestSuite _ -> popResult
            InterruptCurrent -> pure ()
            ResetAbort -> pure ()
            IsAborted -> pure False


-- | Patch live compile progress for a test suite into the current 'Testing'
-- phase of the build state.
--
-- A test suite's @cabal repl@ session typically recompiles a slice of the
-- project before running @:main@. Mirroring the main-build progress bar, we
-- update the matching 'TestRunning' entry as each @[N of M] Compiling …@
-- line arrives so the UI shows @running... (N/M)@ live.
--
-- The update is best-effort: if the phase has moved on (e.g. a source change
-- triggered 'Restarting' or 'Building'), the progress event is dropped rather
-- than reverting the phase.
reportTestProgress
    :: (BuildStore :> es) => Text -> GhciLoading -> Eff es ()
reportTestProgress target loading = do
    state <- getState
    case state.phase of
        Testing partialResult ->
            let progress = BuildProgress {compiled = loading.index, total = loading.total}
                updateRun (TestRunning t _) | t == target = TestRunning t (Just progress)
                updateRun r = r
                newRuns = map updateRun partialResult.testRuns
            in  setPhase state.buildId (Testing partialResult {testRuns = newRuns})
        _ -> pure ()


data GhciOutcome
    = GhciPassed
    | GhciFailed
    | GhciCrashed Text
    deriving stock (Eq, Show)


-- | Detect the test outcome from raw GHCi output.
--
-- All major test frameworks (@hspec@, @tasty@, @HUnit@) call
-- 'System.Exit.exitWith' on completion. GHCi surfaces this as a line
-- matching @*** Exception: ExitSuccess@ (pass) or
-- @*** Exception: ExitFailure N@ (fail). Any other @*** Exception:@ line
-- means the runner crashed.
--
-- When no exception line is present, the absence is ambiguous: either the
-- test ran and printed nothing exit-related, or @:main@ never ran at all
-- (e.g. the test target failed to compile, so @main@ is not in scope).
-- A line containing @": error:"@ in the captured output is treated as the
-- latter — a GHC compile/load error that prevented the suite from running.
detectOutcome :: Text -> GhciOutcome
detectOutcome output =
    case List.find ("*** Exception: " `T.isPrefixOf`) outputLines of
        Just line ->
            case T.stripPrefix "*** Exception: " line of
                Nothing -> GhciPassed
                Just rest ->
                    let r = T.strip rest
                    in  if r == "ExitSuccess" then
                            GhciPassed
                        else
                            if "ExitFailure" `T.isPrefixOf` r then
                                GhciFailed
                            else
                                GhciCrashed r
        Nothing -> case List.find isCompileErrorLine outputLines of
            Just errLine -> GhciCrashed (T.strip errLine)
            Nothing -> GhciPassed
  where
    outputLines = T.lines output
    -- GHC compile/load errors are formatted as
    -- @<file-or-loc>:L:C: error: …@ (with at least one space after the colon).
    -- The substring @": error:"@ is the canonical marker for these.
    isCompileErrorLine line = ": error:" `T.isInfixOf` line
