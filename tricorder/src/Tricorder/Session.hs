module Tricorder.Session
    ( Session (..)
    , Config (..)
    , loadSession
    , resolveCommand
    , resolveTargets
    , discoverCabalFiles
    , allComponentTargets
    , resolveTestTargets
    , resolveWatchDirs
    , sourceDirsForTarget
    ) where

import Atelier.Config (LoadedConfig, extractConfig)
import Atelier.Effects.FileSystem (FileSystem, doesFileExist, listDirectory, readFileBs)
import Atelier.Effects.Log (Log)
import Atelier.Types.QuietSnake (QuietSnake (..))
import Atelier.Types.WithDefaults (WithDefaults (..))
import Data.Aeson (FromJSON)
import Data.Default (Default (..))
import Data.List (nub)
import Distribution.Fields (Field (..), FieldLine (..), Name (..), readFields)
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
import Effectful.Reader.Static (Reader, ask)
import System.FilePath (normalise, takeDirectory, takeExtension, (</>))

import Atelier.Effects.Log qualified as Log
import Data.ByteString.Char8 qualified as BC
import Data.Text qualified as T

import Tricorder.Runtime (ProjectRoot (..))


data Session = Session
    { command :: Text
    , targets :: [Text]
    , testTargets :: [Text]
    , watchDirs :: [FilePath]
    , replBuildDir :: FilePath
    , testTimeout :: Int
    }


instance Default Session where
    def =
        Session
            { command = ""
            , targets = []
            , testTargets = []
            , watchDirs = []
            , replBuildDir = "/tmp"
            , testTimeout = 10
            }


data Config = Config
    { command :: Maybe Text
    , targets :: [Text]
    , watchDirs :: [FilePath]
    , testTargets :: Maybe [Text]
    , replBuildDir :: FilePath
    , testTimeout :: Int
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
            , replBuildDir = "dist-newstyle/tricorder"
            , testTimeout = 10
            }


-- | Resolve the GHCi command, using config if set or autodetecting otherwise.
--
-- The @testTargets@ are the discovered @test:@ components; they are appended to
-- the auto-detected @all@ target (see 'detectCommand'). They are ignored when
-- the user has pinned an explicit @command@ or explicit @targets@ in config.
resolveCommand :: (FileSystem :> es) => ProjectRoot -> Config -> [Text] -> Eff es Text
resolveCommand projectRoot cfg testTargets =
    case cfg.command of
        Just cmd -> pure cmd
        Nothing -> detectCommand cfg.targets testTargets cfg.replBuildDir projectRoot


-- | Build the autodetected GHCi command.
--
-- Configured @targets@ are spelled out verbatim. Otherwise we use cabal's
-- catch-all @all@ plus the discovered @test:@ targets, because
-- @cabal repl --enable-multi-repl all@ omits test suites unless the project sets
-- @tests: True@ in @cabal.project@ — so test errors would go unnoticed.
--
-- We keep @all@ rather than enumerating every component: @all@ lets cabal order
-- the multi-repl units, and GHCi makes the /last/ unit the active one. If that
-- unit imports a custom @Prelude@ from a sibling home package, GHCi reports it
-- "not loaded" and the session dies — which a naive discovery-order enumeration
-- triggers but @all@ avoids. Appending already-included test targets is a no-op
-- (cabal deduplicates).
detectCommand :: (FileSystem :> es) => [Text] -> [Text] -> FilePath -> ProjectRoot -> Eff es Text
detectCommand targets testTargets replBuildDir (ProjectRoot projectRoot) = do
    hasCabalProject <- doesFileExist (projectRoot </> "cabal.project")
    cabalFiles <- filter (\f -> takeExtension f == ".cabal") <$> listDirectory projectRoot
    hasStack <- doesFileExist (projectRoot </> "stack.yaml")
    let targetStr
            | not (null targets) = unwords targets
            | otherwise = unwords ("all" : testTargets)
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
resolveWatchDirs :: (FileSystem :> es) => ProjectRoot -> [FilePath] -> Config -> [Text] -> Eff es [FilePath]
resolveWatchDirs projectRoot cabalFiles cfg targets =
    case cfg.watchDirs of
        dirs@(_ : _) -> pure $ map (coerce projectRoot </>) dirs
        [] -> resolveWatchDirsFromTargets cabalFiles targets


resolveWatchDirsFromTargets :: (FileSystem :> es) => [FilePath] -> [Text] -> Eff es [FilePath]
resolveWatchDirsFromTargets _ [] = pure ["."]
resolveWatchDirsFromTargets cabalFiles targets = do
    dirs <- nub . concat <$> traverse watchDirsForCabal cabalFiles
    pure $ if null dirs then ["."] else dirs
  where
    -- @hs-source-dirs@ are relative to the package's own directory, so scope
    -- them to the directory holding that package's @.cabal@. In a
    -- single-package project that directory is the project root; in a
    -- multi-package project it's the per-package subdirectory. Targets that
    -- don't belong to this package yield no dirs.
    watchDirsForCabal cabalFile = do
        contents <- readFileBs cabalFile
        let pkgDir = takeDirectory cabalFile
        pure $ case parseGenericPackageDescriptionMaybe contents of
            Nothing -> []
            Just gpd -> map (pkgDir </>) (concatMap (sourceDirsForTarget gpd) targets)


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
-- Returns the configured targets as-is, or auto-detects all components across
-- every discovered package when no targets are configured.
resolveTargets :: (FileSystem :> es) => [FilePath] -> [Text] -> Eff es [Text]
resolveTargets _ targets@(_ : _) = pure targets
resolveTargets cabalFiles [] =
    concat <$> traverse targetsFromCabal cabalFiles
  where
    targetsFromCabal path = do
        contents <- readFileBs path
        pure $ maybe [] allComponentTargets (parseGenericPackageDescriptionMaybe contents)


-- | Locate every package's @.cabal@ file, logging what drove the result. In a
-- multi-package project the packages live in subdirectories listed under
-- @packages:@ in @cabal.project@; in a single-package project the @.cabal@
-- file(s) sit in the root. Called once per session load; the result is shared
-- by target and watch-dir resolution.
discoverCabalFiles :: (FileSystem :> es, Log :> es) => ProjectRoot -> Eff es [FilePath]
discoverCabalFiles (ProjectRoot projectRoot) = do
    hasProject <- doesFileExist projectFile
    cabalFiles <-
        if hasProject then do
            contents <- readFileBs projectFile
            concat <$> traverse cabalFilesForEntry (projectPackageEntries contents)
        else
            cabalFilesIn projectRoot
    let listed
            | null cabalFiles = "none"
            | otherwise = T.intercalate ", " (map toText cabalFiles)
    if hasProject then
        Log.info
            $ "Found cabal.project; discovered "
                <> show (length cabalFiles)
                <> " package cabal file(s): "
                <> listed
    else
        Log.info $ "No cabal.project; using cabal file(s) in project root: " <> listed
    pure cabalFiles
  where
    projectFile = projectRoot </> "cabal.project"

    -- A @packages:@ entry is either a direct path to a @.cabal@ file or a
    -- directory to search for one.
    cabalFilesForEntry entry
        | takeExtension entry == ".cabal" = pure [projectRoot </> entry]
        | otherwise = cabalFilesIn (normalise (projectRoot </> entry))


-- | List the @.cabal@ files directly inside a directory.
cabalFilesIn :: (FileSystem :> es) => FilePath -> Eff es [FilePath]
cabalFilesIn dir = do
    entries <- filter (\f -> takeExtension f == ".cabal") <$> listDirectory dir
    pure $ map (dir </>) entries


-- | Extract the directory/file entries from the @packages:@ field of a
-- @cabal.project@. Glob entries (containing @*@) are not expanded and are
-- skipped.
projectPackageEntries :: ByteString -> [FilePath]
projectPackageEntries contents =
    case readFields contents of
        Left _ -> []
        Right fields -> filter (notElem '*') (concatMap fromField fields)
  where
    fromField (Field (Name _ name) fieldLines)
        | name == "packages" = concatMap fromLine fieldLines
    fromField _ = []
    fromLine (FieldLine _ bs) = map BC.unpack (BC.words bs)


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


loadSession
    :: ( FileSystem :> es
       , Log :> es
       , Reader LoadedConfig :> es
       , Reader ProjectRoot :> es
       )
    => Eff es Session
loadSession = do
    projectRoot <- ask @ProjectRoot
    loadedCfg <- ask
    let cfgFile = extractConfig @"session" @Config loadedCfg
    cabalFiles <- discoverCabalFiles projectRoot
    effectiveTargets <- resolveTargets cabalFiles cfgFile.targets
    let testTargets = resolveTestTargets cfgFile effectiveTargets
    command <- resolveCommand projectRoot cfgFile testTargets
    watchDirs <- resolveWatchDirs projectRoot cabalFiles cfgFile effectiveTargets
    pure
        $ Session
            { targets = effectiveTargets
            , command
            , watchDirs
            , testTargets
            , replBuildDir = cfgFile.replBuildDir
            , testTimeout = cfgFile.testTimeout
            }
