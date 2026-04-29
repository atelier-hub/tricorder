module Tricorder (run) where

import Effectful (IOE)
import Effectful.Reader.Static (Reader, ask, asks)

import Atelier.Effects.Client (Client)
import Atelier.Effects.Clock (Clock)
import Atelier.Effects.Conc (Conc)
import Atelier.Effects.Console (Console)
import Atelier.Effects.Debounce (Debounce)
import Atelier.Effects.Delay (Delay)
import Atelier.Effects.Exit (Exit)
import Atelier.Effects.FileSystem (FileSystem)
import Atelier.Effects.FileWatcher (FileWatcher)
import Atelier.Effects.Handler (Handler)
import Atelier.Effects.Log (Log)
import Atelier.Effects.Monitoring.Tracing (Tracing)
import Atelier.Effects.Posix.Daemons (Daemons)
import Tricorder.Arguments (Command (..))
import Tricorder.BuildState (BuildState (..), DaemonInfo (..))
import Tricorder.CLI (showLog, showSource, showStatus)
import Tricorder.Config (Config)
import Tricorder.Daemon (startDaemon, stopDaemon, waitForDaemon)
import Tricorder.Effects.Brick (Brick)
import Tricorder.Effects.BrickChan (BrickChan)
import Tricorder.Effects.BuildStore (BuildStore)
import Tricorder.Effects.GhciSession (GhciSession)
import Tricorder.Effects.TestRunner (TestRunner)
import Tricorder.Effects.UnixSocket (UnixSocket)
import Tricorder.Runtime (PidFile (..), SocketPath (..))
import Tricorder.Socket.Client (isDaemonRunning, queryStatus)
import Tricorder.Socket.Protocol (Request)
import Tricorder.UI (viewUi)

import Atelier.Effects.Console qualified as Console
import Atelier.Effects.FileSystem qualified as FileSystem
import Tricorder.Observability qualified as Observability


run
    :: ( Brick :> es
       , BrickChan :> es
       , BuildStore :> es
       , Client Request :> es
       , Clock :> es
       , Conc :> es
       , Console :> es
       , Daemons :> es
       , Debounce FilePath :> es
       , Delay :> es
       , Exit :> es
       , FileSystem :> es
       , FileWatcher :> es
       , GhciSession :> es
       , Handler Request :> es
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
        Start -> do
            running <- isDaemonRunning
            if running then
                Console.putStrLn "Daemon already running."
            else do
                startDaemon
                Console.putStrLn "Daemon started."
        Stop -> do
            stopDaemon
            Console.putStrLn "Daemon stopped."
            FileSystem.removeFile =<< asks getSocketPath
            FileSystem.removeFile =<< asks getPidFile
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
                    result <- queryStatus
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
