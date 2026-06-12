module Tricorder.UI
    ( viewUi
    ) where

import Atelier.Effects.Clock (Clock)
import Atelier.Effects.Conc (Conc)
import Atelier.Effects.Console (Console)
import Atelier.Effects.Delay (Delay)
import Atelier.Effects.File (File)
import Brick (App (..), neverShowCursor)
import Brick.Keybindings (KeyConfig)
import Effectful.Reader.Static (Reader, ask)

import Atelier.Effects.Conc qualified as Conc

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
-- a brick TUI. Quits on @q@ or @Esc@; arrow keys scroll the viewport.
viewUi
    :: ( Brick :> es
       , BrickChan :> es
       , Clock :> es
       , Conc :> es
       , Console :> es
       , Delay :> es
       , File :> es
       , Reader Keys.Config :> es
       , Reader SocketPath :> es
       , UnixSocket :> es
       )
    => Eff es ()
viewUi = do
    SocketPath sockPath <- ask
    chan <- BrickChan.newBChan 10
    initialState <- Model.init
    Conc.scoped do
        _ <-
            Conc.fork do
                queryWatch sockPath $ BrickChan.writeBChan chan . NewBuildState
                BrickChan.writeBChan chan $ FailedBuild "Lost contact with the daemon"
        keyConfig <- Keys.mkKeyConfig
        void
            $ Brick.runBrickApp
                chan
                (watchApp keyConfig)
                initialState


watchApp :: KeyConfig KeyEvent -> App State Event Viewports
watchApp kc =
    App
        { appDraw = view kc
        , appHandleEvent = handleEvent $ dispatcher kc
        , appStartEvent = pure ()
        , appAttrMap = mkAttrMap
        , appChooseCursor = neverShowCursor
        }
