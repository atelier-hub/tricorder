module Tricorder.Session.TestTargets
    ( TestTargets (..)
    , Config (..)
    , resolveTestTargets
    , asReader
    ) where

import Data.Aeson (FromJSON, ToJSON)
import Data.Default (Default (..))
import Effectful.Reader.Static (Reader, ask, runReader)
import GHC.Generics (Generically (..))

import Data.Text qualified as T

import Atelier.Config (LoadedConfig, runConfig)
import Atelier.Types.QuietSnake (QuietSnake (..))
import Atelier.Types.WithDefaults (WithDefaults (..))
import Tricorder.Session.Targets (Targets (..))


newtype TestTargets = TestTargets {getTestTargets :: [Text]}
    deriving stock (Eq, Show)


data Config = Config
    { testTargets :: Maybe [Text]
    }
    deriving stock (Eq, Generic, Show)
    deriving (ToJSON) via Generically Config
    deriving (FromJSON) via WithDefaults (QuietSnake Config)


instance Default Config where
    def = Config Nothing


asReader
    :: ( Reader LoadedConfig :> es
       , Reader Targets :> es
       )
    => Eff (Reader TestTargets : es) a -> Eff es a
asReader act = do
    cfg <- runConfig @"session" @Config ask
    tgts <- ask
    let testTargets = resolveTestTargets cfg tgts
    runReader testTargets act


-- | Resolve which test suites to run after a clean build.
--
-- When 'testTargets' is set in config, those suites are used directly.
-- Otherwise, all @test:@ components in 'targets' are inferred.
resolveTestTargets :: Config -> Targets -> TestTargets
resolveTestTargets cfg (Targets tgts) = case cfg.testTargets of
    Just explicit -> TestTargets explicit
    Nothing -> TestTargets $ filter ("test:" `T.isPrefixOf`) tgts
