module Ghcib.GhciSession (component) where

import Data.Time (diffUTCTime)
import Effectful (IOE)
import Effectful.Concurrent (Concurrent)
import Effectful.Exception (throwIO, try)
import Effectful.Reader.Static (Reader, ask)
import System.Directory (getCurrentDirectory)

import Atelier.Component (Component (..), Listener, defaultComponent)
import Atelier.Effects.Chan (Chan, OutChan)
import Atelier.Effects.Clock (Clock)
import Atelier.Effects.Delay (Delay, wait)
import Atelier.Effects.Log (Log)
import Atelier.Exception (isGracefulShutdown)
import Atelier.Time (Millisecond, nominalDiffTime)
import Ghcib.BuildState
    ( BuildId (..)
    , BuildPhase (..)
    , BuildStateRef (..)
    , updateBuildPhase
    )
import Ghcib.Config (Config (..), resolveCommand)
import Ghcib.Effects.GhciSession (GhciSession)
import Ghcib.Watcher (ReloadRequest (..))

import Atelier.Effects.Chan qualified as Chan
import Atelier.Effects.Clock qualified as Clock
import Atelier.Effects.Log qualified as Log
import Ghcib.Effects.GhciSession qualified as GhciSession


-- | GhciSession component.
-- Starts a GHCi session, performs an initial load, then listens for reload
-- requests from the watcher. Catches UnexpectedExit and restarts the session
-- rather than propagating (the fix for ghcid's file-removal crash).
component
    :: ( Chan :> es
       , Clock :> es
       , Concurrent :> es
       , Delay :> es
       , GhciSession :> es
       , IOE :> es
       , Log :> es
       , Reader BuildStateRef :> es
       , Reader Config :> es
       )
    => OutChan ReloadRequest
    -> Component es
component reloadOut =
    defaultComponent
        { name = "GhciSession"
        , listeners = do
            cfg <- ask @Config
            stateRef <- ask @BuildStateRef
            projectRoot <- liftIO getCurrentDirectory
            cmd <- liftIO $ resolveCommand cfg projectRoot
            Log.debug $ "GhciSession.component: resolved command = " <> cmd
            Log.debug $ "GhciSession.component: projectRoot = " <> toText projectRoot
            pure [sessionListener cmd projectRoot stateRef reloadOut]
        }


sessionListener
    :: ( Chan :> es
       , Clock :> es
       , Concurrent :> es
       , Delay :> es
       , GhciSession :> es
       , Log :> es
       )
    => Text
    -> FilePath
    -> BuildStateRef
    -> OutChan ReloadRequest
    -> Listener es
sessionListener cmd projectRoot stateRef reloadOut = startSession (BuildId 1)
  where
    startSession (BuildId n) = do
        Log.info $ "Starting GHCi session #" <> show n <> ": " <> cmd
        result <- try @SomeException $ GhciSession.startGhci cmd projectRoot
        Log.debug $ "GhciSession.startGhci returned (session #" <> show n <> ")"
        case result of
            Left ex -> do
                when (isGracefulShutdown ex) $ throwIO ex
                Log.err $ "Failed to start GHCi (session #" <> show n <> "): " <> show ex
                -- Brief pause before retry to avoid tight restart loop
                wait (2_000 :: Millisecond)
                startSession (BuildId n)
            Right msgs -> do
                Log.info $ "GHCi started (session #" <> show n <> "): " <> show (length msgs) <> " messages"
                t0 <- Clock.currentTime
                let dur = nominalDiffTime @Millisecond (diffUTCTime t0 t0)
                updateBuildPhase stateRef (BuildId n) (Done t0 dur msgs)
                Log.debug $ "Build state updated to Done (session #" <> show n <> ")"
                listenLoop (BuildId (n + 1))

    listenLoop (BuildId n) = do
        Log.debug $ "GhciSession: waiting for reload request (build #" <> show n <> ")"
        request <- Chan.readChan reloadOut
        let nextId = BuildId (n + 1)
        Log.debug $ "Reload requested: " <> show request
        updateBuildPhase stateRef (BuildId n) Building
        t0 <- Clock.currentTime
        result <- try @SomeException $ case request of
            Reload -> GhciSession.reloadGhci
            Restart -> GhciSession.stopGhci >> pure []
        case result of
            Left ex -> do
                when (isGracefulShutdown ex) $ throwIO ex
                Log.warn "GHCi session died; restarting"
                void $ try @SomeException GhciSession.stopGhci
                startSession nextId
            Right msgs -> do
                t1 <- Clock.currentTime
                let dur = nominalDiffTime (diffUTCTime t1 t0)
                updateBuildPhase stateRef (BuildId n) (Done t1 dur msgs)
                if request == Restart then
                    startSession nextId
                else
                    listenLoop nextId
