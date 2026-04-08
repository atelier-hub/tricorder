module Ghcib.Watch
    ( watchDisplay
    ) where

import Atelier.Effects.Clock (Clock, currentTimeZone)
import Atelier.Effects.File (File)
import Ghcib.BuildState (BuildState)
import Ghcib.Effects.Display (Display, putDocLn, resetScreen)
import Ghcib.Effects.UnixSocket (UnixSocket)
import Ghcib.Render (buildStateDoc)
import Ghcib.Socket.Client (queryWatch)


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
