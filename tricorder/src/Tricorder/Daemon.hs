module Tricorder.Daemon
    ( runDaemon
    , startDaemon
    , stopDaemon
    ) where

import Effectful (IOE)
import Effectful.Exception (try)
import Effectful.Reader.Static (Reader, ask)

import Atelier.Component (runSystem)
import Atelier.Effects.Cache (Cache)
import Atelier.Effects.Clock (Clock)
import Atelier.Effects.Conc (Conc)
import Atelier.Effects.Delay (Delay)
import Atelier.Effects.FileSystem (FileSystem, removeFile)
import Atelier.Effects.Log (Log)
import Atelier.Effects.Monitoring.Tracing (Tracing)
import Atelier.Effects.Posix.Process (Process, createSession, forkProcess)
import Tricorder.Config (Config (..))
import Tricorder.Effects.BuildStore (BuildStore)
import Tricorder.Effects.FileWatcher (FileWatcher)
import Tricorder.Effects.GhcPkg (GhcPkg)
import Tricorder.Effects.GhciSession (GhciSession)
import Tricorder.Effects.TestRunner (TestRunner)
import Tricorder.Effects.UnixSocket (UnixSocket)
import Tricorder.GhcPkg.Types (ModuleName, PackageId)
import Tricorder.Socket.SocketPath (SocketPath (..))

import Atelier.Effects.Conc qualified as Conc
import Tricorder.GhciSession qualified as GhciSession
import Tricorder.Observability qualified as Observability
import Tricorder.Socket.Server qualified as SocketServer
import Tricorder.Watcher qualified as Watcher


-- | Run the daemon for the given project root.
-- Blocks forever; all work happens inside the component system.
runDaemon
    :: ( BuildStore :> es
       , Cache (PackageId, ModuleName) Text :> es
       , Cache ModuleName PackageId :> es
       , Clock :> es
       , Conc :> es
       , Delay :> es
       , FileSystem :> es
       , FileWatcher :> es
       , GhcPkg :> es
       , GhciSession :> es
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
runDaemon = do
    runSystem
        [ Observability.component
        , Watcher.component
        , GhciSession.component
        , SocketServer.component
        ]
    Conc.awaitAll


-- | Fork the daemon as a background process and return immediately.
-- No-op if the daemon is already running (caller should check beforehand).
startDaemon
    :: ( BuildStore :> es
       , Cache (PackageId, ModuleName) Text :> es
       , Cache ModuleName PackageId :> es
       , Clock :> es
       , Conc :> es
       , Delay :> es
       , FileSystem :> es
       , FileWatcher :> es
       , GhcPkg :> es
       , GhciSession :> es
       , IOE :> es
       , Log :> es
       , Process :> es
       , Reader Config :> es
       , Reader Observability.Config :> es
       , Reader SocketPath :> es
       , TestRunner :> es
       , Tracing :> es
       , UnixSocket :> es
       )
    => Eff es ()
startDaemon = do
    void $ forkProcess do
        void createSession -- detach from terminal
        runDaemon


-- | Remove the daemon's socket file, which causes the socket server to stop.
-- The daemon process itself will exit once its scope closes.
stopDaemon :: (FileSystem :> es, Reader SocketPath :> es) => Eff es ()
stopDaemon = do
    SocketPath sockPath <- ask
    void $ try @SomeException $ removeFile sockPath
