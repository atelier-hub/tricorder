module Tricorder.Effects.GhciSession.GhciProcess
    ( Config (..)
    , GhciProcess
    , GhciProcessError (..)
    , withGhciProcess
    , execGhci
    , interruptGhci
    , collectGhciResult
    , reloadGhci
    , addGhci
    , unaddGhci
    ) where

import Control.Concurrent.STM (TVar, readTVar, retry, writeTVar)
import Data.Default (Default (..))
import Data.Time.Units (Second)
import Effectful (IOE)
import Effectful.Concurrent (Concurrent)
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
import Atelier.Effects.File (File)
import Atelier.Effects.Timeout (Timeout, timeout)
import Tricorder.Effects.GhciSession.GhciParser
    ( GhciLoading (..)
    , LoadResult (..)
    , collectResultCustom
    , parseProgressLine
    , parseReload
    , parseShowModules
    , parseShowTargets
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
startGhciProcess
    :: ( Conc :> es
       , Concurrent :> es
       , File :> es
       , IOE :> es
       , Timeout :> es
       )
    => Config
    -> Text
    -> FilePath
    -> (GhciLoading -> Eff es ())
    -- ^ Called as each @[N of M] Compiling …@ line is streamed during the
    -- initial-build drain, so the UI can update the progress bar live
    -- instead of replaying everything once compilation finishes.
    -> Eff es (GhciProcess, [Text])
startGhciProcess config cmd dir onProgress = do
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
    -- compilation progress and any startup diagnostics. The line hook fires
    -- 'onProgress' for each "[N of M] Compiling …" line as it arrives, so the
    -- UI can update the progress bar live during the initial build.
    let marker1 = markerFor 1
        hook = progressLineHook onProgress
    sendSyncCommand inp marker1
    initialLines <- Conc.scoped do
        stdoutThread <- Conc.fork $ drainUntil out marker1 hook
        stderrThread <- Conc.fork $ drainUntil err marker1 hook
        stdoutLines <- Conc.await stdoutThread
        stderrLines <- Conc.await stderrThread
        pure (stdoutLines ++ stderrLines)
    atomically $ writeTVar stateVar (Idle 2)

    pure (ghciProcess, initialLines)


-- | Bracket helper: start a GHCi process, run an action, then stop it.
--
-- The action receives both the process handle and the output lines captured
-- during the startup sync (stdout ++ stderr). These lines contain the initial
-- compilation progress and any startup diagnostics. The @onProgress@ callback
-- fires for each @[N of M] Compiling …@ line as GHCi emits it during the
-- initial build, so the UI can update its progress bar in real time.
withGhciProcess
    :: (Conc :> es, Concurrent :> es, File :> es, IOE :> es, Timeout :> es)
    => Config
    -> Text
    -> FilePath
    -> (GhciLoading -> Eff es ())
    -> (GhciProcess -> [Text] -> Eff es a)
    -> Eff es a
withGhciProcess config cmd dir onProgress action =
    bracket
        (startGhciProcess config cmd dir onProgress)
        (stopGhciProcess config . fst)
        (uncurry action)


-- | Execute a command in GHCi and return the combined stdout+stderr output
-- lines. The @onProgress@ callback fires for each @[N of M] Compiling …@ line
-- as it arrives, so reload/add/unadd progress is streamed live to the UI.
-- Pass @\\_ -> pure ()@ for commands that do not trigger compilation.
execGhci
    :: ( Conc :> es
       , Concurrent :> es
       , File :> es
       , IOE :> es
       )
    => GhciProcess -> Text -> (GhciLoading -> Eff es ()) -> Eff es [Text]
execGhci ghciProcess command onProgress = do
    n <- atomically do
        readTVar ghciProcess.stateVar >>= \case
            Idle n -> writeTVar ghciProcess.stateVar (Busy n) $> n
            Busy _ -> retry
    doExec n `finally` atomically (writeTVar ghciProcess.stateVar (Idle (n + 1)))
  where
    doExec n = do
        let marker = markerFor n
            hook = progressLineHook onProgress
        liftIO $ TIO.hPutStrLn ghciProcess.stdin command
        File.hFlush ghciProcess.stdin
        sendSyncCommand ghciProcess.stdin marker
        (stdoutLines, stderrLines) <- do
            stdoutThread <- Conc.fork $ drainUntil ghciProcess.stdout marker hook
            stderrThread <- Conc.fork $ drainUntil ghciProcess.stderr marker hook
            (,) <$> Conc.await stdoutThread <*> Conc.await stderrThread
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
stopGhciProcess
    :: (File :> es, IOE :> es, Timeout :> es)
    => Config -> GhciProcess -> Eff es ()
stopGhciProcess config ghciProcess = do
    -- Try to write :quit
    void $ trySync $ do
        liftIO $ TIO.hPutStrLn ghciProcess.stdin ":quit"
        File.hFlush ghciProcess.stdin

    -- Wait up to shutdownTimeout seconds for the process to exit, then force-kill
    result <- timeout config.shutdownTimeout (liftIO $ waitExitCode ghciProcess.handle)
    when (not (isJust result))
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
-- a later marker will unblock a drain waiting for an earlier one. Each
-- non-marker line is passed to @onLine@ as it arrives, so callers can stream
-- progress without waiting for the full drain to complete.
-- Returns accumulated non-marker lines in order. Throws 'UnexpectedExit' on
-- EOF before a marker is seen.
drainUntil :: (File :> es) => Handle -> Text -> (Text -> Eff es ()) -> Eff es [Text]
drainUntil h command onLine = go []
  where
    go acc = do
        result <- try @E.IOException $ File.hGetLine h
        case result of
            Left _ ->
                throwIO $ UnexpectedExit command (listToMaybe (reverse acc))
            Right line ->
                if markerPrefix `T.isInfixOf` line then
                    pure (reverse acc)
                else do
                    onLine line
                    go (line : acc)


-- | Convert a 'GhciLoading' progress callback into a per-line hook suitable
-- for 'drainUntil'. Non-progress lines are ignored.
progressLineHook :: (GhciLoading -> Eff es ()) -> Text -> Eff es ()
progressLineHook onProgress line = traverse_ onProgress (parseProgressLine line)


-- | Wait up to the given number of seconds for a GHCi version banner on the
-- given handle.
--
-- Returns 'True' if the banner was seen, 'False' on timeout.
waitForBanner
    :: ( File :> es
       , Timeout :> es
       )
    => Second -> Handle -> Eff es Bool
waitForBanner delay h = do
    result <- timeout delay go
    pure (isJust result)
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


-- | Parse already-drained GHCi output lines into a 'LoadResult', fetching the
-- current module list via @:show modules@.
--
-- Progress is emitted live by 'drainUntil' as lines arrive, so no replay
-- callback is needed here — this function only assembles the final result.
collectGhciResult
    :: (Conc :> es, Concurrent :> es, File :> es, IOE :> es)
    => GhciProcess
    -> [Text]
    -> FilePath
    -> Eff es LoadResult
collectGhciResult process lines' projectRoot = do
    let loads = parseReload lines'
        noProgress = \_ -> pure ()
    moduleLines <- execGhci process ":show modules" noProgress
    targetLines <- execGhci process ":show targets" noProgress
    pure
        $ collectResultCustom
            projectRoot
            loads
            (parseShowModules moduleLines)
            (parseShowTargets targetLines)


-- | Execute @:reload@ and return the assembled 'LoadResult'. Progress events
-- fire live via @onProgress@ as each @[N of M] Compiling …@ line is read.
reloadGhci
    :: (Conc :> es, Concurrent :> es, File :> es, IOE :> es)
    => GhciProcess
    -> FilePath
    -> (GhciLoading -> Eff es ())
    -> Eff es LoadResult
reloadGhci process projectRoot onProgress = do
    reloadLines <- execGhci process ":reload" onProgress
    collectGhciResult process reloadLines projectRoot


-- | Execute @:add@ for the given file and return the assembled 'LoadResult'.
-- Progress events fire live via @onProgress@ as compilation proceeds.
addGhci
    :: (Conc :> es, Concurrent :> es, File :> es, IOE :> es)
    => GhciProcess
    -> FilePath -- the file to :add
    -> FilePath -- projectRoot
    -> (GhciLoading -> Eff es ())
    -> Eff es LoadResult
addGhci process filePath projectRoot onProgress = do
    addLines <- execGhci process (":add " <> T.pack filePath) onProgress
    collectGhciResult process addLines projectRoot


-- | Execute @:unadd@ for the given module and return the assembled
-- 'LoadResult'. Progress events fire live via @onProgress@ as compilation
-- proceeds.
unaddGhci
    :: (Conc :> es, Concurrent :> es, File :> es, IOE :> es)
    => GhciProcess
    -> Text -- the module name to :unadd
    -> FilePath -- projectRoot
    -> (GhciLoading -> Eff es ())
    -> Eff es LoadResult
unaddGhci process moduleName projectRoot onProgress = do
    unaddLines <- execGhci process (":unadd " <> moduleName) onProgress
    collectGhciResult process unaddLines projectRoot
