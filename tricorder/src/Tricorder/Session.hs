module Tricorder.Session
    ( Session (..)
    , Config (..)
    , Command (..)
    , TestTargets
    , getTestTargets
    , parseTestTargets
    , Target (..)
    , ComponentKind (..)
    , parseTarget
    , renderTarget
    , WatchDirs (..)
    , WatchExclusionPatterns (..)
    , ReplBuildDir (..)
    , TestTimeout (..)
    , Pattern
    , loadSession
    , resolveCommand
    , resolveTargets
    , discoverCabalFiles
    , allComponentTargets
    , resolveTestTargets
    , resolveWatchDirs
    , sourceDirsForTarget
    , compareTargets
    ) where

import Atelier.Config (LoadedConfig, extractConfig)
import Atelier.Effects.FileSystem (FileSystem, doesFileExist, listDirectory, readFileBs)
import Atelier.Effects.Log (Log)
import Atelier.Types.QuietSnake (QuietSnake (..))
import Atelier.Types.WithDefaults (WithDefaults (..))
import Data.Aeson (FromJSON (..), ToJSON (..))
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
import Effectful.Exception (throwIO)
import Effectful.Reader.Static (Reader, ask)
import System.FilePath (normalise, takeDirectory, takeExtension, (</>))
import System.IO.Error (userError)
import Text.Regex.TDFA.ReadRegex (parseRegex)

import Atelier.Effects.Log qualified as Log
import Data.ByteString.Char8 qualified as BC
import Data.Text qualified as T
import Text.Regex.TDFA.Pattern qualified as Regex

import Tricorder.Runtime (ProjectRoot (..))


data Session = Session
    { command :: Command
    , targets :: [Target]
    , testTargets :: TestTargets
    , watchDirs :: WatchDirs
    , watchExclusionPatterns :: WatchExclusionPatterns
    , replBuildDir :: ReplBuildDir
    , testTimeout :: TestTimeout
    }


type Pattern = (Regex.Pattern, (Regex.GroupIndex, Regex.DoPa))


instance Default Session where
    def =
        Session
            { command = Command ""
            , targets = []
            , testTargets = projectTestTargets []
            , watchDirs = WatchDirs []
            , watchExclusionPatterns = WatchExclusionPatterns []
            , replBuildDir = ReplBuildDir "/tmp"
            , testTimeout = TestTimeout 10
            }


data Config = Config
    { command :: Maybe Text
    , targets :: [Text]
    , watchDirs :: [FilePath]
    , watchExclusionPatterns :: [Text]
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
            , watchExclusionPatterns = []
            , testTargets = Nothing
            , replBuildDir = "dist-newstyle/tricorder"
            , testTimeout = 10
            }


newtype Command = Command {getCommand :: Text}
    deriving stock (Eq, Generic, Show)
    deriving (FromJSON, ToJSON) via Text


-- | The test suites to run after a clean build. Built only by projecting a
-- target list onto its @test:@ components via 'projectTestTargets'; the data
-- constructor is not exported, so a 'TestTargets' can never hold a non-test
-- target.
newtype TestTargets = TestTargets {getTestTargets :: [Target]}
    deriving stock (Eq, Generic, Show)
    deriving (FromJSON, ToJSON) via [Target]


-- | Project a target list onto its test suites — the only way to build a
-- 'TestTargets', so the @test:@-only invariant holds by construction.
projectTestTargets :: [Target] -> TestTargets
projectTestTargets = TestTargets . filter isTestTarget
  where
    isTestTarget (Qualified Test _) = True
    isTestTarget _ = False


-- | Parse raw target strings (e.g. the @test_targets@ config) and project them
-- onto their test suites — non-test entries are dropped.
parseTestTargets :: [Text] -> TestTargets
parseTestTargets = projectTestTargets . map parseTarget


-- | A cabal build target, parsed from its textual @[kind:]name@ form. Used to
-- resolve which source directories belong to a target.
data Target
    = -- | A @kind:name@ reference, e.g. @lib:foo@, @exe:foo@, @test:foo@. An
      -- empty name with 'Lib' (i.e. @lib:@) denotes the package's main library.
      Qualified ComponentKind Text
    | -- | A name with no @kind:@ prefix. Refers either to a package (all of its
      -- components) or to a single component matched by name.
      Bare Text
    | -- | A form we don't recognize: an unknown kind, or extra colons.
      Unrecognized Text
    deriving stock (Eq, Show)


-- | The kind of cabal component a 'Qualified' target names.
data ComponentKind = Lib | Exe | Test
    deriving stock (Bounded, Enum, Eq, Show)


-- | The textual prefix cabal uses for each component kind. Single source of
-- truth shared by 'parseTarget' and 'renderTarget' — keep this the only place
-- the prefix strings appear.
kindPrefix :: ComponentKind -> Text
kindPrefix = \case
    Lib -> "lib"
    Exe -> "exe"
    Test -> "test"


-- | Parse a kind prefix, derived as the inverse of 'kindPrefix' so the two
-- never drift apart.
parseKind :: Text -> Maybe ComponentKind
parseKind = inverseMap kindPrefix


-- | Classify a target's textual form. The grammar is @[kind:]name@ where
-- @kind@ is one of @lib@, @exe@, or @test@; anything else (an unknown kind, or
-- extra colons) is 'Unrecognized'.
parseTarget :: Text -> Target
parseTarget target = case T.splitOn ":" target of
    [prefix, name] | Just kind <- parseKind prefix -> Qualified kind name
    [name] -> Bare name
    _ -> Unrecognized target


-- | Render a 'Target' back to the textual form cabal understands. Inverse of
-- 'parseTarget' (lossless: @parseTarget . renderTarget == id@).
renderTarget :: Target -> Text
renderTarget = \case
    Qualified kind name -> kindPrefix kind <> ":" <> name
    Bare name -> name
    Unrecognized raw -> raw


instance ToJSON Target where
    toJSON = toJSON . renderTarget


instance FromJSON Target where
    parseJSON = fmap parseTarget . parseJSON


newtype WatchDirs = WatchDirs {getWatchDirs :: [FilePath]}
    deriving stock (Eq, Generic, Show)
    deriving (FromJSON, ToJSON) via [FilePath]


newtype WatchExclusionPatterns = WatchExclusionPatterns {getWatchExclusionPatterns :: [Pattern]}
    deriving stock (Eq, Generic, Show)


newtype ReplBuildDir = ReplBuildDir {getReplBuildDir :: FilePath}
    deriving stock (Eq, Generic, Show)
    deriving (FromJSON, ToJSON) via FilePath


newtype TestTimeout = TestTimeout {getTestTimeout :: Int}
    deriving stock (Eq, Generic, Show)
    deriving (FromJSON, ToJSON) via Int


-- | Resolve the GHCi command, using config if set or autodetecting otherwise.
--
-- The @testTargets@ are the discovered @test:@ components; they are appended to
-- the auto-detected @all@ target (see 'detectCommand'). They are ignored when
-- the user has pinned an explicit @command@ or explicit @targets@ in config.
resolveCommand :: (FileSystem :> es) => ProjectRoot -> Config -> [Target] -> TestTargets -> Eff es Command
resolveCommand projectRoot cfg targets testTargets =
    case cfg.command of
        Just cmd -> pure $ Command cmd
        Nothing -> detectCommand targets testTargets cfg.replBuildDir projectRoot


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
detectCommand :: (FileSystem :> es) => [Target] -> TestTargets -> FilePath -> ProjectRoot -> Eff es Command
detectCommand targets (TestTargets testTargets) replBuildDir (ProjectRoot projectRoot) = do
    hasCabalProject <- doesFileExist (projectRoot </> "cabal.project")
    cabalFiles <- filter (\f -> takeExtension f == ".cabal") <$> listDirectory projectRoot
    hasStack <- doesFileExist (projectRoot </> "stack.yaml")
    let targetStr
            | not (null targets) = unwords (map renderTarget targets)
            | otherwise = unwords ("all" : map renderTarget testTargets)
        buildDirFlag = "--builddir " <> toText replBuildDir <> " "
    pure
        if
            | hasCabalProject || not (null cabalFiles) ->
                Command $ "cabal repl --enable-multi-repl " <> buildDirFlag <> targetStr
            | hasStack -> Command $ "stack ghci " <> targetStr
            | otherwise -> Command $ "cabal repl " <> buildDirFlag <> targetStr


-- | Resolve the directories to watch.
--
-- Priority:
-- 1. @watch_dirs@ from config, if non-empty (used as-is relative to project root)
-- 2. @hs-source-dirs@ inferred from cabal targets, if targets are set
-- 3. Falls back to @["."]@ (project root) if neither is available
resolveWatchDirs :: (FileSystem :> es) => ProjectRoot -> [FilePath] -> Config -> [Target] -> Eff es WatchDirs
resolveWatchDirs projectRoot cabalFiles cfg targets =
    case cfg.watchDirs of
        dirs@(_ : _) -> pure $ WatchDirs $ map (coerce projectRoot </>) dirs
        [] -> resolveWatchDirsFromTargets cabalFiles targets


resolveWatchDirsFromTargets :: (FileSystem :> es) => [FilePath] -> [Target] -> Eff es WatchDirs
resolveWatchDirsFromTargets _ [] = pure $ WatchDirs ["."]
resolveWatchDirsFromTargets cabalFiles targets = do
    dirs <- nub . concat <$> traverse watchDirsForCabal cabalFiles
    pure $ WatchDirs $ if null dirs then ["."] else dirs
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


sourceDirsForTarget :: GenericPackageDescription -> Target -> [FilePath]
sourceDirsForTarget gpd target =
    map getSymbolicPath $ case target of
        Qualified Lib "" -> mainLibSourceDirs
        Qualified Lib name
            | toString name == mainPkgName -> mainLibSourceDirs
            | otherwise -> subLibSourceDirs name
        Qualified Exe name -> exeSourceDirs name
        Qualified Test name -> testSourceDirs name
        -- A bare target (no @kind:@ prefix) is a package name or a component
        -- name. A package name covers every component; otherwise match a
        -- single component by name across the kinds.
        Bare name
            | toString name == mainPkgName -> allComponentSourceDirs
            | otherwise -> subLibSourceDirs name <> exeSourceDirs name <> testSourceDirs name
        Unrecognized _ -> []
  where
    mainPkgName = unPackageName . pkgName . package . packageDescription $ gpd
    libDirs = hsSourceDirs . libBuildInfo
    testDirs = hsSourceDirs . testBuildInfo
    exeDirs = hsSourceDirs . buildInfo

    mainLibSourceDirs = maybe [] (libDirs . condTreeData) (condLibrary gpd)
    subLibSourceDirs name = dirsForComponent libDirs (condSubLibraries gpd) name
    exeSourceDirs name = dirsForComponent exeDirs (condExecutables gpd) name
    testSourceDirs name = dirsForComponent testDirs (condTestSuites gpd) name

    allComponentSourceDirs =
        mainLibSourceDirs
            <> concatMap (libDirs . condTreeData . snd) (condSubLibraries gpd)
            <> concatMap (exeDirs . condTreeData . snd) (condExecutables gpd)
            <> concatMap (testDirs . condTreeData . snd) (condTestSuites gpd)

    dirsForComponent dirs components name =
        let ucn = mkUnqualComponentName (toString name)
        in  concatMap (dirs . condTreeData . snd) $ filter ((== ucn) . fst) components


-- | Infer the effective targets to build and watch. This is the boundary where
-- raw target strings (from config) are parsed into structured 'Target's: the
-- configured targets are parsed as-is, or all components across every
-- discovered package are auto-detected when no targets are configured. Either
-- way the result is sorted with 'compareTargets' so libraries come last.
resolveTargets :: (FileSystem :> es) => [FilePath] -> [Text] -> Eff es [Target]
resolveTargets _ targets@(_ : _) = pure $ sortBy compareTargets $ map parseTarget targets
resolveTargets cabalFiles [] =
    sortBy compareTargets . concat <$> traverse targetsFromCabal cabalFiles
  where
    targetsFromCabal path = do
        contents <- readFileBs path
        pure $ maybe [] allComponentTargets (parseGenericPackageDescriptionMaybe contents)


-- | When running @cabal repl <package defining custom prelude> <other
-- packages...>@, GHCi fails because it attempts to load the provided @Prelude@
-- module before loading the package itself. This is not a problem if the
-- package defining the prelude module is not the first component listed.
--
-- Because of this GHCi quirk, we sort all packages beginning with @lib:@ last.
-- This is based on the assumption that components defining custom preludes
-- usually reside in libraries. If we can then place at least one target that
-- does not specify a custom prelude a before targets that do, we will prevent
-- the user from being hit with this rather obscure error message.
compareTargets :: Target -> Target -> Ordering
compareTargets a b
    | isLib a && not (isLib b) = GT
    | not (isLib a) && isLib b = LT
    | otherwise = compare (renderTarget a) (renderTarget b)
  where
    isLib (Qualified Lib _) = True
    isLib _ = False


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


allComponentTargets :: GenericPackageDescription -> [Target]
allComponentTargets gpd =
    mainLibTargets
        ++ subLibTargets
        ++ exeTargets
        ++ testTargets
  where
    mainPkgName = toText $ unPackageName . pkgName . package . packageDescription $ gpd
    mainLibTargets = maybe [] (const [Qualified Lib mainPkgName]) (condLibrary gpd)
    subLibTargets = map (\(n, _) -> Qualified Lib (componentName n)) (condSubLibraries gpd)
    exeTargets = map (\(n, _) -> Qualified Exe (componentName n)) (condExecutables gpd)
    testTargets = map (\(n, _) -> Qualified Test (componentName n)) (condTestSuites gpd)
    componentName = toText . unUnqualComponentName


-- | Resolve which test suites to run after a clean build. Either source — the
-- explicit @test_targets@ config or the build 'targets' — is projected onto its
-- @test:@ components (see 'projectTestTargets'), so non-test entries are
-- dropped and the result only ever names test suites.
resolveTestTargets :: Config -> [Target] -> TestTargets
resolveTestTargets cfg targets = case cfg.testTargets of
    Just explicit -> parseTestTargets explicit
    Nothing -> projectTestTargets targets


resolveWatchExclusionPatterns :: [Text] -> Eff es WatchExclusionPatterns
resolveWatchExclusionPatterns rawPatterns = do
    either (throwIO . userError . show) (pure . WatchExclusionPatterns)
        $ traverse
            ( parseRegex
                . toString
            )
            rawPatterns


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
    command <- resolveCommand projectRoot cfgFile effectiveTargets testTargets
    watchDirs <- resolveWatchDirs projectRoot cabalFiles cfgFile effectiveTargets
    watchExclusionPatterns <- resolveWatchExclusionPatterns cfgFile.watchExclusionPatterns
    pure
        $ Session
            { targets = effectiveTargets
            , command
            , watchDirs
            , watchExclusionPatterns
            , testTargets
            , replBuildDir = ReplBuildDir cfgFile.replBuildDir
            , testTimeout = TestTimeout cfgFile.testTimeout
            }
