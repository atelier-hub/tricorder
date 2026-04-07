module Main (main) where

import Control.Concurrent (threadDelay)
import Data.Aeson (encode)
import Data.Time.Format (defaultTimeLocale, formatTime)
import Data.Time.LocalTime (getCurrentTimeZone, utcToLocalTime)
import Effectful (IOE, runEff)
import Options.Applicative
import System.IO (hGetLine)

import Data.ByteString.Lazy qualified as BSL

import Atelier.Effects.Clock (Clock, runClock)
import Atelier.Effects.FileSystem (FileSystem, doesFileExist, getCurrentDirectory, readFileLbs, runFileSystemIO)
import Ghcib.BuildState (BuildPhase (..), BuildResult (..), BuildState (..), DaemonInfo (..), Diagnostic (..), Severity (..))
import Ghcib.Config (loadConfig)
import Ghcib.Daemon (startDaemon, stopDaemon)
import Ghcib.Effects.Display (Display, runDisplayIO)
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


main :: IO ()
main = do
    cmd <- execParser opts
    runEff . runFileSystemIO . runClock . runUnixSocketIO . runDisplayIO $ run cmd
  where
    opts =
        info (commandParser <**> helper)
            $ fullDesc
                <> progDesc "ghcib — daemon-based GHCi build status"
                <> header "ghcib — robust GHCi daemon with structured querying"


data Command
    = Start
    | Stop
    | Status Bool Bool Bool
    | Watch
    | Log Bool


commandParser :: Parser Command
commandParser =
    hsubparser
        ( command "start" (info (pure Start) (progDesc "Start the daemon (no-op if already running)"))
            <> command "stop" (info (pure Stop) (progDesc "Stop the daemon"))
            <> command "status" (info statusParser (progDesc "Print build diagnostics (--json for machine-readable output)"))
            <> command "watch" (info (pure Watch) (progDesc "Auto-refreshing terminal display"))
            <> command "log" (info logParser (progDesc "Show daemon log output"))
        )


logParser :: Parser Command
logParser =
    Log
        <$> switch
            ( long "follow"
                <> short 'f'
                <> help "Keep streaming new log lines as they are written"
            )


statusParser :: Parser Command
statusParser =
    Status
        <$> switch
            ( long "wait"
                <> help "Block until the current build cycle completes"
            )
        <*> switch
            ( long "json"
                <> help "Output full build state as JSON"
            )
        <*> switch
            ( long "verbose"
                <> short 'v'
                <> help "Print full GHC message body under each diagnostic"
            )


run :: (Clock :> es, Display :> es, FileSystem :> es, IOE :> es, UnixSocket :> es) => Command -> Eff es ()
run Start = do
    projectRoot <- getCurrentDirectory
    sp <- socketPath projectRoot
    running <- isDaemonRunning sp
    liftIO
        $ if running then
            putStrLn "Daemon already running."
        else
            startDaemon projectRoot >> putStrLn "Daemon started."
run Stop = do
    projectRoot <- getCurrentDirectory
    liftIO $ stopDaemon projectRoot >> putStrLn "Daemon stopped."
run (Status waitFlag jsonFlag verboseFlag) = do
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
run (Log followFlag) = do
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
run Watch = do
    projectRoot <- getCurrentDirectory
    sockPath <- socketPath projectRoot
    running <- isDaemonRunning sockPath
    unless running $ liftIO $ startDaemon projectRoot >> waitForSocket sockPath
    watchDisplay sockPath


renderText :: Bool -> BuildState -> IO ()
renderText verbose state = case state.phase of
    Building -> putStrLn "Building..."
    Done r -> do
        tz <- getCurrentTimeZone
        let printDiag = if verbose then putStr . diagnosticBlock else putStrLn . diagnosticLine
        mapM_ printDiag r.diagnostics
        putStrLn $ buildSummary tz r
        when (any ((== SError) . (.severity)) r.diagnostics) exitFailure
  where
    buildSummary tz r =
        let errs = length $ filter ((== SError) . (.severity)) r.diagnostics
            warns = length $ filter ((== SWarning) . (.severity)) r.diagnostics
            ts = "— " <> formatTime defaultTimeLocale "%H:%M:%S" (utcToLocalTime tz r.completedAt)
            stats = "(" <> show r.moduleCount <> " modules, " <> formatDuration r.durationMs <> ")"
        in  if null r.diagnostics then
                "All good. " <> stats <> " " <> ts
            else
                show errs <> " error(s), " <> show warns <> " warning(s) " <> stats <> " " <> ts


followLog :: FilePath -> IO ()
followLog path = withFile path ReadMode loop
  where
    loop h =
        hIsEOF h >>= \case
            True -> threadDelay 200_000 >> loop h
            False -> hGetLine h >>= putStrLn >> loop h


-- | Poll until the daemon socket becomes connectable.
waitForSocket :: FilePath -> IO ()
waitForSocket sockPath = do
    threadDelay 200_000 -- 200ms
    running <- runEff $ runUnixSocketIO $ isDaemonRunning sockPath
    unless running $ waitForSocket sockPath
