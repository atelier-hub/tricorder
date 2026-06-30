module Tricorder.UI
    ( viewUi
    ) where

import Atelier.Effects.Clock (Clock)
import Atelier.Effects.Conc (Conc)
import Atelier.Effects.Console (Console)
import Atelier.Effects.Delay (Delay)
import Atelier.Effects.File (File)
import Atelier.Effects.Process (Process, getExecutablePath, proc, readProcessStdout)
import Brick (App (..), neverShowCursor)
import Brick.BChan (BChan, writeBChanNonBlocking)
import Brick.Keybindings (KeyConfig)
import Data.IORef (IORef, newIORef, readIORef, writeIORef)
import Effectful (IOE)
import Effectful.Exception (trySync)
import Effectful.Reader.Static (Reader, ask)

import Atelier.Effects.Conc qualified as Conc

import Tricorder.Daemon (waitForDaemon)
import Tricorder.Effects.Brick (Brick)
import Tricorder.Effects.BrickChan (BrickChan)
import Tricorder.Effects.UnixSocket (UnixSocket)
import Tricorder.Runtime (SocketPath (..))
import Tricorder.Socket.Client (queryWatch)
import Tricorder.UI.Event (Event (..), handleEvent)
import Tricorder.UI.Keys (KeyEvent, dispatcher)
import Tricorder.UI.State (State (..), Viewports (..))
import Tricorder.UI.View (mkAttrMap, view)

import Tricorder.Effects.Brick qualified as Brick
import Tricorder.Effects.BrickChan qualified as BrickChan
import Tricorder.UI.Keys qualified as Keys
import Tricorder.UI.State qualified as Model


-- | Connect to the daemon and render a live-updating build status display using
-- a brick TUI. Quits on @q@ or @Esc@; arrow keys scroll the viewport; @R@
-- restarts the daemon.
viewUi
    :: ( Brick :> es
       , BrickChan :> es
       , Clock :> es
       , Conc :> es
       , Console :> es
       , Delay :> es
       , File :> es
       , IOE :> es
       , Process :> es
       , Reader Keys.Config :> es
       , Reader SocketPath :> es
       , UnixSocket :> es
       )
    => Eff es ()
viewUi = do
    SocketPath sockPath <- ask
    chan <- BrickChan.newBChan 10
    restartChan <- BrickChan.newBChan 1
    -- Set while a restart we triggered is in flight, so the watch loop stays
    -- patient and reconnects to the fresh daemon instead of giving up.
    restarting <- liftIO $ newIORef False
    initialState <- Model.init
    Conc.scoped do
        _ <-
            Conc.fork do
                queryWatch sockPath (liftIO $ readIORef restarting)
                    $ BrickChan.writeBChan chan . NewBuildState
                BrickChan.writeBChan chan $ FailedBuild "Lost contact with the daemon"
        _ <- Conc.fork $ restartWorker restartChan restarting
        keyConfig <- Keys.mkKeyConfig
        let requestRestart = void $ writeBChanNonBlocking restartChan ()
        void
            $ Brick.runBrickApp
                chan
                (watchApp requestRestart keyConfig)
                initialState


-- | Wait for restart requests from the TUI and service each one by spawning a
-- fresh @tricorder restart@ process.
--
-- The restart must happen out-of-process: starting the daemon double-forks (see
-- "System.Posix.Daemon"), and forking this vty-controlled process knocks the
-- terminal out of the raw mode brick set up, so keystrokes stop being captured.
-- Delegating to a separate process keeps the fork isolated. The brick event
-- handler signals us over @restartChan@ because it cannot run these effects.
restartWorker
    :: ( BrickChan :> es
       , Delay :> es
       , IOE :> es
       , Process :> es
       , Reader SocketPath :> es
       , UnixSocket :> es
       )
    => BChan ()
    -> IORef Bool
    -> Eff es ()
restartWorker restartChan restarting = forever do
    BrickChan.readBChan restartChan
    liftIO $ writeIORef restarting True
    self <- getExecutablePath
    -- Swallow failures: a restart that errors must not take down the TUI, and
    -- the flag has to be cleared either way.
    _ <- trySync $ readProcessStdout $ proc self ["restart"]
    void waitForDaemon
    liftIO $ writeIORef restarting False


watchApp :: IO () -> KeyConfig KeyEvent -> App State Event Viewports
watchApp requestRestart kc =
    App
        { appDraw = view kc
        , appHandleEvent = handleEvent $ dispatcher requestRestart kc
        , appStartEvent = pure ()
        , appAttrMap = mkAttrMap
        , appChooseCursor = neverShowCursor
        }
