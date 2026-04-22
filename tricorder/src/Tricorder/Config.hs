module Tricorder.Config
    ( Config (..)
    , loadTricorderConfig
    , resolveCommand
    , resolveTargets
    , resolveTestTargets
    , resolveWatchDirs
    , allComponentTargets
    , sourceDirsForTarget
    , runConfig
    ) where

import Data.Aeson (FromJSON)
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
import Distribution.Types.UnqualComponentName (mkUnqualComponentName, unUnqualComponentName)
import Distribution.Utils.Path (getSymbolicPath)
import Effectful.Reader.Static (Reader, ask, runReader)
import System.FilePath (takeExtension, (</>))

import Data.Aeson qualified as Aeson
import Data.Aeson.KeyMap qualified as KM
import Data.Text qualified as T
import Data.Yaml qualified as Yaml

import Atelier.Config (LoadedConfig (..), extractConfig)
import Atelier.Effects.FileSystem (FileSystem, doesFileExist, listDirectory, readFileBs)
import Atelier.Types.QuietSnake (QuietSnake (..))
import Atelier.Types.WithDefaults (WithDefaults (..))
import Tricorder.Runtime (ProjectRoot (..))

import Tricorder.Observability qualified as Observability


data Config = Config
    { command :: Maybe Text
    , targets :: [Text]
    , watchDirs :: [FilePath]
    , testTargets :: Maybe [Text]
    , outputFile :: Maybe FilePath
    }
    deriving stock (Eq, Generic, Show)
    deriving (FromJSON) via WithDefaults (QuietSnake Config)


instance Default Config where
    def =
        Config
            { command = Nothing
            , targets = []
            , watchDirs = []
            , testTargets = Nothing
            , outputFile = Just "build.json"
            }


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


-- | Resolve the GHCi command, using config if set or autodetecting otherwise.
resolveCommand :: (FileSystem :> es) => Config -> FilePath -> Eff es Text
resolveCommand cfg projectRoot =
    case cfg.command of
        Just cmd -> pure cmd
        Nothing -> detectCommand cfg.targets projectRoot


detectCommand :: (FileSystem :> es) => [Text] -> FilePath -> Eff es Text
detectCommand targets projectRoot = do
    hasCabalProject <- doesFileExist (projectRoot </> "cabal.project")
    cabalFiles <- filter (\f -> takeExtension f == ".cabal") <$> listDirectory projectRoot
    hasStack <- doesFileExist (projectRoot </> "stack.yaml")
    let targetStr = if null targets then "all" else unwords targets
    pure
        $ if
            | hasCabalProject -> "cabal repl --enable-multi-repl " <> targetStr
            | not (null cabalFiles) -> "cabal repl --enable-multi-repl " <> targetStr
            | hasStack -> "stack ghci " <> targetStr
            | otherwise -> "cabal repl " <> targetStr


-- | Resolve the directories to watch.
--
-- Priority:
-- 1. @watch_dirs@ from config, if non-empty (used as-is relative to project root)
-- 2. @hs-source-dirs@ inferred from cabal targets, if targets are set
-- 3. Falls back to @["."]@ (project root) if neither is available
resolveWatchDirs :: (FileSystem :> es) => Config -> FilePath -> Eff es [FilePath]
resolveWatchDirs cfg projectRoot =
    case cfg.watchDirs of
        dirs@(_ : _) -> pure (map (projectRoot </>) dirs)
        [] -> resolveWatchDirsFromTargets cfg.targets projectRoot


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


-- | Infer the effective targets to build and watch.
-- Returns the configured targets as-is, or auto-detects all components
-- from the .cabal file when no targets are configured.
resolveTargets :: (FileSystem :> es) => [Text] -> FilePath -> Eff es [Text]
resolveTargets targets@(_ : _) _ = pure targets
resolveTargets [] projectRoot = do
    cabalFiles <- filter (\f -> takeExtension f == ".cabal") <$> listDirectory projectRoot
    case cabalFiles of
        [] -> pure []
        (cabalFile : _) -> do
            contents <- readFileBs (projectRoot </> cabalFile)
            pure $ maybe [] allComponentTargets (parseGenericPackageDescriptionMaybe contents)


allComponentTargets :: GenericPackageDescription -> [Text]
allComponentTargets gpd =
    mainLibTargets
        ++ subLibTargets
        ++ exeTargets
        ++ testTargets
  where
    mainPkgName = toText $ unPackageName . pkgName . package . packageDescription $ gpd
    mainLibTargets = maybe [] (const ["lib:" <> mainPkgName]) (condLibrary gpd)
    subLibTargets = map (\(n, _) -> "lib:" <> toText (unUnqualComponentName n)) (condSubLibraries gpd)
    exeTargets = map (\(n, _) -> "exe:" <> toText (unUnqualComponentName n)) (condExecutables gpd)
    testTargets = map (\(n, _) -> "test:" <> toText (unUnqualComponentName n)) (condTestSuites gpd)


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


-- | Resolve which test suites to run after a clean build.
--
-- When 'testTargets' is set in config, those suites are used directly.
-- Otherwise, all @test:@ components in 'targets' are inferred.
resolveTestTargets :: Config -> [Text]
resolveTestTargets cfg = case cfg.testTargets of
    Just explicit -> explicit
    Nothing -> filter ("test:" `T.isPrefixOf`) cfg.targets


runConfig
    :: ( FileSystem :> es
       , HasCallStack
       , Reader ProjectRoot :> es
       )
    => Eff (Reader Config : Reader Observability.Config : es) a
    -> Eff es a
runConfig act = do
    ProjectRoot projectRoot <- ask
    loadedCfg <- loadTricorderConfig projectRoot
    let cfg = extractConfig @"session" loadedCfg
        obsCfg = extractConfig @"observability" loadedCfg
    effectiveTargets <- resolveTargets cfg.targets projectRoot
    let cfg' = cfg {targets = effectiveTargets}
    runReader obsCfg $ runReader cfg' act
