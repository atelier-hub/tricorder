module Tricorder.Watcher
    ( component
    , WatcherSession
    , FileChangeDetected (..)
    , isCabalFile
    , markWatchedFiles
    ) where

import Effectful.Reader.Static (Reader, ask)
import Effectful.State.Static.Shared (evalState, get, put)
import System.FilePath (takeExtension, takeFileName)

import Atelier.Component (Component (..), defaultComponent)
import Atelier.Effects.Conc (Conc)
import Atelier.Effects.Debounce (Debounce)
import Atelier.Effects.FileWatcher
    ( FileEvent
    , FileWatcher
    , Watch
    , containing
    , dirExt
    , dirWhere
    , excluding
    , watchFilePathsDebounced
    )
import Atelier.Effects.Input (Input, input)
import Atelier.Effects.Publishing (Pub, Sub, publish)
import Tricorder.BuildState
    ( CabalChangeDetected (..)
    , ChangeKind (..)
    , SourceChangeDetected (..)
    )
import Tricorder.Effects.BuildStore (BuildStore)
import Tricorder.Events.Restart (Restart (..))
import Tricorder.Runtime (ProjectRoot (..))
import Tricorder.Session (Session (..))

import Atelier.Effects.Publishing qualified as Sub
import Tricorder.Effects.BuildStore qualified as BuildStore
import Tricorder.Events.Restart qualified as Restart
import Tricorder.SessionStore qualified as SessionStore


component
    :: ( BuildStore :> es
       , Conc :> es
       , Debounce FilePath :> es
       , FileWatcher :> es
       , Input Session :> es
       , Pub (Restart WatcherSession) :> es
       , Pub CabalChangeDetected :> es
       , Pub FileChangeDetected :> es
       , Pub SourceChangeDetected :> es
       , Reader ProjectRoot :> es
       , Sub (Restart WatcherSession) :> es
       , Sub FileChangeDetected :> es
       , Sub SessionStore.Reloaded :> es
       )
    => Component es
component =
    defaultComponent
        { name = "Watcher"
        , listeners = do
            session <- input
            pure
                [ Restart.onEvent watchFiles $ Restart $ mkWatcherSession session
                , Sub.listen_ markWatchedFiles
                , restartOnSessionReload session
                ]
        }


mkWatcherSession :: Session -> WatcherSession
mkWatcherSession = WatcherSession . (.watchDirs)


markWatchedFiles
    :: ( BuildStore :> es
       , Pub CabalChangeDetected :> es
       , Pub SourceChangeDetected :> es
       )
    => FileChangeDetected -> Eff es ()
markWatchedFiles f = do
    BuildStore.markDirty change
    case change of
        CabalChange -> publish CabalChangeDetected
        SourceChange -> publish (SourceChangeDetected f.path f.event)
  where
    change = changeKindFor f.path


data FileChangeDetected = FileChangeDetected
    { path :: FilePath
    , event :: FileEvent
    }


data WatcherSession = WatcherSession
    { watchDirs :: [FilePath]
    }
    deriving stock (Eq)


watchFiles
    :: ( Debounce FilePath :> es
       , FileWatcher :> es
       , Pub FileChangeDetected :> es
       , Reader ProjectRoot :> es
       )
    => WatcherSession -> Eff es Void
watchFiles session = do
    projectRoot <- ask
    let watches = sourceWatches session.watchDirs <> cabalWatches projectRoot
    watchFilePathsDebounced watches \filePath fileEvent ->
        publish (FileChangeDetected filePath fileEvent)


restartOnSessionReload
    :: ( Pub (Restart WatcherSession) :> es
       , Sub SessionStore.Reloaded :> es
       )
    => Session -> Eff es Void
restartOnSessionReload initialSession = evalState initial $ forever do
    SessionStore.Reloaded session <- Sub.listenOnce_
    let new = mkWatcherSession session
    old <- get
    when (old /= new) do
        put new
        publish $ Restart new
  where
    initial = mkWatcherSession initialSession


sourceWatches :: [FilePath] -> [Watch]
sourceWatches = map (\d -> dirExt d ".hs" `excluding` containing "dist-newstyle")


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
