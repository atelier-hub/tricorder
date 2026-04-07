module Main (main) where

import Control.Concurrent (threadDelay)
import Data.Aeson (encode)
import Data.Time.Format (defaultTimeLocale, formatTime)
import Data.Time.LocalTime (getCurrentTimeZone, utcToLocalTime)
import Effectful (runEff)
import Options.Applicative
import System.IO (hGetLine)

import Data.ByteString.Lazy qualified as BSL

import Atelier.Effects.Clock (runClock)
import Atelier.Effects.FileSystem (doesFileExist, getCurrentDirectory, readFileLbs, runFileSystemIO)
import Ghcib.BuildState (BuildPhase (..), BuildResult (..), BuildState (..), DaemonInfo (..), Diagnostic (..), Severity (..))
import Ghcib.Config (loadConfig)
import Ghcib.Daemon (startDaemon, stopDaemon)
import Ghcib.Effects.Display (runDisplayIO)
import Ghcib.Effects.UnixSocket (runUnixSocketIO)
import Ghcib.Render (diagnosticLine, formatDuration)
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
    run cmd
  where
    opts =
        info (commandParser <**> helper)
            $ fullDesc
                <> progDesc "ghcib — daemon-based GHCi build status"
                <> header "ghcib — robust GHCi daemon with structured querying"


data Command
    = Start
    | Stop
    | Status Bool Bool
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


run :: Command -> IO ()
run Start =
    runEff . runFileSystemIO . runUnixSocketIO $ do
        projectRoot <- getCurrentDirectory
        sp <- socketPath projectRoot
        running <- isDaemonRunning sp
        liftIO
            $ if running then
                putStrLn "Daemon already running."
            else
                startDaemon projectRoot >> putStrLn "Daemon started."
run Stop =
    runEff . runFileSystemIO $ do
        projectRoot <- getCurrentDirectory
        liftIO $ stopDaemon projectRoot >> putStrLn "Daemon stopped."
run (Status waitFlag jsonFlag) =
    runEff . runFileSystemIO . runUnixSocketIO $ do
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
                    renderText state
run (Log followFlag) = do
    mLogFile <- runEff . runFileSystemIO . runUnixSocketIO $ do
        projectRoot <- getCurrentDirectory
        sp <- socketPath projectRoot
        running <- isDaemonRunning sp
        if running then do
            result <- queryStatus sp
            pure $ case result of
                Right state -> state.daemonInfo.logFile
                Left _ -> Nothing
        else
            Config.logFile <$> loadConfig projectRoot
    case mLogFile of
        Nothing ->
            putStrLn "No log file configured. Add `log_file = \"/path/to/ghcib.log\"` to .ghcib.toml"
        Just path -> do
            exists <- runEff . runFileSystemIO $ doesFileExist path
            if not exists then
                putStrLn $ "Log file does not exist yet: " <> path
            else
                if followFlag then
                    followLog path
                else
                    runEff (runFileSystemIO (readFileLbs path)) >>= BSL.putStr
run Watch =
    runEff . runFileSystemIO . runClock . runUnixSocketIO . runDisplayIO $ do
        projectRoot <- getCurrentDirectory
        sockPath <- socketPath projectRoot
        running <- isDaemonRunning sockPath
        unless running $ liftIO $ startDaemon projectRoot >> waitForSocket sockPath
        watchDisplay sockPath


renderText :: BuildState -> IO ()
renderText state = case state.phase of
    Building -> putStrLn "Building..."
    Done r -> do
        tz <- getCurrentTimeZone
        mapM_ (putStrLn . diagnosticLine) r.diagnostics
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
