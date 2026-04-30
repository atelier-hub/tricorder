module Tricorder.Socket.Client
    ( queryStatus
    , queryStatusWait
    , queryWatch
    , querySource
    , queryDiagnostic
    , requestShutdown
    , isDaemonRunning
    ) where

import Effectful.Reader.Static (Reader, ask)

import Atelier.Effects.Posix.Daemons (Daemons)
import Atelier.Effects.RPC (Client, runRequest, runStream)
import Tricorder.BuildState (BuildState, Diagnostic)
import Tricorder.GhcPkg.Types (ModuleName)
import Tricorder.RPC.Protocol (Protocol (..))
import Tricorder.Runtime (PidFile)
import Tricorder.SourceLookup (ModuleSourceResult)

import Atelier.Effects.Posix.Daemons qualified as Daemons


queryStatus :: (Client Protocol :> es) => Eff es (Either Text BuildState)
queryStatus = runRequest StatusNow


queryStatusWait :: (Client Protocol :> es) => Eff es (Either Text BuildState)
queryStatusWait = runRequest StatusAwait


queryWatch :: (Client Protocol :> es) => (BuildState -> Eff es ()) -> Eff es ()
queryWatch = runStream Watch


querySource :: (Client Protocol :> es) => [ModuleName] -> Eff es (Either Text [ModuleSourceResult])
querySource = runRequest . Source


queryDiagnostic :: (Client Protocol :> es) => Int -> Eff es (Either Text Diagnostic)
queryDiagnostic idx =
    runRequest (DiagnosticAt idx) <&> \case
        Left err -> Left err
        Right (Left msg) -> Left msg
        Right (Right d) -> Right d


requestShutdown :: (Client Protocol :> es) => Eff es (Either Text ())
requestShutdown = runRequest Quit


isDaemonRunning :: (Daemons :> es, Reader PidFile :> es) => Eff es Bool
isDaemonRunning = do
    pidFile <- ask
    Daemons.isRunning pidFile
