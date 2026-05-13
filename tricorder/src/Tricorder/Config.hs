module Tricorder.Config
    ( LoadedConfig (..)
    , runLoadedConfig
    , restartOnConfigChange
    ) where

import Data.List (isSuffixOf)
import Effectful.Concurrent.MVar (Concurrent, newEmptyMVar, putMVar, takeMVar)
import Effectful.Reader.Static (Reader, ask, runReader)
import System.FilePath ((</>))

import Data.Aeson qualified as Aeson
import Data.Aeson.KeyMap qualified as KM
import Data.Yaml qualified as Yaml

import Atelier.Config (LoadedConfig (..))
import Atelier.Effects.Conc (Conc)
import Atelier.Effects.Debounce (Debounce)
import Atelier.Effects.FileSystem (FileSystem)
import Atelier.Effects.FileWatcher (FileWatcher)
import Tricorder.Runtime (ProjectRoot (..))

import Atelier.Effects.Conc qualified as Conc
import Atelier.Effects.FileSystem qualified as FileSystem
import Atelier.Effects.FileWatcher qualified as FileWatcher


-- | Load config from .tricorder.yaml in the project root.
-- Falls back to empty config (all defaults) if the file is absent or cannot be parsed.
loadTricorderConfig :: (FileSystem :> es) => FilePath -> Eff es LoadedConfig
loadTricorderConfig projectRoot = do
    exists <- FileSystem.doesFileExist yamlPath
    if not exists then
        pure $ LoadedConfig (Aeson.Object KM.empty)
    else do
        bs <- FileSystem.readFileBs yamlPath
        pure . LoadedConfig $ case Yaml.decodeEither' @Aeson.Value bs of
            Left _ -> Aeson.Object KM.empty
            Right v -> v
  where
    yamlPath = projectRoot </> configFileName


configFileName :: FilePath
configFileName = ".tricorder.yaml"


runLoadedConfig
    :: ( FileSystem :> es
       , Reader ProjectRoot :> es
       )
    => Eff (Reader LoadedConfig : es) a -> Eff es a
runLoadedConfig act = do
    ProjectRoot projectRoot <- ask
    cfg <- loadTricorderConfig projectRoot
    runReader cfg act


restartOnConfigChange
    :: ( Conc :> es
       , Concurrent :> es
       , Debounce FilePath :> es
       , FileWatcher :> es
       , Reader ProjectRoot :> es
       )
    => Eff es a -> Eff es a
restartOnConfigChange act = do
    ProjectRoot projectRoot <- ask
    ref <- newEmptyMVar
    var <- Conc.scoped do
        void $ Conc.fork do
            res <- act
            putMVar ref $ Just res

        Conc.fork_ $ FileWatcher.watchFilePathsDebounced
            [FileWatcher.dirWhere projectRoot (configFileName `isSuffixOf`)]
            \_ -> putMVar ref Nothing

        takeMVar ref
    case var of
        Nothing -> restartOnConfigChange act
        Just x -> pure x
