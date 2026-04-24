module Tricorder.CLI
    ( showLog
    , showSource
    , showStatus
    ) where

import Data.Aeson (encode)
import Data.Time.Format (defaultTimeLocale, formatTime)
import Data.Time.LocalTime (utcToLocalTime)

import Data.ByteString.Lazy qualified as BSL

import Atelier.Effects.Clock (Clock, currentTimeZone)
import Atelier.Effects.Console (Console)
import Atelier.Effects.Delay (Delay)
import Atelier.Effects.Exit (Exit, exitFailure)
import Atelier.Effects.FileSystem (FileSystem, doesFileExist, followFile, readFileLbs)
import Tricorder.Arguments
    ( FollowMode (..)
    , OutputFormat (..)
    , StatusOptions (..)
    , Verbosity (..)
    , WaitMode (..)
    )
import Tricorder.BuildState
    ( BuildPhase (..)
    , BuildResult (..)
    , BuildState (..)
    , Diagnostic (..)
    , Severity (..)
    , TestOutcome (..)
    , TestRun (..)
    )
import Tricorder.CLI.Render
    ( diagnosticLineIndexed
    , formatDuration
    , renderSourceResults
    )
import Tricorder.GhcPkg.Types (ModuleName)
import Tricorder.Web.Client
    ( querySource
    , queryStatus
    , queryStatusWait
    )

import Atelier.Effects.Console qualified as Console
import Tricorder.Web.Client qualified as Web


showStatus
    :: ( Clock :> es
       , Console :> es
       , Exit :> es
       , Web.Client :> es
       )
    => StatusOptions -> Eff es ()
showStatus opts = do
    when (opts.wait == WaitForBuild && opts.format == TextOutput) $ do
        current <- queryStatus
        case current of
            Right BuildState {phase = Building _} -> Console.putStrLn "Building..."
            Right BuildState {phase = Restarting} -> Console.putStrLn "Restarting..."
            Right BuildState {phase = Testing _} -> Console.putStrLn "Testing..."
            _ -> pure ()
    result <-
        case opts.wait of
            WaitForBuild -> queryStatusWait
            ShowCurrent -> queryStatus
    case result of
        Left err -> Console.putTextLn $ "Error: " <> err
        Right state ->
            case opts.format of
                JsonOutput -> do
                    Console.putStr $ BSL.toStrict $ encode state
                    Console.putStrLn ""
                TextOutput ->
                    renderText opts.verbosity opts.expand state
  where
    renderText verbosity expand state = case state.phase of
        Building _ -> Console.putStrLn "Building..."
        Restarting -> Console.putStrLn "Restarting..."
        Testing _ -> Console.putStrLn "Testing..."
        Done r -> do
            tz <- currentTimeZone
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
                    let printDiag (i, d) = case verbosity of
                            Verbose -> do
                                Console.putTextLn $ diagnosticLineIndexed i d
                                Console.putText d.text
                            Concise ->
                                Console.putTextLn $ diagnosticLineIndexed i d
                    mapM_ printDiag (zip [1 ..] r.diagnostics)
                    Console.putTextLn $ buildSummary tz r
                    mapM_ (printTestRun verbosity) r.testRuns
                    when (buildHasErrors r || testsFailed r) exitFailure

    printTestRun verbosity tr = do
        Console.putTextLn $ testRunSummary tr.target tr.outcome
        when (verbosity == Verbose)
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
       , Delay :> es
       , FileSystem :> es
       )
    => Maybe FilePath -> FollowMode -> Eff es ()
showLog mLogFile followMode = case mLogFile of
    Nothing ->
        Console.putStrLn "No log file configured. Add `log_file: /path/to/tricorder.log` to .tricorder.yaml"
    Just path -> do
        exists <- doesFileExist path
        if not exists then
            Console.putTextLn $ "Log file does not exist yet: " <> toText path
        else case followMode of
            Follow -> followFile path Console.putStr
            NoFollow -> readFileLbs path >>= Console.putStr . BSL.toStrict


showSource
    :: ( Console :> es
       , Web.Client :> es
       )
    => [ModuleName]
    -> Eff es ()
showSource moduleNames = do
    result <- querySource moduleNames
    case result of
        Left err -> Console.putTextLn $ "Error: " <> err
        Right results -> renderSourceResults results
