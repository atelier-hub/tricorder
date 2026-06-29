module Tricorder.Daemon
    ( startDaemon
    , stopDaemon
    , waitForDaemon
    ) where

import Atelier.Effects.Delay (Delay)
import Atelier.Effects.File (File)
import Atelier.Effects.Posix.Daemons (Daemons)
import Atelier.Effects.Timeout (Timeout, timeout)
import Atelier.Time (Millisecond, Second)
import Effectful (IOE)
import Effectful.NonDet (OnEmptyPolicy (..), emptyEff, runNonDet)
import Effectful.Reader.Static (Reader, ask)
import Effectful.Writer.Static.Local (runWriter, tell)
import Prelude hiding (force)

import Atelier.Effects.Delay qualified as Delay
import Atelier.Effects.Posix.Daemons qualified as Daemons

import Tricorder.Arguments (Force (..))
import Tricorder.Effects.UnixSocket (UnixSocket)
import Tricorder.Runtime (PidFile, SocketPath (..))
import Tricorder.Socket.Client (isDaemonRunning, requestShutdown)

import Tricorder.Daemon.Main qualified as Daemon.Main


startDaemon
    :: ( Daemons :> es
       , IOE :> es
       , Reader PidFile :> es
       )
    => Eff es ()
startDaemon = do
    pidFile <- ask
    Daemons.daemonize pidFile $ liftIO Daemon.Main.main


-- | Attempts to stop the daemon in progressively more forceful ways.
-- 1. First attempts to make the daemon stop using the API.
-- 2. Then attempts to stop the daemon by sending `SIGKILL` to its process.
stopDaemon
    :: ( Daemons :> es
       , Delay :> es
       , File :> es
       , Reader PidFile :> es
       , Reader SocketPath :> es
       , Timeout :> es
       , UnixSocket :> es
       )
    => Force -> Eff es (Either [Text] Text)
stopDaemon force = do
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
    timeoutDelay :: Second = case force of
        Force -> 3
        NoForce -> 6
    requestStop sockPath pidFile = do
        timeout1second (requestShutdown force sockPath) >>= \_ -> do
            didStop <- fmap isJust $ timeout timeoutDelay $ waitForStop pidFile
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

    timeout1second = fmap (join . fmap rightToMaybe) . timeout (1 :: Second)

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
