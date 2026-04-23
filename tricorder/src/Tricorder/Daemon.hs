module Tricorder.Daemon
    ( startDaemon
    , stopDaemon
    ) where

import Effectful (IOE)
import Effectful.Reader.Static (Reader)

import Atelier.Component (runSystem)
import Atelier.Effects.Cache (Cache)
import Atelier.Effects.Clock (Clock)
import Atelier.Effects.Conc (Conc)
import Atelier.Effects.Debounce (Debounce)
import Atelier.Effects.Delay (Delay)
import Atelier.Effects.FileSystem (FileSystem)
import Atelier.Effects.FileWatcher (FileWatcher)
import Atelier.Effects.Log (Log)
import Atelier.Effects.Monitoring.Tracing (Tracing)
import Atelier.Effects.Posix.Daemon (Daemon)
import Tricorder.Config (Config (..))
import Tricorder.Effects.BuildStore (BuildStore)
import Tricorder.Effects.GhcPkg (GhcPkg)
import Tricorder.Effects.GhciSession (GhciSession)
import Tricorder.Effects.TestRunner (TestRunner)
import Tricorder.Effects.UnixSocket (UnixSocket)
import Tricorder.GhcPkg.Types (ModuleName, PackageId)
import Tricorder.Runtime (SocketPath (..))

import Atelier.Effects.Conc qualified as Conc
import Atelier.Effects.Posix.Daemon qualified as Daemon
import Tricorder.GhciSession qualified as GhciSession
import Tricorder.Observability qualified as Observability
import Tricorder.Socket.Server qualified as SocketServer
import Tricorder.Watcher qualified as Watcher


-- | Fork the daemon as a background process and return immediately.
-- No-op if the daemon is already running (caller should check beforehand).
startDaemon
    :: ( BuildStore :> es
       , Cache (PackageId, ModuleName) Text :> es
       , Cache ModuleName PackageId :> es
       , Clock :> es
       , Conc :> es
       , Daemon :> es
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
       , Reader SocketPath :> es
       , TestRunner :> es
       , Tracing :> es
       , UnixSocket :> es
       )
    => Eff es ()
startDaemon =
    Daemon.daemonize
        $ runSystem
            [ Observability.component
            , Watcher.component
            , GhciSession.component
            , SocketServer.component
            ]


stopDaemon :: (Daemon :> es) => Eff es ()
stopDaemon = Daemon.killAndWait
