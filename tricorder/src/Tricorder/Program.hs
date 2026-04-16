module Tricorder.Program (run) where

import Data.Aeson (encode)
import Data.Time.Format (defaultTimeLocale, formatTime)
import Data.Time.LocalTime (getCurrentTimeZone, utcToLocalTime)
import Effectful (IOE)
import Effectful.Reader.Static (Reader, ask, asks)

import Data.ByteString.Lazy qualified as BSL

import Atelier.Effects.Cache (Cache)
import Atelier.Effects.Clock (Clock)
import Atelier.Effects.Conc (Conc)
import Atelier.Effects.Console (Console)
import Atelier.Effects.Delay (Delay)
import Atelier.Effects.File (File)
import Atelier.Effects.FileSystem
    ( FileSystem
    , doesFileExist
    , getCurrentDirectory
    , readFileLbs
    )
import Atelier.Effects.Monitoring.Tracing (Tracing)
import Atelier.Effects.Posix.Process (Process)
import Atelier.Time (Millisecond)
import Tricorder.Arguments (Command (..))
import Tricorder.BuildState
    ( BuildPhase (..)
    , BuildResult (..)
    , BuildState (..)
    , DaemonInfo (..)
    , Diagnostic (..)
    , Severity (..)
    , TestOutcome (..)
    , TestRun (..)
    )
import Tricorder.Config (Config)
import Tricorder.Daemon (startDaemon, stopDaemon)
import Tricorder.Effects.Brick (Brick)
import Tricorder.Effects.BrickChan (BrickChan)
import Tricorder.Effects.BuildStore (BuildStore)
import Tricorder.Effects.FileWatcher (FileWatcher)
import Tricorder.Effects.GhcPkg (GhcPkg)
import Tricorder.Effects.GhciSession (GhciSession)
import Tricorder.Effects.TestRunner (TestRunner)
import Tricorder.Effects.UnixSocket (UnixSocket)
import Tricorder.GhcPkg.Types (ModuleName, PackageId)
import Tricorder.Render (diagnosticBlock, diagnosticLine, formatDuration, renderSourceResults)
import Tricorder.Socket.Client
    ( isDaemonRunning
    , querySource
    , queryStatus
    , queryStatusWait
    )
import Tricorder.Socket.SocketPath (SocketPath, socketPath)
import Tricorder.Watch (watchDisplay)

import Atelier.Effects.Console qualified as Console
import Atelier.Effects.Delay qualified as Delay
import Atelier.Effects.File qualified as File
import Atelier.Effects.Log qualified as Log
import Tricorder.Observability qualified as Observability


run
    :: ( Brick :> es
       , BrickChan :> es
       , BuildStore :> es
       , Cache (PackageId, ModuleName) Text :> es
       , Cache ModuleName PackageId :> es
       , Clock :> es
       , Conc :> es
       , Console :> es
       , Delay :> es
       , File :> es
       , FileSystem :> es
       , FileWatcher :> es
       , GhcPkg :> es
       , GhciSession :> es
       , IOE :> es
       , Log.Log :> es
       , Process :> es
       , Reader Command :> es
       , Reader Config :> es
       , Reader Observability.Config :> es
       , Reader SocketPath :> es
       , TestRunner :> es
       , Tracing :> es
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


start
    :: ( BuildStore :> es
       , Cache (PackageId, ModuleName) Text :> es
       , Cache ModuleName PackageId :> es
       , Clock :> es
       , Conc :> es
       , Console :> es
       , Delay :> es
       , FileSystem :> es
       , FileWatcher :> es
       , GhcPkg :> es
       , GhciSession :> es
       , IOE :> es
       , Log.Log :> es
       , Process :> es
       , Reader Config :> es
       , Reader Observability.Config :> es
       , Reader SocketPath :> es
       , TestRunner :> es
       , Tracing :> es
       , UnixSocket :> es
       )
    => Eff es ()
start = do
    projectRoot <- getCurrentDirectory
    sp <- socketPath projectRoot
    running <- isDaemonRunning sp
    if running then
        Console.putStrLn "Daemon already running."
    else do
        startDaemon
        Console.putStrLn "Daemon started."


stop :: (Console :> es, FileSystem :> es, Reader SocketPath :> es) => Eff es ()
stop = do
    stopDaemon
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
    if not running then
        Console.putStrLn "Stopped."
    else do
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
       , Delay :> es
       , File :> es
       , FileSystem :> es
       , Reader Observability.Config :> es
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
            asks @Observability.Config (.logFile)
    case mLogFile of
        Nothing ->
            Console.putStrLn "No log file configured. Add `log_file: /path/to/tricorder.log` to .tricorder.yaml"
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
                Delay.wait (200 :: Millisecond)
                loop h
            False -> do
                File.hGetLine h >>= Console.putTextLn
                loop h


watch
    :: ( Brick :> es
       , BrickChan :> es
       , BuildStore :> es
       , Cache (PackageId, ModuleName) Text :> es
       , Cache ModuleName PackageId :> es
       , Clock :> es
       , Conc :> es
       , Delay :> es
       , File :> es
       , FileSystem :> es
       , FileWatcher :> es
       , GhcPkg :> es
       , GhciSession :> es
       , IOE :> es
       , Log.Log :> es
       , Process :> es
       , Reader Config :> es
       , Reader Observability.Config :> es
       , Reader SocketPath :> es
       , TestRunner :> es
       , Tracing :> es
       , UnixSocket :> es
       )
    => Eff es ()
watch = do
    projectRoot <- getCurrentDirectory
    sockPath <- socketPath projectRoot
    running <- isDaemonRunning sockPath
    unless running $ do
        startDaemon
        waitForSocket sockPath
    watchDisplay sockPath


showSource
    :: ( BuildStore :> es
       , Cache (PackageId, ModuleName) Text :> es
       , Cache ModuleName PackageId :> es
       , Clock :> es
       , Conc :> es
       , Console :> es
       , Delay :> es
       , File :> es
       , FileSystem :> es
       , FileWatcher :> es
       , GhcPkg :> es
       , GhciSession :> es
       , IOE :> es
       , Log.Log :> es
       , Process :> es
       , Reader Config :> es
       , Reader Observability.Config :> es
       , Reader SocketPath :> es
       , TestRunner :> es
       , Tracing :> es
       , UnixSocket :> es
       )
    => [ModuleName]
    -> Eff es ()
showSource moduleNames = do
    projectRoot <- getCurrentDirectory
    sockPath <- socketPath projectRoot
    running <- isDaemonRunning sockPath
    unless running $ do
        startDaemon
        waitForSocket sockPath
    result <- querySource sockPath moduleNames
    case result of
        Left err -> Console.putTextLn $ "Error: " <> err
        Right results -> renderSourceResults results


-- | Poll until the daemon socket becomes connectable.
waitForSocket :: (Delay :> es, UnixSocket :> es) => FilePath -> Eff es ()
waitForSocket sockPath = do
    Delay.wait (200 :: Millisecond)
    running <- isDaemonRunning sockPath
    unless running $ waitForSocket sockPath
