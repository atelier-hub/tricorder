module Tricorder.Socket.Server (component, SocketRemoved (..)) where

import Effectful.Reader.Static (Reader, ask)

import Atelier.Component (Component (..), Trigger, defaultComponent)
import Atelier.Effects.Conc (Conc)
import Atelier.Effects.Exit (Exit)
import Atelier.Effects.Log (Log)
import Atelier.Effects.RPC (Handler)
import Atelier.Effects.RPC.Unix (serveUnix)
import Atelier.Effects.UnixSocket (UnixSocket, removeSocketFile)
import Tricorder.RPC.Protocol (Protocol, dispatch)
import Tricorder.Runtime (SocketPath (..))


data SocketRemoved = SocketRemoved
    deriving stock (Eq, Show)
    deriving anyclass (Exception)


-- | SocketServer component.
-- Listens on a Unix socket and responds to status/watch/source queries.
component
    :: ( Conc :> es
       , Exit :> es
       , Handler Protocol :> es
       , Log :> es
       , Reader SocketPath :> es
       , UnixSocket :> es
       )
    => Component es
component =
    defaultComponent
        { name = "SocketServer"
        , setup = do
            SocketPath sockPath <- ask
            removeSocketFile sockPath
        , triggers = pure [acceptTrigger]
        }


acceptTrigger
    :: ( Conc :> es
       , Exit :> es
       , Handler Protocol :> es
       , Log :> es
       , Reader SocketPath :> es
       , UnixSocket :> es
       )
    => Trigger es
acceptTrigger = do
    SocketPath sockPath <- ask
    serveUnix dispatch sockPath
