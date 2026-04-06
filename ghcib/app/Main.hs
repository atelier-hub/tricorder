module Main (main) where

import Control.Concurrent (threadDelay)
import Data.Aeson (encode)
import Data.Time.Format (defaultTimeLocale, formatTime)
import Data.Time.LocalTime (getCurrentTimeZone, utcToLocalTime)
import Effectful (runEff)
import Options.Applicative
import System.Directory (getCurrentDirectory)

import Data.ByteString.Lazy qualified as BSL

import Atelier.Effects.Clock (runClock)
import Ghcib.BuildState (BuildPhase (..), BuildResult (..), BuildState (..), Diagnostic (..), Severity (..))
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


commandParser :: Parser Command
commandParser =
    hsubparser
        ( command "start" (info (pure Start) (progDesc "Start the daemon (no-op if already running)"))
            <> command "stop" (info (pure Stop) (progDesc "Stop the daemon"))
            <> command "status" (info statusParser (progDesc "Print build diagnostics (--json for machine-readable output)"))
            <> command "watch" (info (pure Watch) (progDesc "Auto-refreshing terminal display"))
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
run Start = do
    projectRoot <- getCurrentDirectory
    sockPath <- socketPath projectRoot
    running <- runEff $ runUnixSocketIO $ isDaemonRunning sockPath
    if running then
        putStrLn "Daemon already running."
    else do
        startDaemon projectRoot
        putStrLn "Daemon started."
run Stop = do
    projectRoot <- getCurrentDirectory
    stopDaemon projectRoot
    putStrLn "Daemon stopped."
run (Status waitFlag jsonFlag) = do
    projectRoot <- getCurrentDirectory
    sockPath <- socketPath projectRoot
    runEff $ runUnixSocketIO $ do
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
run Watch = do
    projectRoot <- getCurrentDirectory
    sockPath <- socketPath projectRoot
    runEff $ runClock $ runUnixSocketIO $ runDisplayIO $ do
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


-- | Poll until the daemon socket becomes connectable.
waitForSocket :: FilePath -> IO ()
waitForSocket sockPath = do
    threadDelay 200_000 -- 200ms
    running <- runEff $ runUnixSocketIO $ isDaemonRunning sockPath
    unless running $ waitForSocket sockPath
