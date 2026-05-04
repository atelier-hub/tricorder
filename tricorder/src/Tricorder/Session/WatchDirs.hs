module Tricorder.Session.WatchDirs
    ( WatchDirs (..)
    , asReader
    , sourceDirsForTarget
    ) where

import Data.Aeson (FromJSON, ToJSON)
import Data.Default (Default (..))
import Data.List (nub)
import Distribution.PackageDescription.Parsec (parseGenericPackageDescriptionMaybe)
import Distribution.Types.BuildInfo (hsSourceDirs)
import Distribution.Types.CondTree (condTreeData)
import Distribution.Types.Executable (buildInfo)
import Distribution.Types.GenericPackageDescription
    ( GenericPackageDescription
    , condExecutables
    , condLibrary
    , condSubLibraries
    , condTestSuites
    , packageDescription
    )
import Distribution.Types.Library (libBuildInfo)
import Distribution.Types.PackageDescription (package)
import Distribution.Types.PackageId (pkgName)
import Distribution.Types.PackageName (unPackageName)
import Distribution.Types.TestSuite (testBuildInfo)
import Distribution.Types.UnqualComponentName (mkUnqualComponentName)
import Distribution.Utils.Path (getSymbolicPath)
import Effectful.Reader.Static (Reader, ask, asks, runReader)
import GHC.Generics (Generically (..))
import System.FilePath (takeExtension, (</>))

import Data.Text qualified as T

import Atelier.Config (LoadedConfig, runConfig)
import Atelier.Effects.FileSystem (FileSystem, listDirectory, readFileBs)
import Atelier.Types.QuietSnake (QuietSnake (..))
import Atelier.Types.WithDefaults (WithDefaults (..))
import Tricorder.Session.ProjectRoot (ProjectRoot (..))
import Tricorder.Session.Targets (Targets (..))


newtype WatchDirs = WatchDirs {getWatchDirs :: [FilePath]}


newtype Config = Config
    { watchDirs :: [FilePath]
    }
    deriving stock (Generic)
    deriving (ToJSON) via (Generically Config)
    deriving (FromJSON) via (WithDefaults (QuietSnake Config))


instance Default Config where
    def =
        Config
            { watchDirs = []
            }


asReader
    :: ( FileSystem :> es
       , Reader LoadedConfig :> es
       , Reader ProjectRoot :> es
       , Reader Targets :> es
       )
    => Eff (Reader WatchDirs : es) a -> Eff es a
asReader act = do
    cfg <- runConfig @"session" @Config ask
    projectRoot <- asks @ProjectRoot (.getProjectRoot)
    watchDirs <- resolveWatchDirs cfg projectRoot
    runReader (WatchDirs watchDirs) act


-- | Resolve the directories to watch.
--
-- Priority:
-- 1. @watch_dirs@ from config, if non-empty (used as-is relative to project root)
-- 2. @hs-source-dirs@ inferred from cabal targets, if targets are set
-- 3. Falls back to @["."]@ (project root) if neither is available
resolveWatchDirs
    :: (FileSystem :> es, Reader Targets :> es)
    => Config
    -> FilePath
    -> Eff es [FilePath]
resolveWatchDirs cfg projectRoot = do
    targets <- asks (.getTargets)
    case cfg.watchDirs of
        dirs@(_ : _) -> pure (map (projectRoot </>) dirs)
        [] -> resolveWatchDirsFromTargets targets projectRoot


resolveWatchDirsFromTargets :: (FileSystem :> es) => [Text] -> FilePath -> Eff es [FilePath]
resolveWatchDirsFromTargets [] _ = pure ["."]
resolveWatchDirsFromTargets targets projectRoot = do
    cabalFiles <- filter (\f -> takeExtension f == ".cabal") <$> listDirectory projectRoot
    case cabalFiles of
        [] -> pure ["."]
        (cabalFile : _) -> do
            contents <- readFileBs (projectRoot </> cabalFile)
            case parseGenericPackageDescriptionMaybe contents of
                Nothing -> pure ["."]
                Just gpd ->
                    let dirs = nub $ concatMap (sourceDirsForTarget gpd) targets
                    in  pure $ if null dirs then ["."] else map (projectRoot </>) dirs


sourceDirsForTarget :: GenericPackageDescription -> Text -> [FilePath]
sourceDirsForTarget gpd target =
    map getSymbolicPath $ case T.splitOn ":" target of
        ["lib", ""] ->
            maybe [] (libDirs . condTreeData) (condLibrary gpd)
        ["lib", name] ->
            let ucn = mkUnqualComponentName (toString name)
                mainLibName = unPackageName . pkgName . package . packageDescription $ gpd
            in  if toString name == mainLibName then
                    maybe [] (libDirs . condTreeData) (condLibrary gpd)
                else
                    concatMap (libDirs . condTreeData . snd) $ filter ((== ucn) . fst) (condSubLibraries gpd)
        ["test", name] ->
            let ucn = mkUnqualComponentName (toString name)
            in  concatMap (testDirs . condTreeData . snd) $ filter ((== ucn) . fst) (condTestSuites gpd)
        ["exe", name] ->
            let ucn = mkUnqualComponentName (toString name)
            in  concatMap (exeDirs . condTreeData . snd) $ filter ((== ucn) . fst) (condExecutables gpd)
        _ -> []
  where
    libDirs = hsSourceDirs . libBuildInfo
    testDirs = hsSourceDirs . testBuildInfo
    exeDirs = hsSourceDirs . buildInfo
