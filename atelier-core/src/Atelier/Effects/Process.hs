-- | Effect for spawning and interacting with external processes.
--
-- Unifies @typed-process@ (configuration, lifecycle and stream capture) and
-- the one operation only @process@ provides (process-group interruption)
-- behind a single effect, so callers never depend on either package directly.
--
-- Build a 'ProcessConfig' with the re-exported @typed-process@ DSL
-- ('proc', 'shell', 'setStdin', …), then run it with one of the operations
-- below.
module Atelier.Effects.Process
    ( -- * Effect
      Process

      -- * Building process configs (re-exported from @typed-process@)
    , ProcessConfig
    , RunningProcess
    , proc
    , shell
    , setStdin
    , setStdout
    , setStderr
    , setWorkingDir
    , setCreateGroup
    , createPipe
    , getStdin
    , getStdout
    , getStderr

      -- * Operations
    , readProcessStdout
    , readProcessSafe
    , startProcess
    , stopProcess
    , waitExitCode
    , interruptProcessGroup

      -- * Interpreters
    , runProcessIO
    ) where

import Effectful (Effect, IOE)
import Effectful.Dispatch.Dynamic (interpret_)
import Effectful.Exception (trySync)
import Effectful.TH (makeEffect)
import System.Exit (ExitCode (..))
import System.Process (interruptProcessGroupOf)
import System.Process.Typed
    ( ProcessConfig
    , createPipe
    , getStderr
    , getStdin
    , getStdout
    , proc
    , setCreateGroup
    , setStderr
    , setStdin
    , setStdout
    , setWorkingDir
    , shell
    )

import System.Process.Typed qualified as TP


-- | @typed-process@'s started-process type, re-exported under a non-clashing
-- name (the effect itself is called 'Process'). Parameterised by its stdin,
-- stdout and stderr stream types.
type RunningProcess = TP.Process


data Process :: Effect where
    -- | Run a process to completion, returning its exit code and captured stdout.
    ReadProcessStdout :: ProcessConfig i o e -> Process m (ExitCode, LByteString)
    -- | Spawn a process and return its handle for further interaction.
    StartProcess :: ProcessConfig i o e -> Process m (TP.Process i o e)
    -- | Stop a process: close its streams, terminate it, and wait for it to exit.
    StopProcess :: TP.Process i o e -> Process m ()
    -- | Block until the process exits and return its exit code.
    WaitExitCode :: TP.Process i o e -> Process m ExitCode
    -- | Send an interrupt (SIGINT) to the process's group. Requires the process
    -- to have been started with @'setCreateGroup' True@.
    InterruptProcessGroup :: TP.Process i o e -> Process m ()


makeEffect ''Process


-- | Run @cmd@ with @args@ and return its stdout as 'Text', or 'Nothing' on any
-- error (non-zero exit, the executable not being found, etc.).
readProcessSafe :: (Process :> es) => FilePath -> [String] -> Eff es (Maybe Text)
readProcessSafe cmd args = do
    result <- trySync $ readProcessStdout (proc cmd args)
    pure $ case result of
        Right (ExitSuccess, out) -> Just (decodeUtf8 out)
        _ -> Nothing


runProcessIO :: (IOE :> es) => Eff (Process : es) a -> Eff es a
runProcessIO = interpret_ \case
    ReadProcessStdout cfg -> liftIO $ TP.readProcessStdout cfg
    StartProcess cfg -> liftIO $ TP.startProcess cfg
    StopProcess p -> liftIO $ TP.stopProcess p
    WaitExitCode p -> liftIO $ TP.waitExitCode p
    InterruptProcessGroup p -> liftIO $ interruptProcessGroupOf (TP.unsafeProcessHandle p)
