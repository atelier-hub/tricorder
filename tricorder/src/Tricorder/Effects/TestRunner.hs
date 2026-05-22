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
import Data.Default (def)
import Data.Time.Units (Second)
import Effectful (Effect, IOE)
import Effectful.Concurrent (Concurrent)
import Effectful.Dispatch.Dynamic (interpretWith_, reinterpret)
import Effectful.Exception (trySync)
import Effectful.Reader.Static (Reader, ask)
import Effectful.State.Static.Shared (State, evalState, get, put)
import Effectful.TH (makeEffect)

import Data.List qualified as List
import Data.Text qualified as T

import Atelier.Effects.Conc (Conc)
import Atelier.Effects.Delay (Delay, withTimeout)
import Atelier.Effects.File (File)
import Tricorder.BuildState (TestRun (..), TestRunCompletion (..), TestRunError (..))
import Tricorder.Effects.GhciSession.GhciProcess (execGhci, withGhciProcess)
import Tricorder.Effects.SessionStore (SessionStore)
import Tricorder.Runtime (ProjectRoot (..))
import Tricorder.Session (Session (..))
import Tricorder.TestOutput (parseHspecDuration, parseHspecOutput)

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
    interpretWith_ act \case
        RunTestSuite target -> do
            Session {testTimeout} <- SessionStore.get
            result <- trySync $ withGhciProcess def ("cabal repl " <> target) projectRoot \ghci _ -> do
                case testTimeout of
                    secs | secs <= 0 -> Right <$> execGhci ghci ":main"
                    secs ->
                        withTimeout (fromIntegral secs :: Second) (execGhci ghci ":main") >>= \case
                            Left () -> pure (Left secs)
                            Right ls -> pure (Right ls)
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
