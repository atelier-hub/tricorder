module Tricorder.Session.BuildCommand
    ( BuildCommand (..)
    , Config (..)
    , asReader
    , resolveCommand
    ) where

import Data.Aeson (FromJSON, ToJSON)
import Data.Default (Default (..))
import Effectful.Reader.Static (Reader, ask, runReader)
import GHC.Generics (Generically (..))
import System.FilePath (takeExtension, (</>))

import Atelier.Config (LoadedConfig, runConfig)
import Atelier.Effects.FileSystem (FileSystem, doesFileExist, listDirectory)
import Atelier.Types.QuietSnake (QuietSnake (..))
import Atelier.Types.WithDefaults (WithDefaults (..))
import Tricorder.Session.ProjectRoot (ProjectRoot (..))
import Tricorder.Session.ReplBuildDir (ReplBuildDir (..))
import Tricorder.Session.Targets (Targets (..))


newtype BuildCommand = BuildCommand {getBuildCommand :: Text}


data Config = Config
    { command :: Maybe Text
    }
    deriving stock (Generic)
    deriving (ToJSON) via Generically Config
    deriving (FromJSON) via WithDefaults (QuietSnake Config)


instance Default Config where def = Config Nothing


-- | Resolve the GHCi command, using config if set or autodetecting otherwise.
resolveCommand
    :: ( FileSystem :> es
       , Reader ProjectRoot :> es
       , Reader ReplBuildDir :> es
       , Reader Targets :> es
       )
    => Config
    -> Eff es Text
resolveCommand cfg = case cfg.command of
    Just cmd -> pure cmd
    Nothing -> detectCommand


detectCommand
    :: ( FileSystem :> es
       , Reader ProjectRoot :> es
       , Reader ReplBuildDir :> es
       , Reader Targets :> es
       )
    => Eff es Text
detectCommand = do
    Targets targets <- ask
    ProjectRoot projectRoot <- ask
    ReplBuildDir replBuildDir <- ask
    hasCabalProject <- doesFileExist (projectRoot </> "cabal.project")
    cabalFiles <- filter (\f -> takeExtension f == ".cabal") <$> listDirectory projectRoot
    hasStack <- doesFileExist (projectRoot </> "stack.yaml")
    let targetStr = if null targets then "all" else unwords targets
        buildDirFlag = "--builddir " <> toText replBuildDir <> " "
    pure
        $ if
            | hasCabalProject || not (null cabalFiles) ->
                "cabal repl --enable-multi-repl " <> buildDirFlag <> targetStr
            | hasStack -> "stack ghci " <> targetStr
            | otherwise -> "cabal repl " <> buildDirFlag <> targetStr


asReader
    :: ( FileSystem :> es
       , Reader LoadedConfig :> es
       , Reader ProjectRoot :> es
       , Reader ReplBuildDir :> es
       , Reader Targets :> es
       )
    => Eff (Reader BuildCommand : es) a -> Eff es a
asReader act = do
    cfg <- runConfig @"session" @Config ask
    cmd <- resolveCommand cfg
    runReader (BuildCommand cmd) act
