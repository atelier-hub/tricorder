module Tricorder.Watch
    ( watchDisplay
    ) where

import Atelier.Effects.Clock (Clock, currentTimeZone)
import Atelier.Effects.File (File)
import Tricorder.BuildState (BuildState)
import Tricorder.Effects.Display (Display, putDocLn, resetScreen)
import Tricorder.Effects.UnixSocket (UnixSocket)
import Tricorder.Render (buildStateDoc)
import Tricorder.Socket.Client (queryWatch)


-- | Connect to the daemon and render a live-updating build status display.
watchDisplay :: (Clock :> es, Display :> es, File :> es, UnixSocket :> es) => FilePath -> Eff es ()
watchDisplay sockPath = do
    resetScreen
    putDocLn "Waiting for build..."
    queryWatch sockPath renderState


renderState :: (Clock :> es, Display :> es) => BuildState -> Eff es ()
renderState bs = do
    tz <- currentTimeZone
    resetScreen
    putDocLn (buildStateDoc tz bs)
