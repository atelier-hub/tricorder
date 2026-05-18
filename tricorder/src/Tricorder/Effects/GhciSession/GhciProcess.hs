module Tricorder.Effects.GhciSession.GhciProcess
    ( Config (..)
    , GhciProcess
    , GhciProcessError (..)
    , withGhciProcess
    , execGhci
    , interruptGhci
    , collectGhciResult
    , reloadGhci
    ) where

import Control.Concurrent.STM (TVar, readTVar, retry, writeTVar)
import Data.Default (Default (..))
import Data.Time.Units (Second)
import Effectful (IOE)
import Effectful.Concurrent (Concurrent)
import Effectful.Concurrent.Async (concurrently)
import Effectful.Concurrent.STM (atomically, newTVarIO)
import Effectful.Exception (bracket, finally, throwIO, try, trySync)
import System.Process (interruptProcessGroupOf)
import System.Process.Typed
    ( Process
    , createPipe
    , getStderr
    , getStdin
    , getStdout
    , setCreateGroup
    , setStderr
    , setStdin
    , setStdout
    , setWorkingDir
    , shell
    , startProcess
    , stopProcess
    , unsafeProcessHandle
    , waitExitCode
    )

import Control.Exception qualified as E
import Data.Text qualified as T
import Data.Text.IO qualified as TIO

import Atelier.Effects.Conc (Conc)
import Atelier.Effects.Delay (Delay, withTimeout)
import Atelier.Effects.File (File)
import Tricorder.Effects.GhciSession.GhciParser
    ( GhciLoad (..)
    , GhciLoading (..)
    , LoadResult (..)
    , collectResultCustom
    , parseReload
    , parseShowModules
    , stripAnsi
    )

import Atelier.Effects.Conc qualified as Conc
import Atelier.Effects.File qualified as File


-- | Configuration for GHCi process management.
data Config = Config
    { startupTimeout :: Second
    -- ^ How long to wait for the GHCi version banner on startup.
    , shutdownTimeout :: Second
    -- ^ How long to wait for the process to exit gracefully before force-killing.
    , extraSetupCommands :: [Text]
    -- ^ Additional GHCi commands to send after the fixed setup block.
    -- Use this to inject session-wide options such as @:set -XOverloadedStrings@.
    }


instance Default Config where
    def =
        Config
            { startupTimeout = 60
            , shutdownTimeout = 5
            , extraSetupCommands = []
            }


data SessionState = Idle Int | Busy Int


-- | A handle to a running GHCi subprocess.
data GhciProcess = GhciProcess
    { stdin :: Handle
    , stdout :: Handle
    , stderr :: Handle
    , handle :: Process Handle Handle Handle
    , stateVar :: TVar SessionState
    }


-- | Errors that can occur during GHCi process management.
data GhciProcessError
    = StartupTimeout
    | UnexpectedExit Text (Maybe Text)
    deriving stock (Eq, Show)


instance Exception GhciProcessError


-- | Start a GHCi subprocess running the given command in the given directory.
--
-- Waits up to 'startupTimeout' seconds for GHCi to print its version banner,
-- then performs initial setup (setting prompts and synchronising) and sends
-- any 'extraSetupCommands' from the config.
startGhciProcess :: (Conc :> es, Concurrent :> es, Delay :> es, File :> es, IOE :> es) => Config -> Text -> FilePath -> Eff es (GhciProcess, [Text])
startGhciProcess config cmd dir = do
    p <-
        liftIO
            $ startProcess
            $ setStdin createPipe
            $ setStdout createPipe
            $ setStderr createPipe
            $ setCreateGroup True
            $ setWorkingDir dir
            $ shell (toString cmd)
    let inp = getStdin p
        out = getStdout p
        err = getStderr p
    File.hSetBuffering inp LineBuffering
    File.hSetBuffering out LineBuffering
    File.hSetBuffering err LineBuffering

    -- Send a blank line to kick GHCi into producing output
    liftIO $ TIO.hPutStrLn inp ""
    File.hFlush inp

    -- Wait for the version banner
    bannerSeen <- waitForBanner config.startupTimeout out
    unless bannerSeen do
        liftIO $ stopProcess p
        throwIO StartupTimeout

    -- Send fixed setup commands (protocol requirements)
    liftIO $ TIO.hPutStrLn inp ":set prompt \"\""
    liftIO $ TIO.hPutStrLn inp ":set prompt-cont \"\""
    liftIO $ TIO.hPutStrLn inp ":set +c"
    -- Send any caller-supplied extra setup commands
    for_ config.extraSetupCommands \c ->
        liftIO $ TIO.hPutStrLn inp c
    File.hFlush inp

    -- Create state var
    stateVar <- newTVarIO (Idle 0)

    let ghciProcess =
            GhciProcess
                { stdin = inp
                , stdout = out
                , stderr = err
                , handle = p
                , stateVar = stateVar
                }

    -- Sync: drain until marker 1 seen, then set counter to 2.
    -- Capture lines from both streams — the stderr output contains the initial
    -- compilation progress and any startup diagnostics.
    let marker1 = markerFor 1
    sendSyncCommand inp marker1
    initialLines <- Conc.scoped do
        stdoutThread <- Conc.fork $ drainUntil out marker1
        stderrThread <- Conc.fork $ drainUntil err marker1
        stdoutLines <- Conc.await stdoutThread
        stderrLines <- Conc.await stderrThread
        pure (stdoutLines ++ stderrLines)
    atomically $ writeTVar stateVar (Idle 2)

    pure (ghciProcess, initialLines)


-- | Bracket helper: start a GHCi process, run an action, then stop it.
--
-- The action receives both the process handle and the output lines captured
-- during the startup sync (stdout ++ stderr). These lines contain the initial
-- compilation progress and any startup diagnostics.
withGhciProcess
    :: (Conc :> es, Concurrent :> es, Delay :> es, File :> es, IOE :> es)
    => Config
    -> Text
    -> FilePath
    -> (GhciProcess -> [Text] -> Eff es a)
    -> Eff es a
withGhciProcess config cmd dir action =
    bracket
        (startGhciProcess config cmd dir)
        (stopGhciProcess config . fst)
        (uncurry action)


-- | Execute a command in GHCi and return the combined stdout+stderr output lines.
execGhci :: (Concurrent :> es, File :> es, IOE :> es) => GhciProcess -> Text -> Eff es [Text]
execGhci ghciProcess command = do
    n <- atomically do
        readTVar ghciProcess.stateVar >>= \case
            Idle n -> writeTVar ghciProcess.stateVar (Busy n) $> n
            Busy _ -> retry
    doExec n `finally` atomically (writeTVar ghciProcess.stateVar (Idle (n + 1)))
  where
    doExec n = do
        let marker = markerFor n
        liftIO $ TIO.hPutStrLn ghciProcess.stdin command
        File.hFlush ghciProcess.stdin
        sendSyncCommand ghciProcess.stdin marker
        (stdoutLines, stderrLines) <-
            concurrently
                (drainUntil ghciProcess.stdout marker)
                (drainUntil ghciProcess.stderr marker)
        pure (stdoutLines ++ stderrLines)


-- | Interrupt the currently running GHCi command (if any).
--
-- Sends SIGINT to the GHCi process group and writes a new sync marker so
-- that any in-progress 'drainUntil' unblocks.
interruptGhci :: (Concurrent :> es, File :> es, IOE :> es) => GhciProcess -> Eff es ()
interruptGhci ghciProcess = do
    n <- atomically do
        s <- readTVar ghciProcess.stateVar
        let n = case s of Idle n' -> n'; Busy n' -> n'
        writeTVar ghciProcess.stateVar (Idle (n + 1))
        pure n
    liftIO $ interruptProcessGroupOf (unsafeProcessHandle ghciProcess.handle)
    sendSyncCommand ghciProcess.stdin (markerFor (n + 1))


-- | Stop the GHCi process gracefully, falling back to forced termination.
--
-- Never throws — all errors are swallowed.
stopGhciProcess :: (Concurrent :> es, Delay :> es, File :> es, IOE :> es) => Config -> GhciProcess -> Eff es ()
stopGhciProcess config ghciProcess = do
    -- Try to write :quit
    void $ trySync $ do
        liftIO $ TIO.hPutStrLn ghciProcess.stdin ":quit"
        File.hFlush ghciProcess.stdin

    -- Wait up to shutdownTimeout seconds for the process to exit, then force-kill
    result <- withTimeout config.shutdownTimeout (liftIO $ waitExitCode ghciProcess.handle)
    when (not (isRight result))
        $ liftIO
        $ stopProcess ghciProcess.handle

    -- Close all handles, ignoring errors
    for_ [ghciProcess.stdin, ghciProcess.stdout, ghciProcess.stderr] \h ->
        void $ trySync $ File.hClose h


-- ---------------------------------------------------------------------------
-- Internal helpers

-- | Build the finish marker for counter value @n@.
markerFor :: Int -> Text
markerFor n = markerPrefix <> show n <> "~#"


-- | The prefix shared by all finish markers.
markerPrefix :: Text
markerPrefix = "#~TRI-FINISH-"


-- | Write the synchronisation Haskell expression to GHCi stdin.
--
-- After each user command, this expression causes GHCi to emit the finish
-- marker on both stdout and stderr, so 'drainUntil' knows when to stop.
sendSyncCommand :: (File :> es, IOE :> es) => Handle -> Text -> Eff es ()
sendSyncCommand h marker = do
    -- Use show to produce a valid Haskell string literal for the marker text.
    let markerLit = toText (show @String (toString marker)) -- e.g. "\"#~TRI-FINISH-3~#\""
        cmd =
            "putStrLn "
                <> markerLit
                <> " >> System.IO.hPutStrLn System.IO.stderr "
                <> markerLit
    liftIO $ TIO.hPutStrLn h cmd
    File.hFlush h


-- | Read lines from a handle until any finish marker is seen (or EOF).
--
-- Stops on any line containing the marker prefix, so an interrupt that writes
-- a later marker will unblock a drain waiting for an earlier one.
-- Returns accumulated non-marker lines in order. Throws 'UnexpectedExit' on
-- EOF before a marker is seen.
drainUntil :: (File :> es) => Handle -> Text -> Eff es [Text]
drainUntil h command = go []
  where
    go acc = do
        result <- try @E.IOException $ File.hGetLine h
        case result of
            Left _ ->
                throwIO $ UnexpectedExit command (listToMaybe (reverse acc))
            Right line ->
                if markerPrefix `T.isInfixOf` line then
                    pure (reverse acc)
                else
                    go (line : acc)


-- | Wait up to the given number of seconds for a GHCi version banner on the
-- given handle.
--
-- Returns 'True' if the banner was seen, 'False' on timeout.
waitForBanner :: (Concurrent :> es, Delay :> es, File :> es) => Second -> Handle -> Eff es Bool
waitForBanner timeout h = do
    result <- withTimeout timeout go
    pure (isRight result)
  where
    isVersionLine :: Text -> Bool
    isVersionLine line =
        let stripped = stripAnsi line
        in  "GHCi, version " `T.isInfixOf` stripped
                || "GHCJSi, version " `T.isInfixOf` stripped
                || "Clashi, version " `T.isInfixOf` stripped

    go = do
        result <- try @E.IOException $ File.hGetLine h
        case result of
            Left ex -> throwIO ex
            Right line ->
                if isVersionLine line then
                    pure ()
                else
                    go


-- | Parse GHCi output lines into a 'LoadResult', fetching the current module
-- list via @:show modules@. Emits a progress callback for each
-- @[N of M] Compiling …@ line.
collectGhciResult
    :: (Concurrent :> es, File :> es, IOE :> es)
    => GhciProcess
    -> [Text]
    -> FilePath
    -> (GhciLoading -> Eff es ())
    -> Eff es LoadResult
collectGhciResult process lines' projectRoot onProgress = do
    let loads = parseReload lines'
    for_ [l | GLoading l <- loads] onProgress
    moduleLines <- execGhci process ":show modules"
    pure $ collectResultCustom projectRoot loads (parseShowModules moduleLines)


-- | Execute @:reload@ and return the assembled 'LoadResult', emitting a
-- progress callback for each @[N of M] Compiling …@ line.
reloadGhci
    :: (Concurrent :> es, File :> es, IOE :> es)
    => GhciProcess
    -> FilePath
    -> (GhciLoading -> Eff es ())
    -> Eff es LoadResult
reloadGhci process projectRoot onProgress = do
    reloadLines <- execGhci process ":reload"
    collectGhciResult process reloadLines projectRoot onProgress
