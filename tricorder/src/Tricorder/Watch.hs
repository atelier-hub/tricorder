module Tricorder.Watch
    ( watchDisplay
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
import Atelier.Effects.File (File)
import Tricorder.Effects.Brick (Brick)
import Tricorder.Effects.BrickChan (BrickChan)
import Tricorder.Effects.UnixSocket (UnixSocket)
import Tricorder.Socket.Client (queryWatch)
import Tricorder.Watch.Event (Event (..), handleEvent)
import Tricorder.Watch.State (Name (..), State (..))
import Tricorder.Watch.View (view)

import Atelier.Effects.Conc qualified as Conc
import Tricorder.Effects.Brick qualified as Brick
import Tricorder.Effects.BrickChan qualified as BrickChan
import Tricorder.Watch.State qualified as Model


-- | Connect to the daemon and render a live-updating build status display using
-- a brick TUI. Quits on @q@ or @Esc@; arrow keys scroll the viewport.
watchDisplay
    :: ( Brick :> es
       , BrickChan :> es
       , Clock :> es
       , Conc :> es
       , File :> es
       , UnixSocket :> es
       )
    => FilePath -> Eff es ()
watchDisplay sockPath = do
    chan <- BrickChan.newBChan 10
    initialState <- Model.init
    Conc.scoped do
        _ <-
            Conc.fork
                $ queryWatch sockPath
                $ BrickChan.writeBChan chan . NewBuildState
        void
            $ Brick.runBrickApp
                chan
                watchApp
                initialState


watchApp :: App State Event Name
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
                    ]
                )
        , appChooseCursor = neverShowCursor
        }
