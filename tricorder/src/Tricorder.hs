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
import Atelier.Effects.File (File)
import Atelier.Effects.FileSystem (FileSystem)
import Atelier.Effects.FileWatcher (FileWatcher)
import Atelier.Effects.Log (Log)
import Atelier.Effects.Monitoring.Tracing (Tracing)
import Atelier.Effects.Posix.Daemons (Daemons)
import Tricorder.Arguments (Command (..))
import Tricorder.BuildState (BuildState (..), DaemonInfo (..))
import Tricorder.CLI (showLog, showSource, showStatus)
import Tricorder.Daemon (startDaemon, stopDaemon, waitForDaemon)
import Tricorder.Effects.Brick (Brick)
import Tricorder.Effects.BrickChan (BrickChan)
import Tricorder.Effects.BuildStore (BuildStore)
import Tricorder.Effects.GhcPkg (GhcPkg)
import Tricorder.Effects.GhciSession (GhciSession)
import Tricorder.Effects.TestRunner (TestRunner)
import Tricorder.Effects.UnixSocket (UnixSocket)
import Tricorder.GhcPkg.Types (ModuleName, PackageId)
import Tricorder.Session.BuildCommand (BuildCommand)
import Tricorder.Session.PidFile (PidFile)
import Tricorder.Session.ProjectRoot (ProjectRoot)
import Tricorder.Session.SocketPath (SocketPath (..))
import Tricorder.Session.TestTargets (TestTargets)
import Tricorder.Session.WatchDirs (WatchDirs)
import Tricorder.Socket.Client (isDaemonRunning, queryStatus)
import Tricorder.UI (viewUi)

import Atelier.Effects.Console qualified as Console
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
       , Exit :> es
       , File :> es
       , FileSystem :> es
       , FileWatcher :> es
       , GhcPkg :> es
       , GhciSession :> es
       , IOE :> es
       , Log :> es
       , Reader BuildCommand :> es
       , Reader Command :> es
       , Reader Observability.Config :> es
       , Reader PidFile :> es
       , Reader ProjectRoot :> es
       , Reader SocketPath :> es
       , Reader TestTargets :> es
       , Reader WatchDirs :> es
       , TestRunner :> es
       , Timeout :> es
       , Tracing :> es
       , UnixSocket :> es
       )
    => Eff es ()
run =
    ask >>= \case
        Start -> do
            running <- isDaemonRunning
            if running then
                Console.putStrLn "Daemon already running."
            else do
                startDaemon
                Console.putStrLn "Daemon started."
        Stop -> do
            running <- isDaemonRunning
            when running
                $ stopDaemon >>= \case
                    Left reasons ->
                        Console.putTextLn
                            $ T.intercalate "\n"
                            $ "Was unable to stop the daemon:" : reasons
                    Right result -> do
                        Console.putTextLn result
        Status opts -> do
            running <- isDaemonRunning
            if not running then
                Console.putStrLn "Stopped."
            else
                showStatus opts
        Log followMode -> do
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
            showLog mLogFile followMode
        UI -> do
            running <- isDaemonRunning
            unless running do
                startDaemon
                waitForDaemon
            viewUi
        Source moduleNames -> do
            running <- isDaemonRunning
            unless running $ do
                startDaemon
                waitForDaemon
            showSource moduleNames
