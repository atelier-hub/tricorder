module Tricorder.Session.Targets
    ( Targets (..)
    , Config (..)
    , asReader
    , allComponentTargets
    ) where

import Data.Aeson (FromJSON, ToJSON)
import Data.Default (Default (..))
import Distribution.PackageDescription
    ( GenericPackageDescription (..)
    , PackageDescription (..)
    , PackageIdentifier (..)
    , unPackageName
    , unUnqualComponentName
    )
import Distribution.PackageDescription.Parsec (parseGenericPackageDescriptionMaybe)
import Effectful.Reader.Static (Reader, ask, asks, runReader)
import GHC.Generics (Generically (..))
import System.FilePath (takeExtension, (</>))

import Atelier.Config (LoadedConfig, runConfig)
import Atelier.Effects.FileSystem (FileSystem, listDirectory, readFileBs)
import Atelier.Types.QuietSnake (QuietSnake (..))
import Atelier.Types.WithDefaults (WithDefaults (..))
import Tricorder.Session.ProjectRoot (ProjectRoot (..))


newtype Targets = Targets {getTargets :: [Text]}


instance Default Targets where def = Targets []


data Config = Config
    { targets :: [Text]
    }
    deriving stock (Generic)
    deriving (ToJSON) via Generically Config
    deriving (FromJSON) via WithDefaults (QuietSnake Config)


instance Default Config where def = Config []


asReader
    :: ( FileSystem :> es
       , Reader LoadedConfig :> es
       , Reader ProjectRoot :> es
       )
    => Eff (Reader Targets : es) a -> Eff es a
asReader act = do
    cfg <- runConfig @"session" @Config ask
    projectRoot <- asks @ProjectRoot (.getProjectRoot)
    tgts <- resolveTargets cfg.targets projectRoot
    runReader (Targets tgts) act


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
