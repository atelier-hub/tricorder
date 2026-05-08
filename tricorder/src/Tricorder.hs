module Tricorder (run) where

import Effectful (IOE)
import Effectful.Reader.Static (Reader, ask, asks)
import Effectful.Timeout (Timeout)

import Data.Text qualified as T

import Atelier.Effects.Clock (Clock)
import Atelier.Effects.Conc (Conc)
import Atelier.Effects.Console (Console)
import Atelier.Effects.Delay (Delay)
import Atelier.Effects.Exit (Exit)
import Atelier.Effects.File (File)
import Atelier.Effects.FileSystem (FileSystem)
import Atelier.Effects.Posix.Daemons (Daemons)
import Tricorder.Arguments (Command (..))
import Tricorder.BuildState (BuildState (..), DaemonInfo (..))
import Tricorder.CLI (showLog, showSource, showStatus, showTests)
import Tricorder.Daemon (startDaemon, stopDaemon, waitForDaemon)
import Tricorder.Effects.Brick (Brick)
import Tricorder.Effects.BrickChan (BrickChan)
import Tricorder.Effects.UnixSocket (UnixSocket)
import Tricorder.Runtime (LogPath (..), PidFile (..), SocketPath (..))
import Tricorder.Socket.Client (isDaemonRunning, queryStatus)
import Tricorder.UI (viewUi)

import Atelier.Effects.Console qualified as Console
import Tricorder.UI.Keys qualified as Keys


run
    :: ( Brick :> es
       , BrickChan :> es
       , Clock :> es
       , Conc :> es
       , Console :> es
       , Daemons :> es
       , Delay :> es
       , Exit :> es
       , File :> es
       , FileSystem :> es
       , IOE :> es
       , Reader Command :> es
       , Reader Keys.Config :> es
       , Reader LogPath :> es
       , Reader PidFile :> es
       , Reader SocketPath :> es
       , Timeout :> es
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
        Test opts -> do
            running <- isDaemonRunning
            if not running then
                Console.putStrLn "Stopped."
            else
                showTests opts
        Log followMode -> do
            running <- isDaemonRunning
            logFile <-
                if running then do
                    SocketPath sp <- ask
                    result <- queryStatus sp
                    LogPath fallback <- ask
                    pure $ case result of
                        Right state -> state.daemonInfo.logFile
                        Left _ -> fallback
                else
                    asks @LogPath (.getLogPath)
            showLog logFile followMode
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
