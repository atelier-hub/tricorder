module Ghcib.Watcher
    ( component
    ) where

import Effectful.Reader.Static (Reader, ask)
import System.FilePath (takeExtension, takeFileName)

import Atelier.Component (Component (..), defaultComponent)
import Atelier.Effects.FileSystem (FileSystem, getCurrentDirectory)
import Ghcib.BuildState (ChangeKind (..))
import Ghcib.Config (Config (..), resolveWatchDirs)
import Ghcib.Effects.BuildStore (BuildStore, markDirty)
import Ghcib.Effects.FileWatcher (FileWatcher, watchDirs)


-- | Watcher component.
-- Watches relevant source files for changes and sets the dirty flag in
-- 'BuildStore'. 'GhciSession' polls this flag and triggers a rebuild whenever
-- it transitions to @True@.
component
    :: ( BuildStore :> es
       , FileSystem :> es
       , FileWatcher :> es
       , Reader Config :> es
       )
    => Component es
component =
    defaultComponent
        { name = "Watcher"
        , triggers = do
            cfg <- ask @Config
            projectRoot <- getCurrentDirectory
            dirs <- resolveWatchDirs cfg.targets projectRoot
            pure [forever $ watchDirs dirs \path -> markDirty (changeKindFor path)]
        }


changeKindFor :: FilePath -> ChangeKind
changeKindFor path
    | takeExtension path == ".cabal" = CabalChange
    | takeFileName path `elem` ["cabal.project", "package.yaml"] = CabalChange
    | otherwise = SourceChange
