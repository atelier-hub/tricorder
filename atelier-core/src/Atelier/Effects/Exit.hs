module Atelier.Effects.Exit
    ( -- * Effect
      Exit
    , exitWith
    , exitSuccess
    , exitFailure

      -- * Interpreters
    , runExit
    , runExitNoOp
    ) where

import Effectful (Effect, IOE)
import Effectful.Dispatch.Dynamic (interpret_, reinterpret_)
import Effectful.Error.Static (runErrorNoCallStack, throwError)
import Effectful.TH (makeEffect)
import System.Exit (ExitCode (..))

import System.Exit qualified as IO


data Exit :: Effect where
    ExitWith :: ExitCode -> Exit m a


makeEffect ''Exit


exitSuccess :: (Exit :> es) => Eff es a
exitSuccess = exitWith ExitSuccess


exitFailure :: (Exit :> es) => Eff es a
exitFailure = exitWith (ExitFailure 1)


runExit :: (IOE :> es) => Eff (Exit : es) a -> Eff es a
runExit = interpret_ \(ExitWith code) -> liftIO (IO.exitWith code)


-- | Exit interpreter that captures exit calls instead of terminating the process.
-- Returns 'Left' the exit code if the action exited, 'Right' the result otherwise.
-- Useful in unit tests.
runExitNoOp :: Eff (Exit : es) a -> Eff es (Either ExitCode a)
runExitNoOp =
    reinterpret_ (runErrorNoCallStack @ExitCode) \(ExitWith code) -> throwError code
