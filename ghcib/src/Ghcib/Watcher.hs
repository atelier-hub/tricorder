module Ghcib.Watcher
    ( component
    ) where

import Effectful (IOE)
import Effectful.Reader.Static (Reader, ask)
import System.Directory (getCurrentDirectory)

import Atelier.Component (Component (..), defaultComponent)
import Ghcib.Config (Config (..), resolveWatchDirs)
import Ghcib.Effects.BuildStore (BuildStore, markDirty)
import Ghcib.Effects.FileWatcher (FileWatcher, watchDirs)


-- | Watcher component.
-- Watches relevant source files for changes and sets the dirty flag in
-- 'BuildStore'. 'GhciSession' polls this flag and triggers a rebuild whenever
-- it transitions to @True@.
component
    :: ( BuildStore :> es
       , FileWatcher :> es
       , IOE :> es
       , Reader Config :> es
       )
    => Component es
component =
    defaultComponent
        { name = "Watcher"
        , triggers = do
            cfg <- ask @Config
            projectRoot <- liftIO getCurrentDirectory
            dirs <- liftIO $ resolveWatchDirs cfg.targets projectRoot
            pure [forever $ watchDirs dirs \_ -> markDirty]
        }
