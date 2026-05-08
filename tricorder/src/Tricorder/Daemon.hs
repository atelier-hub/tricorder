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
import Atelier.Effects.Debounce (Debounce)
import Atelier.Effects.Delay (Delay)
import Atelier.Effects.Exit (Exit)
import Atelier.Effects.File (File)
import Atelier.Effects.FileSystem (FileSystem)
import Atelier.Effects.FileWatcher (FileWatcher)
import Atelier.Effects.Log (Log)
import Atelier.Effects.Monitoring.Tracing (Tracing)
import Atelier.Effects.Posix.Daemons (Daemons)
import Atelier.Time (Millisecond)
import Tricorder.Effects.BuildStore (BuildStore)
import Tricorder.Effects.GhcPkg (GhcPkg)
import Tricorder.Effects.GhciSession (GhciSession)
import Tricorder.Effects.TestRunner (TestRunner)
import Tricorder.Effects.UnixSocket (UnixSocket)
import Tricorder.GhcPkg.Types (ModuleName, PackageId)
import Tricorder.Runtime (PidFile, SocketPath (..))
import Tricorder.Session (Session (..))
import Tricorder.Socket.Client (isDaemonRunning, requestShutdown)

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
       , Reader Observability.Config :> es
       , Reader Session :> es
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
       , Reader Observability.Config :> es
       , Reader PidFile :> es
       , Reader Session :> es
       , Reader SocketPath :> es
       , TestRunner :> es
       , Tracing :> es
       , UnixSocket :> es
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
       , File :> es
       , Reader PidFile :> es
       , Reader SocketPath :> es
       , Timeout :> es
       , UnixSocket :> es
       )
    => Eff es (Either [Text] Text)
stopDaemon = do
    SocketPath sockPath <- ask
    pidFile <- ask
    res <-
        runWriter @[Text]
            $ fmap rightToMaybe
            $ runNonDet OnEmptyKeep
            $ requestStop sockPath pidFile
                <|> sendKill pidFile
    case res of
        (Just r, _) -> pure $ Right r
        (Nothing, es) -> pure $ Left es
  where
    requestStop sockPath pidFile = do
        timeout1second (requestShutdown sockPath) >>= \_ -> do
            didStop <- fmap isJust $ timeout 3_000_000 $ waitForStop pidFile
            if didStop then
                pure "Daemon stopped."
            else do
                tell ["Daemon did not stop as requested."]
                emptyEff

    sendKill pidFile = do
        timeout1second (Daemons.forceKillAndWait pidFile) >>= \case
            Nothing -> pure "Daemon stopped with SIGKILL."
            Just ex -> do
                tell ["Daemon did not respond to SIGKILL: " <> show ex]
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
waitForDaemon :: (Daemons :> es, Delay :> es, Reader PidFile :> es, UnixSocket :> es) => Eff es ()
waitForDaemon = do
    Delay.wait (200 :: Millisecond)
    running <- isDaemonRunning
    unless running waitForDaemon
