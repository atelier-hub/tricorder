module Tricorder.Daemon
    ( runDaemon
    , startDaemon
    , stopDaemon
    , waitForDaemon
    ) where

import Effectful (IOE)
import Effectful.Reader.Static (Reader, ask)

import Atelier.Component (runSystem)
import Atelier.Effects.Clock (Clock)
import Atelier.Effects.Conc (Conc)
import Atelier.Effects.Debounce (Debounce)
import Atelier.Effects.Delay (Delay)
import Atelier.Effects.FileSystem (FileSystem)
import Atelier.Effects.FileWatcher (FileWatcher)
import Atelier.Effects.Log (Log)
import Atelier.Effects.Monitoring.Tracing (Tracing)
import Atelier.Effects.Posix.Daemons (Daemons)
import Atelier.Effects.RPC (Handler)
import Atelier.Time (Millisecond)
import Tricorder.Config (Config (..))
import Tricorder.Effects.BuildStore (BuildStore)
import Tricorder.Effects.GhciSession (GhciSession)
import Tricorder.Effects.TestRunner (TestRunner)
import Tricorder.Effects.UnixSocket (UnixSocket)
import Tricorder.Runtime (PidFile, SocketPath (..))
import Tricorder.Socket.Client (isDaemonRunning)
import Tricorder.Socket.Protocol (Request)

import Atelier.Effects.Delay qualified as Delay
import Atelier.Effects.Posix.Daemons qualified as Daemons
import Tricorder.GhciSession qualified as GhciSession
import Tricorder.Observability qualified as Observability
import Tricorder.Socket.Server qualified as SocketServer
import Tricorder.Watcher qualified as Watcher


-- | Run the daemon for the given project root.
-- Blocks forever; all work happens inside the component system.
runDaemon
    :: ( BuildStore :> es
       , Clock :> es
       , Conc :> es
       , Debounce FilePath :> es
       , Delay :> es
       , FileSystem :> es
       , FileWatcher :> es
       , GhciSession :> es
       , Handler Request :> es
       , IOE :> es
       , Log :> es
       , Reader Config :> es
       , Reader Observability.Config :> es
       , Reader SocketPath :> es
       , TestRunner :> es
       , Tracing :> es
       , UnixSocket :> es
       )
    => Eff es ()
runDaemon =
    runSystem
        [ Observability.component
        , Watcher.component
        , GhciSession.component
        , SocketServer.component
        ]


-- | Fork the daemon as a background process and return immediately.
-- No-op if the daemon is already running (caller should check beforehand).
startDaemon
    :: ( BuildStore :> es
       , Clock :> es
       , Conc :> es
       , Daemons :> es
       , Debounce FilePath :> es
       , Delay :> es
       , FileSystem :> es
       , FileWatcher :> es
       , GhciSession :> es
       , Handler Request :> es
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
startDaemon = do
    pidFile <- ask
    Daemons.daemonize pidFile runDaemon


stopDaemon :: (Daemons :> es, Reader PidFile :> es) => Eff es ()
stopDaemon = do
    pidFile <- ask
    Daemons.killAndWait pidFile


-- | Poll until the daemon socket becomes connectable.
waitForDaemon :: (Daemons :> es, Delay :> es, Reader PidFile :> es, UnixSocket :> es) => Eff es ()
waitForDaemon = do
    Delay.wait (200 :: Millisecond)
    running <- isDaemonRunning
    unless running waitForDaemon
