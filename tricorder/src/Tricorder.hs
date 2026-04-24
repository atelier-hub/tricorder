module Tricorder (run) where

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
import Atelier.Effects.Debounce (Debounce)
import Atelier.Effects.Delay (Delay)
import Atelier.Effects.File (File)
import Atelier.Effects.FileSystem (FileSystem, doesFileExist, readFileLbs)
import Atelier.Effects.FileWatcher (FileWatcher)
import Atelier.Effects.Log (Log)
import Atelier.Effects.Monitoring.Tracing (Tracing)
import Atelier.Effects.Posix.Daemons (Daemons)
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
import Tricorder.Effects.GhcPkg (GhcPkg)
import Tricorder.Effects.GhciSession (GhciSession)
import Tricorder.Effects.TestRunner (TestRunner)
import Tricorder.Effects.UnixSocket (UnixSocket)
import Tricorder.GhcPkg.Types (ModuleName, PackageId)
import Tricorder.Render (diagnosticLineIndexed, formatDuration, renderSourceResults)
import Tricorder.Runtime (PidFile (..), SocketPath (..))
import Tricorder.Socket.Client
    ( isDaemonRunning
    , querySource
    , queryStatus
    , queryStatusWait
    )
import Tricorder.UI (viewUi)

import Atelier.Effects.Console qualified as Console
import Atelier.Effects.Delay qualified as Delay
import Atelier.Effects.File qualified as File
import Atelier.Effects.FileSystem qualified as FileSystem
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
       , Daemons :> es
       , Debounce FilePath :> es
       , Delay :> es
       , File :> es
       , FileSystem :> es
       , FileWatcher :> es
       , GhcPkg :> es
       , GhciSession :> es
       , IOE :> es
       , Log :> es
       , Reader Command :> es
       , Reader Config :> es
       , Reader Observability.Config :> es
       , Reader PidFile :> es
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
        (Status waitFlag jsonFlag verboseFlag expandFlag) -> showStatus waitFlag jsonFlag verboseFlag expandFlag
        (Log followFlag) -> showLog followFlag
        UI -> ui
        (Source moduleNames) -> showSource moduleNames


start
    :: ( BuildStore :> es
       , Cache (PackageId, ModuleName) Text :> es
       , Cache ModuleName PackageId :> es
       , Clock :> es
       , Conc :> es
       , Console :> es
       , Daemons :> es
       , Debounce FilePath :> es
       , Delay :> es
       , FileSystem :> es
       , FileWatcher :> es
       , GhcPkg :> es
       , GhciSession :> es
       , IOE :> es
       , Log :> es
       , Reader Config :> es
       , Reader Observability.Config :> es
       , Reader PidFile :> es
       , Reader SocketPath :> es
       , TestRunner :> es
       , Tracing :> es
       , UnixSocket :> es
       )
    => Eff es ()
start = do
    running <- isDaemonRunning
    if running then
        Console.putStrLn "Daemon already running."
    else do
        startDaemon
        Console.putStrLn "Daemon started."


stop
    :: ( Console :> es
       , Daemons :> es
       , FileSystem :> es
       , Reader PidFile :> es
       , Reader SocketPath :> es
       )
    => Eff es ()
stop = do
    stopDaemon
    Console.putStrLn "Daemon stopped."
    FileSystem.removeFile =<< asks getSocketPath
    FileSystem.removeFile =<< asks getPidFile


showStatus
    :: ( Console :> es
       , Daemons :> es
       , File :> es
       , IOE :> es
       , Reader PidFile :> es
       , Reader SocketPath :> es
       , UnixSocket :> es
       )
    => Bool -> Bool -> Bool -> Maybe Int -> Eff es ()
showStatus waitFlag jsonFlag verboseFlag expandFlag = do
    running <- isDaemonRunning
    if not running then
        Console.putStrLn "Stopped."
    else do
        SocketPath sockPath <- ask
        when (waitFlag && not jsonFlag) $ do
            current <- queryStatus sockPath
            case current of
                Right BuildState {phase = Building} -> Console.putStrLn "Building..."
                Right BuildState {phase = Restarting} -> Console.putStrLn "Restarting..."
                Right BuildState {phase = Testing _} -> Console.putStrLn "Testing..."
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
                    renderText verboseFlag expandFlag state
  where
    renderText verbose expand state = case state.phase of
        Building -> Console.putStrLn "Building..."
        Restarting -> Console.putStrLn "Restarting..."
        Testing _ -> Console.putStrLn "Testing..."
        Done r -> do
            tz <- liftIO getCurrentTimeZone
            case expand of
                Just n ->
                    case r.diagnostics !!? (n - 1) of
                        Nothing ->
                            Console.putTextLn
                                $ "No diagnostic #"
                                    <> show n
                                    <> " (current build has "
                                    <> show (length r.diagnostics)
                                    <> ")"
                        Just d -> do
                            Console.putTextLn $ diagnosticLineIndexed n d
                            Console.putText d.text
                Nothing -> do
                    let printDiag (i, d) =
                            if verbose then do
                                Console.putTextLn $ diagnosticLineIndexed i d
                                Console.putText d.text
                            else
                                Console.putTextLn $ diagnosticLineIndexed i d
                    mapM_ printDiag (zip [1 ..] r.diagnostics)
                    Console.putTextLn $ buildSummary tz r
                    mapM_ (printTestRun verbose) r.testRuns
                    when (buildHasErrors r || testsFailed r) $ liftIO exitFailure

    printTestRun verbose tr = do
        Console.putTextLn $ testRunSummary tr.target tr.outcome
        when verbose
            $ mapM_ (Console.putTextLn . ("  " <>) . toText) (lines tr.output)
      where
        testRunSummary t TestsRunning = t <> "  running..."
        testRunSummary t TestsPassed = t <> "  passed"
        testRunSummary t TestsFailed = t <> "  failed"
        testRunSummary t (TestsError msg) = t <> "  error: " <> msg

    buildHasErrors r = any ((== SError) . (.severity)) r.diagnostics
    testsFailed r = any (notPassed . (.outcome)) r.testRuns
      where
        notPassed TestsPassed = False
        notPassed TestsRunning = False
        notPassed _ = True

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
       , Daemons :> es
       , Delay :> es
       , File :> es
       , FileSystem :> es
       , Reader Observability.Config :> es
       , Reader PidFile :> es
       , Reader SocketPath :> es
       , UnixSocket :> es
       )
    => Bool -> Eff es ()
showLog followFlag = do
    running <- isDaemonRunning
    mLogFile <-
        if running then do
            SocketPath sp <- ask
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


ui
    :: ( Brick :> es
       , BrickChan :> es
       , BuildStore :> es
       , Cache (PackageId, ModuleName) Text :> es
       , Cache ModuleName PackageId :> es
       , Clock :> es
       , Conc :> es
       , Daemons :> es
       , Debounce FilePath :> es
       , Delay :> es
       , File :> es
       , FileSystem :> es
       , FileWatcher :> es
       , GhcPkg :> es
       , GhciSession :> es
       , IOE :> es
       , Log :> es
       , Reader Config :> es
       , Reader Observability.Config :> es
       , Reader PidFile :> es
       , Reader SocketPath :> es
       , TestRunner :> es
       , Tracing :> es
       , UnixSocket :> es
       )
    => Eff es ()
ui = do
    running <- isDaemonRunning
    unless running do
        startDaemon
        waitForDaemon
    viewUi


showSource
    :: ( BuildStore :> es
       , Cache (PackageId, ModuleName) Text :> es
       , Cache ModuleName PackageId :> es
       , Clock :> es
       , Conc :> es
       , Console :> es
       , Daemons :> es
       , Debounce FilePath :> es
       , Delay :> es
       , File :> es
       , FileSystem :> es
       , FileWatcher :> es
       , GhcPkg :> es
       , GhciSession :> es
       , IOE :> es
       , Log :> es
       , Reader Config :> es
       , Reader Observability.Config :> es
       , Reader PidFile :> es
       , Reader SocketPath :> es
       , TestRunner :> es
       , Tracing :> es
       , UnixSocket :> es
       )
    => [ModuleName]
    -> Eff es ()
showSource moduleNames = do
    running <- isDaemonRunning
    unless running $ do
        startDaemon
        waitForDaemon
    SocketPath sockPath <- ask
    result <- querySource sockPath moduleNames
    case result of
        Left err -> Console.putTextLn $ "Error: " <> err
        Right results -> renderSourceResults results


-- | Poll until the daemon socket becomes connectable.
waitForDaemon :: (Daemons :> es, Delay :> es, Reader PidFile :> es, UnixSocket :> es) => Eff es ()
waitForDaemon = do
    Delay.wait (200 :: Millisecond)
    running <- isDaemonRunning
    unless running waitForDaemon
