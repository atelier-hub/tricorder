module Ghcib.Program (run) where

import Control.Concurrent (threadDelay)
import Data.Aeson (encode)
import Data.Time.Format (defaultTimeLocale, formatTime)
import Data.Time.LocalTime (getCurrentTimeZone, utcToLocalTime)
import Effectful (IOE, runEff)
import Effectful.Reader.Static (Reader, ask)

import Data.ByteString.Lazy qualified as BSL

import Atelier.Effects.Clock (Clock)
import Atelier.Effects.Console (Console)
import Atelier.Effects.File (File)
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
    , TestOutcome (..)
    , TestRun (..)
    )
import Ghcib.Config (loadConfig)
import Ghcib.Daemon (startDaemon, stopDaemon)
import Ghcib.Effects.Display (Display)
import Ghcib.Effects.UnixSocket (UnixSocket, runUnixSocketIO)
import Ghcib.GhcPkg.Types (ModuleName)
import Ghcib.Render (diagnosticBlock, diagnosticLine, formatDuration, renderSourceResults)
import Ghcib.Socket.Client
    ( isDaemonRunning
    , querySource
    , queryStatus
    , queryStatusWait
    , socketPath
    )
import Ghcib.Watch (watchDisplay)

import Atelier.Effects.Console qualified as Console
import Atelier.Effects.File qualified as File
import Ghcib.Config qualified as Config


run
    :: ( Clock :> es
       , Console :> es
       , Display :> es
       , File :> es
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
        (Source moduleNames) -> showSource moduleNames


start :: (Console :> es, FileSystem :> es, IOE :> es, UnixSocket :> es) => Eff es ()
start = do
    projectRoot <- getCurrentDirectory
    sp <- socketPath projectRoot
    running <- isDaemonRunning sp
    if running then
        Console.putStrLn "Daemon already running."
    else do
        liftIO $ startDaemon projectRoot
        Console.putStrLn "Daemon started."


stop :: (Console :> es, FileSystem :> es, IOE :> es) => Eff es ()
stop = do
    projectRoot <- getCurrentDirectory
    liftIO $ stopDaemon projectRoot
    Console.putStrLn "Daemon stopped."


showStatus
    :: ( Console :> es
       , File :> es
       , FileSystem :> es
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
            Right BuildState {phase = Building} -> Console.putStrLn "Building..."
            Right BuildState {phase = Testing} -> Console.putStrLn "Testing..."
            _ -> pure ()
    result <-
        if waitFlag then
            queryStatusWait sockPath
        else
            queryStatus sockPath
    case result of
        Left err -> Console.putTextLn $ "Error: " <> err
        Right state ->
            if jsonFlag then do
                Console.putStr $ BSL.toStrict $ encode state
                Console.putStrLn ""
            else
                renderText verboseFlag state
  where
    renderText verbose state = case state.phase of
        Building -> Console.putStrLn "Building..."
        Testing -> Console.putStrLn "Testing..."
        Done r -> do
            tz <- liftIO getCurrentTimeZone
            let printDiag =
                    if verbose then
                        Console.putText . diagnosticBlock
                    else
                        Console.putTextLn . diagnosticLine
            mapM_ printDiag r.diagnostics
            Console.putTextLn $ buildSummary tz r
            mapM_ (printTestRun verbose) r.testRuns
            when (buildHasErrors r || testsFailed r) $ liftIO exitFailure

    printTestRun verbose tr = do
        Console.putTextLn $ testRunSummary tr.target tr.outcome
        when verbose
            $ mapM_ (Console.putTextLn . ("  " <>) . toText) (lines tr.output)
      where
        testRunSummary t TestsPassed = t <> "  passed"
        testRunSummary t TestsFailed = t <> "  failed"
        testRunSummary t (TestsError msg) = t <> "  error: " <> msg

    buildHasErrors r = any ((== SError) . (.severity)) r.diagnostics
    testsFailed r = any ((/= TestsPassed) . (.outcome)) r.testRuns

    buildSummary tz r =
        let errs = length $ filter ((== SError) . (.severity)) r.diagnostics
            warns = length $ filter ((== SWarning) . (.severity)) r.diagnostics
            ts = toText $ "— " <> formatTime defaultTimeLocale "%H:%M:%S" (utcToLocalTime tz r.completedAt)
            stats = toText $ "(" <> show r.moduleCount <> " modules, " <> formatDuration r.durationMs <> ")"
        in  if null r.diagnostics then
                "All good. " <> stats <> " " <> ts
            else
                show errs <> " error(s), " <> show warns <> " warning(s) " <> stats <> " " <> ts


showLog
    :: ( Console :> es
       , File :> es
       , FileSystem :> es
       , IOE :> es
       , UnixSocket :> es
       )
    => Bool -> Eff es ()
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
            Console.putStrLn "No log file configured. Add `log_file = \"/path/to/ghcib.log\"` to .ghcib.toml"
        Just path -> do
            exists <- doesFileExist path
            if not exists then
                Console.putTextLn $ "Log file does not exist yet: " <> toText path
            else
                if followFlag then
                    followLog path
                else
                    readFileLbs path >>= Console.putStr . BSL.toStrict
  where
    followLog path = File.withFile path ReadMode loop
    loop h =
        File.hIsEOF h >>= \case
            True -> do
                liftIO $ threadDelay 200_000 -- 200 milliseconds
                loop h
            False -> do
                File.hGetLine h >>= Console.putTextLn
                loop h


watch
    :: ( Clock :> es
       , Display :> es
       , File :> es
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


showSource
    :: ( Console :> es
       , File :> es
       , FileSystem :> es
       , IOE :> es
       , UnixSocket :> es
       )
    => [ModuleName]
    -> Eff es ()
showSource moduleNames = do
    projectRoot <- getCurrentDirectory
    sockPath <- socketPath projectRoot
    running <- isDaemonRunning sockPath
    unless running $ liftIO $ startDaemon projectRoot >> waitForSocket sockPath
    result <- querySource sockPath moduleNames
    case result of
        Left err -> Console.putTextLn $ "Error: " <> err
        Right results -> renderSourceResults results


-- | Poll until the daemon socket becomes connectable.
waitForSocket :: FilePath -> IO ()
waitForSocket sockPath = do
    threadDelay 200_000 -- 200ms
    running <- runEff $ runUnixSocketIO $ isDaemonRunning sockPath
    unless running $ waitForSocket sockPath
