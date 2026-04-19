module Tricorder.Watcher
    ( component
    ) where

import Effectful.Reader.Static (Reader, ask)
import System.FilePath (takeExtension, takeFileName)

import Atelier.Component (Component (..), defaultComponent)
import Atelier.Effects.FileSystem (FileSystem, getCurrentDirectory)
import Atelier.Effects.FileWatcher (FileWatcher, Watch, containing, dirExt, dirWhere, excluding, watchFilePaths)
import Tricorder.BuildState (ChangeKind (..))
import Tricorder.Config (Config, resolveWatchDirs)
import Tricorder.Effects.BuildStore (BuildStore, markDirty)


-- | Watcher component.
-- Watches source files and cabal-related files for changes, setting the dirty
-- flag in 'BuildStore'. 'GhciSession' polls this flag and triggers a rebuild
-- or session restart accordingly.
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
            dirs <- resolveWatchDirs cfg projectRoot
            let watches = sourceWatches dirs <> cabalWatches projectRoot
            pure [forever $ watchFilePaths watches \path -> markDirty (changeKindFor path)]
        }


sourceWatches :: [FilePath] -> [Watch]
sourceWatches dirs = map (\d -> dirExt d ".hs" `excluding` containing "dist-newstyle") dirs


cabalWatches :: FilePath -> [Watch]
cabalWatches projectRoot = [dirWhere projectRoot isCabalFile]


isCabalFile :: FilePath -> Bool
isCabalFile f =
    takeExtension f == ".cabal"
        || takeFileName f `elem` ["cabal.project", "package.yaml"]


changeKindFor :: FilePath -> ChangeKind
changeKindFor path
    | isCabalFile path = CabalChange
    | otherwise = SourceChange
