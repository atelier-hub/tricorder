module Main (main) where

import Control.Concurrent (threadDelay)
import Data.Aeson (encode)
import Effectful (runEff)
import Options.Applicative
import System.Directory (getCurrentDirectory)

import Data.ByteString.Lazy qualified as BSL

import Ghcib.Daemon (startDaemon, stopDaemon)
import Ghcib.Effects.Display (runDisplayIO)
import Ghcib.Effects.UnixSocket (runUnixSocketIO)
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
    | Status Bool
    | Watch


commandParser :: Parser Command
commandParser =
    hsubparser
        ( command "start" (info (pure Start) (progDesc "Start the daemon (no-op if already running)"))
            <> command "stop" (info (pure Stop) (progDesc "Stop the daemon"))
            <> command "status" (info statusParser (progDesc "Print current build state as JSON"))
            <> command "watch" (info (pure Watch) (progDesc "Auto-refreshing terminal display"))
        )


statusParser :: Parser Command
statusParser =
    Status
        <$> switch
            ( long "wait"
                <> help "Block until the current build cycle completes"
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
run (Status waitFlag) = do
    projectRoot <- getCurrentDirectory
    sockPath <- socketPath projectRoot
    runEff $ runUnixSocketIO $ do
        running <- isDaemonRunning sockPath
        unless running $ liftIO $ startDaemon projectRoot >> waitForSocket sockPath
        result <-
            if waitFlag then
                queryStatusWait sockPath
            else
                queryStatus sockPath
        liftIO $ case result of
            Left err -> putStrLn $ "Error: " <> toString err
            Right state -> BSL.putStr (encode state) >> putStrLn ""
run Watch = do
    projectRoot <- getCurrentDirectory
    sockPath <- socketPath projectRoot
    runEff $ runUnixSocketIO $ runDisplayIO $ do
        running <- isDaemonRunning sockPath
        unless running $ liftIO $ startDaemon projectRoot >> waitForSocket sockPath
        watchDisplay sockPath


-- | Poll until the daemon socket becomes connectable.
waitForSocket :: FilePath -> IO ()
waitForSocket sockPath = do
    threadDelay 200_000 -- 200ms
    running <- runEff $ runUnixSocketIO $ isDaemonRunning sockPath
    unless running $ waitForSocket sockPath
