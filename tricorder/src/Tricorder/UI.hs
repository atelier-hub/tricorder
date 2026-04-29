module Tricorder.UI
    ( viewUi
    ) where

import Brick
    ( App (..)
    , attrMap
    , attrName
    , neverShowCursor
    )

import Graphics.Vty.Attributes qualified as Attr
import Graphics.Vty.Attributes.Color qualified as Color

import Atelier.Effects.Clock (Clock)
import Atelier.Effects.Conc (Conc)
import Atelier.Effects.RPC (Client)
import Tricorder.Effects.Brick (Brick)
import Tricorder.Effects.BrickChan (BrickChan)
import Tricorder.Socket.Client (queryWatch)
import Tricorder.Socket.Protocol (Request)
import Tricorder.UI.Event (Event (..), handleEvent)
import Tricorder.UI.State (State (..), Viewports (..))
import Tricorder.UI.View (view)

import Atelier.Effects.Conc qualified as Conc
import Tricorder.Effects.Brick qualified as Brick
import Tricorder.Effects.BrickChan qualified as BrickChan
import Tricorder.UI.State qualified as Model


-- | Connect to the daemon and render a live-updating build status display using
-- a brick TUI. Quits on @q@ or @Esc@; arrow keys scroll the viewport.
viewUi
    :: ( Brick :> es
       , BrickChan :> es
       , Client Request :> es
       , Clock :> es
       , Conc :> es
       )
    => Eff es ()
viewUi = do
    chan <- BrickChan.newBChan 10
    initialState <- Model.init
    Conc.scoped do
        _ <-
            Conc.fork
                $ queryWatch
                $ BrickChan.writeBChan chan . NewBuildState
        void
            $ Brick.runBrickApp
                chan
                watchApp
                initialState


watchApp :: App State Event Viewports
watchApp =
    App
        { appDraw = view
        , appHandleEvent = handleEvent
        , appStartEvent = pure ()
        , appAttrMap =
            const
                ( attrMap
                    Attr.defAttr
                    [ (attrName "ok", Attr.withForeColor Attr.defAttr Color.green)
                    , (attrName "warning", Attr.withForeColor Attr.defAttr Color.yellow)
                    , (attrName "error", Attr.withForeColor Attr.defAttr Color.red)
                    , (attrName "emphasis", Attr.withStyle Attr.defAttr Attr.bold)
                    , (attrName "subtle", Attr.withForeColor Attr.defAttr $ Color.rgbColor @Int 148 148 148)
                    ]
                )
        , appChooseCursor = neverShowCursor
        }
