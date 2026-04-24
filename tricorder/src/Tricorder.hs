module Tricorder (run) where

import Effectful (IOE)
import Effectful.Reader.Static (Reader, ask, asks)
import Effectful.Timeout (Timeout)

import Data.Text qualified as T

import Atelier.Effects.Cache (Cache)
import Atelier.Effects.Clock (Clock)
import Atelier.Effects.Conc (Conc)
import Atelier.Effects.Console (Console)
import Atelier.Effects.Debounce (Debounce)
import Atelier.Effects.Delay (Delay)
import Atelier.Effects.Exit (Exit)
import Atelier.Effects.FileSystem (FileSystem)
import Atelier.Effects.FileWatcher (FileWatcher)
import Atelier.Effects.Log (Log)
import Atelier.Effects.Monitoring.Tracing (Tracing)
import Atelier.Effects.Posix.Daemons (Daemons)
import Atelier.Effects.Publishing (Pub, Sub)
import Tricorder.Arguments (Command (..))
import Tricorder.BuildState (BuildState (..), DaemonInfo (..))
import Tricorder.CLI (showLog, showSource, showStatus)
import Tricorder.Config (Config)
import Tricorder.Daemon (startDaemon, stopDaemon, waitForDaemon)
import Tricorder.Effects.Brick (Brick)
import Tricorder.Effects.BrickChan (BrickChan)
import Tricorder.Effects.BuildStore (BuildStore)
import Tricorder.Effects.GhcPkg (GhcPkg)
import Tricorder.Effects.GhciSession (GhciSession)
import Tricorder.Effects.TestRunner (TestRunner)
import Tricorder.GhcPkg.Types (ModuleName, PackageId)
import Tricorder.Runtime (PidFile (..))
import Tricorder.UI (viewUi)
import Tricorder.Web.Server (ShutdownRequested)

import Atelier.Effects.Console qualified as Console
import Tricorder.Observability qualified as Observability
import Tricorder.Web.Client qualified as Web
import Tricorder.Web.Config qualified as Web


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
       , Exit :> es
       , FileSystem :> es
       , FileWatcher :> es
       , GhcPkg :> es
       , GhciSession :> es
       , IOE :> es
       , Log :> es
       , Pub ShutdownRequested :> es
       , Reader Command :> es
       , Reader Config :> es
       , Reader Observability.Config :> es
       , Reader PidFile :> es
       , Reader Web.Config :> es
       , Sub ShutdownRequested :> es
       , TestRunner :> es
       , Timeout :> es
       , Tracing :> es
       , Web.Client :> es
       )
    => Eff es ()
run =
    ask >>= \case
        Start -> do
            running <- Web.isDaemonRunning
            if running then
                Console.putStrLn "Daemon already running."
            else do
                startDaemon
                Console.putStrLn "Daemon started."
        Stop -> do
            running <- Web.isDaemonRunning
            when running
                $ stopDaemon >>= \case
                    Left reasons ->
                        Console.putTextLn
                            $ T.intercalate "\n"
                            $ "Was unable to stop the daemon:" : reasons
                    Right result -> do
                        Console.putTextLn result
        Status opts -> do
            running <- Web.isDaemonRunning
            if not running then
                Console.putStrLn "Stopped."
            else
                showStatus opts
        Log followMode -> do
            running <- Web.isDaemonRunning
            mLogFile <-
                if running then do
                    result <- Web.queryStatus
                    pure $ case result of
                        Right state -> state.daemonInfo.logFile
                        Left _ -> Nothing
                else
                    asks @Observability.Config (.logFile)
            showLog mLogFile followMode
        UI -> do
            Console.putStrLn "check running"
            running <- Web.isDaemonRunning
            unless running do
                Console.putStrLn "starting"
                startDaemon
                Console.putStrLn "stat initiated"
                waitForDaemon
                Console.putStrLn "started"
            viewUi
        Source moduleNames -> do
            running <- Web.isDaemonRunning
            unless running $ do
                startDaemon
                waitForDaemon
            showSource moduleNames
