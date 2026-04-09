{-# OPTIONS_GHC -Wno-orphans #-}

module Ghcib.Config
    ( Config (..)
    , loadConfig
    , resolveCommand
    , resolveTargets
    , resolveWatchDirs
    , allComponentTargets
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
import System.FilePath (takeExtension, (</>))
import TOML (DecodeTOML (..), decode, getFieldOpt, getFieldOr)

import Data.Text qualified as T

import Atelier.Effects.FileSystem (FileSystem, doesFileExist, listDirectory, readFileBs)
import Atelier.Time (Millisecond)
import Atelier.Types.QuietSnake (QuietSnake (..))


data Config = Config
    { command :: Maybe Text
    , targets :: [Text]
    , watchDirs :: [FilePath]
    , debounceMs :: Millisecond
    , outputFile :: Maybe FilePath
    , logFile :: Maybe FilePath
    , metricsPort :: Maybe Int
    }
    deriving stock (Eq, Generic, Show)
    deriving (FromJSON) via QuietSnake Config


instance Default Config where
    def =
        Config
            { command = Nothing
            , targets = []
            , watchDirs = []
            , debounceMs = 100
            , outputFile = Just "build.json"
            , logFile = Nothing
            , metricsPort = Nothing
            }


-- Orphan instance — lives here since Millisecond is not in ghcib's dependency tree
instance DecodeTOML Millisecond where
    tomlDecoder = fromInteger <$> tomlDecoder


instance DecodeTOML Config where
    tomlDecoder = do
        command <- getFieldOpt "command"
        targets <- getFieldOr [] "targets"
        watchDirs <- getFieldOr [] "watch_dirs"
        debounceMs <- getFieldOr 100 "debounce_ms"
        outputFile <- getFieldOr (Just "build.json") "output_file"
        logFile <- getFieldOpt "log_file"
        metricsPort <- getFieldOpt "metrics_port"
        pure
            Config
                { command = command
                , targets = targets
                , watchDirs = watchDirs
                , debounceMs = debounceMs
                , outputFile = outputFile
                , logFile = logFile
                , metricsPort = metricsPort
                }


-- | Load config from .ghcib.toml in the project root, falling back to defaults.
-- CLI flags should be merged on top by the caller.
loadConfig :: (FileSystem :> es) => FilePath -> Eff es Config
loadConfig projectRoot = do
    let tomlPath = projectRoot </> ".ghcib.toml"
    exists <- doesFileExist tomlPath
    if exists then do
        content <- readFileBs tomlPath
        case decode (decodeUtf8 content) of
            Left _ -> pure def
            Right cfg -> pure cfg
    else
        pure def


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
