module Tricorder.Effects.TestRunner
    ( -- * Effect
      TestRunner
    , runTestSuite

      -- * Interpreters
    , runTestRunnerIO
    , runTestRunnerScripted

      -- * Parsing utilities
    , detectOutcome
    ) where

import Control.Exception (throwIO)
import Effectful (Effect, IOE)
import Effectful.Dispatch.Dynamic (interpretWith_, reinterpret)
import Effectful.Exception (trySync)
import Effectful.Reader.Static (Reader, ask)
import Effectful.State.Static.Shared (State, evalState, get, put)
import Effectful.TH (makeEffect)
import System.Process.Typed (byteStringInput, proc, readProcess, setStdin, setWorkingDir)

import Data.ByteString.Lazy qualified as BSL
import Data.List qualified as List
import Data.Text qualified as T

import Tricorder.BuildState (TestOutcome (..), TestRun (..))
import Tricorder.Session.ProjectRoot (ProjectRoot (..))


data TestRunner :: Effect where
    -- | Run a single test suite in a short-lived @cabal repl@ process and
    -- return the captured output and detected outcome.
    RunTestSuite :: Text -> TestRunner m TestRun


makeEffect ''TestRunner


-- | Production interpreter that spawns a short-lived @cabal repl test:\<name\>@
-- process for each suite, feeds @:main\\n:quit\\n@ to stdin, captures combined
-- stdout+stderr, and detects the outcome via 'detectOutcome'.
runTestRunnerIO :: (IOE :> es, Reader ProjectRoot :> es) => Eff (TestRunner : es) a -> Eff es a
runTestRunnerIO act = do
    ProjectRoot projectRoot <- ask
    interpretWith_ act \case
        RunTestSuite target -> do
            result <- trySync $ liftIO do
                let config =
                        setStdin (byteStringInput ":main\n:quit\n")
                            $ setWorkingDir projectRoot
                            $ proc "cabal" ["repl", toString target]
                (_, out, err) <- readProcess config
                pure (out, err)
            pure $ case result of
                Left ex ->
                    TestRun {target, outcome = TestsError (show ex :: Text), output = ""}
                Right (out, err) ->
                    let output = decodeUtf8 (BSL.toStrict out) <> decodeUtf8 (BSL.toStrict err)
                    in  TestRun {target, outcome = detectOutcome output, output}


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


-- | Detect the test outcome from raw GHCi output.
--
-- All major test frameworks (@hspec@, @tasty@, @HUnit@) call
-- 'System.Exit.exitWith' on completion. GHCi surfaces this as a line
-- matching @*** Exception: ExitSuccess@ (pass) or
-- @*** Exception: ExitFailure N@ (fail). Any other @*** Exception:@ line
-- means the runner crashed. Absence of an exception line is treated as pass.
detectOutcome :: Text -> TestOutcome
detectOutcome output =
    case List.find ("*** Exception: " `T.isPrefixOf`) (T.lines output) of
        Nothing -> TestsPassed
        Just line ->
            case T.stripPrefix "*** Exception: " line of
                Nothing -> TestsPassed
                Just rest ->
                    let r = T.strip rest
                    in  if r == "ExitSuccess" then
                            TestsPassed
                        else
                            if "ExitFailure" `T.isPrefixOf` r then
                                TestsFailed
                            else
                                TestsError r
