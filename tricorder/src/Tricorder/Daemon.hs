module Tricorder.Daemon
    ( runDaemon
    , startDaemon
    , stopDaemon
    , waitForDaemon
    ) where

import Effectful (IOE)
import Effectful.NonDet (OnEmptyPolicy (..), emptyEff, runNonDet)
import Effectful.Reader.Static (Reader, ask)
import Effectful.Timeout (Timeout, timeout)
import Effectful.Writer.Static.Local (runWriter, tell)

import Atelier.Component (runSystem)
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
import Atelier.Time (Millisecond)
import Tricorder.Config (Config (..))
import Tricorder.Effects.BuildStore (BuildStore)
import Tricorder.Effects.GhcPkg (GhcPkg)
import Tricorder.Effects.GhciSession (GhciSession)
import Tricorder.Effects.TestRunner (TestRunner)
import Tricorder.GhcPkg.Types (ModuleName, PackageId)
import Tricorder.Runtime (PidFile)
import Tricorder.Web.Client (isDaemonRunning)
import Tricorder.Web.Server (ShutdownRequested)

import Atelier.Effects.Delay qualified as Delay
import Atelier.Effects.Posix.Daemons qualified as Daemons
import Tricorder.GhciSession qualified as GhciSession
import Tricorder.Observability qualified as Observability
import Tricorder.Watcher qualified as Watcher
import Tricorder.Web.Client qualified as Client
import Tricorder.Web.Client qualified as Web
import Tricorder.Web.Config qualified as Web
import Tricorder.Web.Server qualified as WebServer


-- | Run the daemon for the given project root.
-- Blocks forever; all work happens inside the component system.
runDaemon
    :: ( BuildStore :> es
       , Cache (PackageId, ModuleName) Text :> es
       , Cache ModuleName PackageId :> es
       , Clock :> es
       , Conc :> es
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
       , Reader Config :> es
       , Reader Observability.Config :> es
       , Reader Web.Config :> es
       , Sub ShutdownRequested :> es
       , TestRunner :> es
       , Tracing :> es
       )
    => Eff es ()
runDaemon = do
    runSystem
        [ Observability.component
        , Watcher.component
        , GhciSession.component
        , WebServer.component
        ]


-- | Fork the daemon as a background process and return immediately.
-- No-op if the daemon is already running (caller should check beforehand).
startDaemon
    :: ( BuildStore :> es
       , Cache (PackageId, ModuleName) Text :> es
       , Cache ModuleName PackageId :> es
       , Clock :> es
       , Conc :> es
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
       , Reader Config :> es
       , Reader Observability.Config :> es
       , Reader PidFile :> es
       , Reader Web.Config :> es
       , Sub ShutdownRequested :> es
       , TestRunner :> es
       , Tracing :> es
       )
    => Eff es ()
startDaemon = do
    pidFile <- ask
    Daemons.daemonize pidFile runDaemon


-- | Attempts to stop the daemon in progressively more forceful ways.
-- 1. First attempts to make the daemon stop using the API.
-- 2. Then attempts to stop the daemon by sending `SIGKILL` to its process.
stopDaemon
    :: forall es
     . ( Daemons :> es
       , Delay :> es
       , Reader PidFile :> es
       , Timeout :> es
       , Web.Client :> es
       )
    => Eff es (Either [Text] Text)
stopDaemon = do
    pidFile <- ask
    res <-
        runWriter @[Text]
            $ fmap rightToMaybe
            $ runNonDet OnEmptyKeep
            $ requestStop pidFile
                <|> sendKill pidFile
    case res of
        (Just r, _) -> pure $ Right r
        (Nothing, es) -> pure $ Left es
  where
    requestStop pidFile = do
        timeout1second Client.shutDown >>= \_ -> do
            didStop <- fmap isJust $ timeout 3_000_000 $ waitForStop pidFile
            if didStop then
                pure "Daemon stopped."
            else do
                tell ["Daemon did not stop as requested."]
                emptyEff

    sendKill pidFile = do
        timeout1second (Daemons.forceKillAndWait pidFile) >>= \case
            Just () -> pure "Daemon stopped with SIGKILL."
            Nothing -> do
                tell ["Daemon did not respond to SIGKILL"]
                emptyEff

    timeout1second = fmap (join . fmap rightToMaybe) . timeout 1_000_000

    waitForStop :: forall es'. (Daemons :> es', Delay :> es') => PidFile -> Eff es' ()
    waitForStop pidFile = fix \rec -> do
        running <- Daemons.isRunning pidFile
        if running then do
            Delay.wait (500 :: Millisecond)
            rec
        else
            pure ()


-- | Poll until the daemon socket becomes connectable.
waitForDaemon
    :: ( Console :> es
       , Daemons :> es
       , Delay :> es
       , Reader PidFile :> es
       , Web.Client :> es
       )
    => Eff es ()
waitForDaemon = do
    Delay.wait (200 :: Millisecond)
    running <- isDaemonRunning
    ready <- Client.isLive
    unless (running && ready == Right True) waitForDaemon
