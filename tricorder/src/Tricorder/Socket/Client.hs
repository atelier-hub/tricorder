module Tricorder.Socket.Client
    ( queryStatus
    , queryStatusWait
    , queryWatch
    , querySource
    , queryDiagnostic
    , isDaemonRunning
    ) where

import Effectful.Reader.Static (Reader, ask)

import Atelier.Effects.Posix.Daemons (Daemons)
import Tricorder.BuildState (BuildState, Diagnostic)
import Tricorder.Effects.DaemonClient (DaemonClient, runRequest, runStream)
import Tricorder.GhcPkg.Types (ModuleName)
import Tricorder.Runtime (PidFile)
import Tricorder.Socket.Protocol (Request (..))
import Tricorder.SourceLookup (ModuleSourceResult)

import Atelier.Effects.Posix.Daemons qualified as Daemons


queryStatus :: (DaemonClient :> es) => Eff es (Either Text BuildState)
queryStatus = runRequest StatusNow


queryStatusWait :: (DaemonClient :> es) => Eff es (Either Text BuildState)
queryStatusWait = runRequest StatusAwait


queryWatch :: (DaemonClient :> es) => (BuildState -> Eff es ()) -> Eff es ()
queryWatch = runStream Watch


querySource :: (DaemonClient :> es) => [ModuleName] -> Eff es (Either Text [ModuleSourceResult])
querySource = runRequest . Source


queryDiagnostic :: (DaemonClient :> es) => Int -> Eff es (Either Text Diagnostic)
queryDiagnostic idx =
    runRequest (DiagnosticAt idx) <&> \case
        Left err -> Left err
        Right (Left msg) -> Left msg
        Right (Right d) -> Right d


isDaemonRunning :: (Daemons :> es, Reader PidFile :> es) => Eff es Bool
isDaemonRunning = do
    pidFile <- ask
    Daemons.isRunning pidFile
