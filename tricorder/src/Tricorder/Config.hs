module Tricorder.Config
    ( loadTricorderConfig
    , LoadedConfig (..)
    , runLoadedConfig
    ) where

import Effectful.Reader.Static (Reader, asks, runReader)
import System.FilePath ((</>))

import Data.Aeson qualified as Aeson
import Data.Aeson.KeyMap qualified as KM
import Data.Yaml qualified as Yaml

import Atelier.Config (LoadedConfig (..))
import Atelier.Effects.FileSystem (FileSystem, doesFileExist, readFileBs)
import Tricorder.Session.ProjectRoot (ProjectRoot (..))


-- | Load config from .tricorder.yaml in the project root.
-- Falls back to empty config (all defaults) if the file is absent or cannot be parsed.
loadTricorderConfig :: (FileSystem :> es) => FilePath -> Eff es LoadedConfig
loadTricorderConfig projectRoot = do
    exists <- doesFileExist yamlPath
    if not exists then
        pure $ LoadedConfig (Aeson.Object KM.empty)
    else do
        bs <- readFileBs yamlPath
        pure . LoadedConfig $ case Yaml.decodeEither' @Aeson.Value bs of
            Left _ -> Aeson.Object KM.empty
            Right v -> v
  where
    yamlPath = projectRoot </> ".tricorder.yaml"


runLoadedConfig
    :: ( FileSystem :> es
       , Reader ProjectRoot :> es
       )
    => Eff (Reader LoadedConfig : es) a -> Eff es a
runLoadedConfig act = do
    projectRoot <- asks (.getProjectRoot)
    cfg <- loadTricorderConfig projectRoot
    runReader cfg act
