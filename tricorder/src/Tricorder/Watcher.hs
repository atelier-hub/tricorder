module Tricorder.Watcher
    ( component
    , WatchedFile (..)
    , isCabalFile
    , markWatchedFiles
    ) where

import Effectful.Reader.Static (Reader, ask)
import System.FilePath (takeExtension, takeFileName)

import Atelier.Component (Component (..), defaultComponent)
import Atelier.Effects.Debounce (Debounce)
import Atelier.Effects.FileWatcher
    ( FileWatcher
    , Watch
    , containing
    , dirExt
    , dirWhere
    , excluding
    , watchFilePathsDebounced
    )
import Atelier.Effects.Publishing (Pub, Sub, publish)
import Tricorder.BuildState
    ( CabalChangeDetected (..)
    , ChangeKind (..)
    , SourceChangeDetected (..)
    )
import Tricorder.Effects.BuildStore (BuildStore)
import Tricorder.Runtime (ProjectRoot (..))
import Tricorder.Session (Session (..))

import Atelier.Effects.Publishing qualified as Sub
import Tricorder.Effects.BuildStore qualified as BuildStore


-- | Watcher component.
-- Watches source files and cabal-related files for changes, setting the dirty
-- flag in 'BuildStore'. 'GhciSession' polls this flag and triggers a rebuild
-- or session restart accordingly.
component
    :: ( BuildStore :> es
       , Debounce FilePath :> es
       , FileWatcher :> es
       , Pub CabalChangeDetected :> es
       , Pub SourceChangeDetected :> es
       , Pub WatchedFile :> es
       , Reader ProjectRoot :> es
       , Reader Session :> es
       , Sub WatchedFile :> es
       )
    => Component es
component =
    defaultComponent
        { name = "Watcher"
        , triggers = do
            session <- ask @Session
            projectRoot <- ask
            let watches = sourceWatches session <> cabalWatches projectRoot
            pure
                [ watchFilePathsDebounced watches $ publish . WatchedFile
                ]
        , listeners =
            pure
                [ Sub.listen_ markWatchedFiles
                ]
        }


markWatchedFiles
    :: ( BuildStore :> es
       , Pub CabalChangeDetected :> es
       , Pub SourceChangeDetected :> es
       )
    => WatchedFile -> Eff es ()
markWatchedFiles f = do
    BuildStore.markDirty change
    case change of
        CabalChange -> publish CabalChangeDetected
        SourceChange -> publish SourceChangeDetected
  where
    change = changeKindFor . getWatchedFile $ f


newtype WatchedFile = WatchedFile {getWatchedFile :: FilePath}


sourceWatches :: Session -> [Watch]
sourceWatches = map (\d -> dirExt d ".hs" `excluding` containing "dist-newstyle") . (.watchDirs)


cabalWatches :: ProjectRoot -> [Watch]
cabalWatches (ProjectRoot projectRoot) = [dirWhere projectRoot isCabalFile]


isCabalFile :: FilePath -> Bool
isCabalFile f =
    takeExtension f == ".cabal"
        || takeFileName f `elem` ["cabal.project", "package.yaml"]


changeKindFor :: FilePath -> ChangeKind
changeKindFor path
    | isCabalFile path = CabalChange
    | otherwise = SourceChange
