module Ghcib.Program (run) where

import Control.Concurrent (threadDelay)
import Data.Aeson (encode)
import Data.Time.Format (defaultTimeLocale, formatTime)
import Data.Time.LocalTime (getCurrentTimeZone, utcToLocalTime)
import Effectful (IOE, runEff)
import Effectful.Reader.Static (Reader, ask)
import System.IO (hGetLine)

import Data.ByteString.Lazy qualified as BSL

import Atelier.Effects.Clock (Clock)
import Atelier.Effects.FileSystem
    ( FileSystem
    , doesFileExist
    , getCurrentDirectory
    , readFileLbs
    )
import Ghcib.Arguments (Command (..))
import Ghcib.BuildState
    ( BuildPhase (..)
    , BuildResult (..)
    , BuildState (..)
    , DaemonInfo (..)
    , Diagnostic (..)
    , Severity (..)
    )
import Ghcib.Config (loadConfig)
import Ghcib.Daemon (startDaemon, stopDaemon)
import Ghcib.Effects.Display (Display)
import Ghcib.Effects.UnixSocket (UnixSocket, runUnixSocketIO)
import Ghcib.Render (diagnosticBlock, diagnosticLine, formatDuration)
import Ghcib.Socket.Client
    ( isDaemonRunning
    , queryStatus
    , queryStatusWait
    , socketPath
    )
import Ghcib.Watch (watchDisplay)

import Ghcib.Config qualified as Config


run
    :: ( Clock :> es
       , Display :> es
       , FileSystem :> es
       , IOE :> es
       , Reader Command :> es
       , UnixSocket :> es
       )
    => Eff es ()
run =
    ask >>= \case
        Start -> start
        Stop -> stop
        (Status waitFlag jsonFlag verboseFlag) -> showStatus waitFlag jsonFlag verboseFlag
        (Log followFlag) -> showLog followFlag
        Watch -> watch


start :: (FileSystem :> es, IOE :> es, UnixSocket :> es) => Eff es ()
start = do
    projectRoot <- getCurrentDirectory
    sp <- socketPath projectRoot
    running <- isDaemonRunning sp
    liftIO
        $ if running then
            putStrLn "Daemon already running."
        else
            startDaemon projectRoot >> putStrLn "Daemon started."


stop :: (FileSystem :> es, IOE :> es) => Eff es ()
stop = do
    projectRoot <- getCurrentDirectory
    liftIO $ stopDaemon projectRoot >> putStrLn "Daemon stopped."


showStatus
    :: ( FileSystem :> es
       , IOE :> es
       , UnixSocket :> es
       )
    => Bool -> Bool -> Bool -> Eff es ()
showStatus waitFlag jsonFlag verboseFlag = do
    projectRoot <- getCurrentDirectory
    sockPath <- socketPath projectRoot
    running <- isDaemonRunning sockPath
    unless running $ liftIO $ startDaemon projectRoot >> waitForSocket sockPath
    when (waitFlag && not jsonFlag) $ do
        current <- queryStatus sockPath
        case current of
            Right BuildState {phase = Building} -> liftIO $ putStrLn "Building..."
            _ -> pure ()
    result <-
        if waitFlag then
            queryStatusWait sockPath
        else
            queryStatus sockPath
    liftIO $ case result of
        Left err -> putStrLn $ "Error: " <> toString err
        Right state ->
            if jsonFlag then
                BSL.putStr (encode state) >> putStrLn ""
            else
                renderText verboseFlag state
  where
    renderText verbose state = case state.phase of
        Building -> putStrLn "Building..."
        Done r -> do
            tz <- getCurrentTimeZone
            let printDiag = if verbose then putStr . diagnosticBlock else putStrLn . diagnosticLine
            mapM_ printDiag r.diagnostics
            putStrLn $ buildSummary tz r
            when (any ((== SError) . (.severity)) r.diagnostics) exitFailure

    buildSummary tz r =
        let errs = length $ filter ((== SError) . (.severity)) r.diagnostics
            warns = length $ filter ((== SWarning) . (.severity)) r.diagnostics
            ts = "— " <> formatTime defaultTimeLocale "%H:%M:%S" (utcToLocalTime tz r.completedAt)
            stats = "(" <> show r.moduleCount <> " modules, " <> formatDuration r.durationMs <> ")"
        in  if null r.diagnostics then
                "All good. " <> stats <> " " <> ts
            else
                show errs <> " error(s), " <> show warns <> " warning(s) " <> stats <> " " <> ts


showLog :: (FileSystem :> es, IOE :> es, UnixSocket :> es) => Bool -> Eff es ()
showLog followFlag = do
    projectRoot <- getCurrentDirectory
    sp <- socketPath projectRoot
    running <- isDaemonRunning sp
    mLogFile <-
        if running then do
            result <- queryStatus sp
            pure $ case result of
                Right state -> state.daemonInfo.logFile
                Left _ -> Nothing
        else
            Config.logFile <$> loadConfig projectRoot
    case mLogFile of
        Nothing ->
            liftIO $ putStrLn "No log file configured. Add `log_file = \"/path/to/ghcib.log\"` to .ghcib.toml"
        Just path -> do
            exists <- doesFileExist path
            if not exists then
                liftIO $ putStrLn $ "Log file does not exist yet: " <> path
            else
                if followFlag then
                    liftIO $ followLog path
                else
                    readFileLbs path >>= liftIO . BSL.putStr
  where
    followLog path = withFile path ReadMode loop
    loop h =
        hIsEOF h >>= \case
            True -> threadDelay 200_000 >> loop h
            False -> hGetLine h >>= putStrLn >> loop h


watch
    :: ( Clock :> es
       , Display :> es
       , FileSystem :> es
       , IOE :> es
       , UnixSocket :> es
       )
    => Eff es ()
watch = do
    projectRoot <- getCurrentDirectory
    sockPath <- socketPath projectRoot
    running <- isDaemonRunning sockPath
    unless running $ liftIO $ startDaemon projectRoot >> waitForSocket sockPath
    watchDisplay sockPath


-- | Poll until the daemon socket becomes connectable.
waitForSocket :: FilePath -> IO ()
waitForSocket sockPath = do
    threadDelay 200_000 -- 200ms
    running <- runEff $ runUnixSocketIO $ isDaemonRunning sockPath
    unless running $ waitForSocket sockPath
