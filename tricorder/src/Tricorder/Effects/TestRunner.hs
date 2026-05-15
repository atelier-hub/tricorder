module Tricorder.Effects.TestRunner
    ( -- * Effect
      TestRunner
    , runTestSuite

      -- * Interpreters
    , runTestRunnerIO
    , runTestRunnerScripted

      -- * Parsing utilities
    , GhciOutcome (..)
    , detectOutcome
    ) where

import Control.Exception (throwIO)
import Data.Time.Units (Second)
import Effectful (Effect, IOE)
import Effectful.Concurrent (Concurrent)
import Effectful.Concurrent.STM (atomically)
import Effectful.Dispatch.Dynamic (interpretWith_, reinterpret)
import Effectful.Exception (trySync)
import Effectful.Reader.Static (Reader, ask)
import Effectful.State.Static.Shared (State, evalState, get, put)
import Effectful.TH (makeEffect)
import System.Process.Typed (byteStringInput, byteStringOutput, getStderr, getStdout, proc, setStderr, setStdin, setStdout, setWorkingDir, withProcessTerm)

import Data.ByteString.Lazy qualified as BSL
import Data.List qualified as List
import Data.Text qualified as T

import Atelier.Effects.Delay (Delay, withTimeout)
import Tricorder.BuildState (TestRun (..), TestRunCompletion (..), TestRunError (..))
import Tricorder.Effects.SessionStore (SessionStore)
import Tricorder.Runtime (ProjectRoot (..))
import Tricorder.Session (Session (..))
import Tricorder.TestOutput (parseHspecOutput)

import Tricorder.Effects.SessionStore qualified as SessionStore


data TestRunner :: Effect where
    -- | Run a single test suite in a short-lived @cabal repl@ process and
    -- return the captured output and detected outcome.
    RunTestSuite :: Text -> TestRunner m TestRun


makeEffect ''TestRunner


-- | Production interpreter that spawns a short-lived @cabal repl test:\<name\>@
-- process for each suite, feeds @:main\\n:quit\\n@ to stdin, captures combined
-- stdout+stderr, and detects the outcome via 'detectOutcome'.
runTestRunnerIO
    :: ( Concurrent :> es
       , Delay :> es
       , IOE :> es
       , Reader ProjectRoot :> es
       , SessionStore :> es
       )
    => Eff (TestRunner : es) a -> Eff es a
runTestRunnerIO act = do
    ProjectRoot projectRoot <- ask
    interpretWith_ act \case
        RunTestSuite target -> do
            Session {testTimeout} <- SessionStore.get
            let config =
                    proc "cabal" ["repl", toString target]
                        & setStdin (byteStringInput ":main\n:quit\n")
                        & setWorkingDir projectRoot
                        & setStdout byteStringOutput
                        & setStderr byteStringOutput
            result <- trySync $ withProcessTerm config \p -> do
                let collectOutput = do
                        out <- atomically (getStdout p)
                        err <- atomically (getStderr p)
                        pure (out <> err)
                case testTimeout of
                    secs | secs <= 0 -> Right <$> collectOutput
                    secs ->
                        withTimeout (fromIntegral secs :: Second) collectOutput >>= \case
                            Left () -> pure (Left secs)
                            Right combined -> pure (Right combined)
            pure $ case result of
                Left ex ->
                    TestRunErrored $ TestRunError {target, message = show ex}
                Right (Left secs) ->
                    TestRunErrored $ TestRunError {target, message = "Test suite timed out after " <> show secs <> "s"}
                Right (Right combined) ->
                    let output = decodeUtf8 (BSL.toStrict combined)
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
-- means the runner crashed. Absence of an exception line is treated as pass.
detectOutcome :: Text -> GhciOutcome
detectOutcome output =
    case List.find ("*** Exception: " `T.isPrefixOf`) (T.lines output) of
        Nothing -> GhciPassed
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
