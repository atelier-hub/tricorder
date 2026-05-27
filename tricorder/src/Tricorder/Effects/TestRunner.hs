module Tricorder.Effects.TestRunner
    ( -- * Effect
      TestRunner
    , withBatch
    , interruptCurrent

      -- * Types
    , TestRunOutcome (..)
    , BatchStatus (..)

      -- * Interpreters
    , runTestRunnerIO
    , runTestRunnerScripted

      -- * Parsing utilities
    , GhciOutcome (..)
    , detectOutcome
    ) where

import Control.Concurrent.STM (readTVar, writeTVar)
import Data.Default (def)
import Data.Time.Units (Second)
import Effectful (Effect, IOE)
import Effectful.Concurrent (Concurrent)
import Effectful.Concurrent.STM (atomically, newTVarIO)
import Effectful.Dispatch.Dynamic (interpret, localSeqUnlift, reinterpret)
import Effectful.Exception (bracket_, trySync)
import Effectful.Reader.Static (Reader, ask)
import Effectful.State.Static.Shared (State, evalState, state)
import Effectful.TH (makeEffect)

import Data.List qualified as List
import Data.Text qualified as T

import Atelier.Effects.Conc (Conc)
import Atelier.Effects.Delay (Delay, withTimeout)
import Atelier.Effects.File (File)
import Tricorder.BuildState (TestRun (..), TestRunCompletion (..), TestRunError (..))
import Tricorder.Effects.GhciSession.GhciProcess (GhciProcess, execGhci, interruptGhci, withGhciProcess)
import Tricorder.Effects.SessionStore (SessionStore)
import Tricorder.Runtime (ProjectRoot (..))
import Tricorder.Session (Session (..))
import Tricorder.TestOutput (parseHspecDuration, parseHspecOutput)

import Tricorder.Effects.SessionStore qualified as SessionStore


data TestRunOutcome
    = TestCompleted TestRun
    | TestAborted
    deriving stock (Eq, Show)


data BatchStatus
    = BatchCompleted
    | BatchAborted
    deriving stock (Eq, Show)


data TestRunner :: Effect where
    -- | Run a batch of test suites. The abort latch is reset on entry so a
    -- stale interrupt from a previous batch cannot short-circuit this one.
    -- Iterates targets in order, invoking the callback per outcome. Stops on
    -- the first 'TestAborted' (which is also delivered to the callback).
    WithBatch :: [Text] -> (Text -> TestRunOutcome -> m ()) -> TestRunner m BatchStatus
    -- | Interrupt the test currently in flight (if any) and latch an abort
    -- flag so the in-progress 'WithBatch' loop bails out at the next step.
    InterruptCurrent :: TestRunner m ()


makeEffect ''TestRunner


-- | Production interpreter that spawns a short-lived @cabal repl test:\<name\>@
-- process for each suite, feeds @:main@ to stdin, captures combined
-- stdout+stderr, and detects the outcome via 'detectOutcome'.
runTestRunnerIO
    :: ( Conc :> es
       , Concurrent :> es
       , Delay :> es
       , File :> es
       , IOE :> es
       , Reader ProjectRoot :> es
       , SessionStore :> es
       )
    => Eff (TestRunner : es) a -> Eff es a
runTestRunnerIO act = do
    ProjectRoot projectRoot <- ask
    currentProcRef <- newTVarIO (Nothing :: Maybe GhciProcess)
    abortedRef <- newTVarIO False
    interpret
        ( \env -> \case
            InterruptCurrent -> do
                mProc <- atomically do
                    writeTVar abortedRef True
                    readTVar currentProcRef
                for_ mProc interruptGhci
            WithBatch targets callback -> do
                atomically (writeTVar abortedRef False)
                localSeqUnlift env \unlift -> do
                    let go [] = pure BatchCompleted
                        go (target : rest) = do
                            outcome <- runOneSuite projectRoot currentProcRef abortedRef target
                            unlift (callback target outcome)
                            case outcome of
                                TestAborted -> pure BatchAborted
                                TestCompleted _ -> go rest
                    go targets
        )
        act
  where
    runOneSuite projectRoot currentProcRef abortedRef target = do
        alreadyAborted <- atomically (readTVar abortedRef)
        if alreadyAborted then
            pure TestAborted
        else do
            Session {testTimeout} <- SessionStore.get
            result <- trySync $ withGhciProcess def ("cabal repl " <> target) projectRoot \ghci _ ->
                bracket_
                    (atomically (writeTVar currentProcRef (Just ghci)))
                    (atomically (writeTVar currentProcRef Nothing))
                    $ case testTimeout of
                        secs | secs <= 0 -> Right <$> execGhci ghci ":main"
                        secs ->
                            withTimeout (fromIntegral secs :: Second) (execGhci ghci ":main") >>= \case
                                Left () -> pure (Left secs)
                                Right ls -> pure (Right ls)
            -- If interrupt fired during the run, surface it uniformly as
            -- TestAborted rather than leaking the kill-induced exception
            -- through as a confusing TestRunErrored that callers would
            -- discard anyway.
            abortedDuring <- atomically (readTVar abortedRef)
            if abortedDuring then
                pure TestAborted
            else pure $ TestCompleted $ case result of
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
-- Each iteration of a 'WithBatch' loop pops one 'TestRunOutcome' from the
-- pre-loaded queue, invokes the callback, and (if the outcome is
-- 'TestAborted') stops the loop with 'BatchAborted'.
runTestRunnerScripted
    :: forall es a
     . [TestRunOutcome]
    -> Eff (TestRunner : es) a
    -> Eff es a
runTestRunnerScripted outcomes = reinterpret (evalState outcomes) $ \env -> \case
    InterruptCurrent -> pure ()
    WithBatch targets callback ->
        let popOutcome :: Eff (State [TestRunOutcome] : es) TestRunOutcome
            popOutcome = state \case
                x : xs -> (x, xs)
                [] -> error "TestRunnerScripted: no more outcomes in queue"
            go [] = pure BatchCompleted
            go (target : rest) = do
                outcome <- popOutcome
                localSeqUnlift env \unlift -> unlift (callback target outcome)
                case outcome of
                    TestAborted -> pure BatchAborted
                    TestCompleted _ -> go rest
        in  go targets


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
