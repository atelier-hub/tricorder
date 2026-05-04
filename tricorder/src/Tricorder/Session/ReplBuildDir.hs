module Tricorder.Session.ReplBuildDir
    ( ReplBuildDir (..)
    , asReader
    ) where

import Data.Aeson (FromJSON, ToJSON)
import Data.Default (Default (..))
import Effectful.Reader.Static (Reader, ask, runReader)
import GHC.Generics (Generically (..))

import Atelier.Config (LoadedConfig, runConfig)
import Atelier.Types.QuietSnake (QuietSnake (..))
import Atelier.Types.WithDefaults (WithDefaults (..))


newtype ReplBuildDir = ReplBuildDir {getReplBuildDir :: FilePath}


data Config = Config
    { replBuildDir :: FilePath
    }
    deriving stock (Generic)
    deriving (ToJSON) via Generically Config
    deriving (FromJSON) via WithDefaults (QuietSnake Config)


instance Default Config where def = Config "dist-newstyle/tricorder"


asReader
    :: (Reader LoadedConfig :> es)
    => Eff (Reader ReplBuildDir : es) a
    -> Eff es a
asReader act = do
    cfg <- runConfig @"session" @Config ask
    runReader (ReplBuildDir cfg.replBuildDir) act
