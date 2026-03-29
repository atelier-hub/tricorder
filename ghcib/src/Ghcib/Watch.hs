module Ghcib.Watch
    ( watchDisplay
    ) where

import Effectful (IOE)

import Ghcib.BuildState (BuildState)
import Ghcib.Effects.Display (Display, putDocLn, resetScreen)
import Ghcib.Effects.UnixSocket (UnixSocket)
import Ghcib.Render (buildStateDoc)
import Ghcib.Socket.Client (queryWatch)


-- | Connect to the daemon and render a live-updating build status display.
watchDisplay :: (Display :> es, IOE :> es, UnixSocket :> es) => FilePath -> Eff es ()
watchDisplay sockPath = do
    resetScreen
    putDocLn "Waiting for build..."
    queryWatch sockPath renderState


renderState :: (Display :> es) => BuildState -> Eff es ()
renderState bs = do
    resetScreen
    putDocLn (buildStateDoc bs)
