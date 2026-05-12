module Tricorder.Session
    ( Session (..)
    , Config (..)
    , runSession
    , resolveCommand
    , resolveTargets
    , allComponentTargets
    , resolveTestTargets
    , resolveWatchDirs
    , sourceDirsForTarget
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

import Data.Text qualified as T

import Atelier.Config (LoadedConfig, extractConfig)
import Atelier.Effects.FileSystem (FileSystem, doesFileExist, listDirectory, readFileBs)
import Atelier.Types.QuietSnake (QuietSnake (..))
import Atelier.Types.WithDefaults (WithDefaults (..))
import Tricorder.Runtime (ProjectRoot (..))


data Session = Session
    { command :: Text
    , targets :: [Text]
    , testTargets :: [Text]
    , watchDirs :: [FilePath]
    , outputFile :: Maybe FilePath
    , replBuildDir :: FilePath
    }


instance Default Session where
    def =
        Session
            { command = ""
            , targets = []
            , testTargets = []
            , watchDirs = []
            , outputFile = Nothing
            , replBuildDir = "/tmp"
            }


data Config = Config
    { command :: Maybe Text
    , targets :: [Text]
    , watchDirs :: [FilePath]
    , testTargets :: Maybe [Text]
    , outputFile :: Maybe FilePath
    , replBuildDir :: FilePath
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
            , replBuildDir = "dist-newstyle/tricorder"
            }


-- | Resolve the GHCi command, using config if set or autodetecting otherwise.
resolveCommand :: (FileSystem :> es) => ProjectRoot -> Config -> Eff es Text
resolveCommand projectRoot cfg =
    case cfg.command of
        Just cmd -> pure cmd
        Nothing -> detectCommand cfg.targets cfg.replBuildDir projectRoot


detectCommand :: (FileSystem :> es) => [Text] -> FilePath -> ProjectRoot -> Eff es Text
detectCommand targets replBuildDir (ProjectRoot projectRoot) = do
    hasCabalProject <- doesFileExist (projectRoot </> "cabal.project")
    cabalFiles <- filter (\f -> takeExtension f == ".cabal") <$> listDirectory projectRoot
    hasStack <- doesFileExist (projectRoot </> "stack.yaml")
    let targetStr = if null targets then "all" else unwords targets
        buildDirFlag = "--builddir " <> toText replBuildDir <> " "
    pure
        if
            | hasCabalProject || not (null cabalFiles) ->
                "cabal repl --enable-multi-repl " <> buildDirFlag <> targetStr
            | hasStack -> "stack ghci " <> targetStr
            | otherwise -> "cabal repl " <> buildDirFlag <> targetStr


-- | Resolve the directories to watch.
--
-- Priority:
-- 1. @watch_dirs@ from config, if non-empty (used as-is relative to project root)
-- 2. @hs-source-dirs@ inferred from cabal targets, if targets are set
-- 3. Falls back to @["."]@ (project root) if neither is available
resolveWatchDirs :: (FileSystem :> es) => ProjectRoot -> Config -> [Text] -> Eff es [FilePath]
resolveWatchDirs projectRoot cfg targets =
    case cfg.watchDirs of
        dirs@(_ : _) -> pure $ map (coerce projectRoot </>) dirs
        [] -> resolveWatchDirsFromTargets targets projectRoot


resolveWatchDirsFromTargets :: (FileSystem :> es) => [Text] -> ProjectRoot -> Eff es [FilePath]
resolveWatchDirsFromTargets [] _ = pure ["."]
resolveWatchDirsFromTargets targets (ProjectRoot projectRoot) = do
    cabalFiles <- filter ((== ".cabal") . takeExtension) <$> listDirectory projectRoot
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


-- | Infer the effective targets to build and watch.
-- Returns the configured targets as-is, or auto-detects all components
-- from the .cabal file when no targets are configured.
resolveTargets :: (FileSystem :> es) => ProjectRoot -> [Text] -> Eff es [Text]
resolveTargets _ targets@(_ : _) = pure targets
resolveTargets (ProjectRoot projectRoot) [] = do
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


-- | Resolve which test suites to run after a clean build.
--
-- When 'testTargets' is set in config, those suites are used directly.
-- Otherwise, all @test:@ components in 'targets' are inferred.
resolveTestTargets :: Config -> [Text] -> [Text]
resolveTestTargets cfg targets = case cfg.testTargets of
    Just explicit -> explicit
    Nothing -> filter ("test:" `T.isPrefixOf`) targets


runSession
    :: ( FileSystem :> es
       , HasCallStack
       , Reader LoadedConfig :> es
       , Reader ProjectRoot :> es
       )
    => Eff (Reader Session : es) a
    -> Eff es a
runSession act = do
    projectRoot <- ask @ProjectRoot
    loadedCfg <- ask
    let cfgFile = extractConfig @"session" @Config loadedCfg
    effectiveTargets <- resolveTargets projectRoot cfgFile.targets
    command <- resolveCommand projectRoot cfgFile
    watchDirs <- resolveWatchDirs projectRoot cfgFile effectiveTargets
    let testTargets = resolveTestTargets cfgFile effectiveTargets
        cfg =
            Session
                { targets = effectiveTargets
                , command
                , watchDirs
                , testTargets
                , outputFile = cfgFile.outputFile
                , replBuildDir = cfgFile.replBuildDir
                }
    runReader cfg act
