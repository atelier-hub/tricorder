module Ghcib.BuildState
    ( BuildId (..)
    , BuildState (..)
    , BuildPhase (..)
    , BuildResult (..)
    , DaemonInfo (..)
    , Diagnostic (..)
    , Severity (..)
    , BuildStateRef (..)
    , initialBuildState
    , stateLabel
    ) where

import Data.Aeson (FromJSON (..), ToJSON (..), withText)
import Data.Time (UTCTime)
import Effectful.Concurrent.STM (TVar)


newtype BuildId = BuildId Int
    deriving stock (Eq, Show)
    deriving newtype (FromJSON, ToJSON)


data DaemonInfo = DaemonInfo
    { targets :: [Text]
    , watchDirs :: [FilePath]
    , sockPath :: FilePath
    , logFile :: Maybe FilePath
    }
    deriving stock (Eq, Generic, Show)
    deriving anyclass (FromJSON, ToJSON)


data BuildResult = BuildResult
    { completedAt :: UTCTime
    , durationMs :: Int
    , moduleCount :: Int
    , diagnostics :: [Diagnostic]
    }
    deriving stock (Eq, Generic, Show)
    deriving anyclass (FromJSON, ToJSON)


data BuildPhase
    = Building
    | Done BuildResult
    deriving stock (Eq, Generic, Show)
    deriving anyclass (FromJSON, ToJSON)


data BuildState = BuildState
    { buildId :: BuildId
    , phase :: BuildPhase
    , daemonInfo :: DaemonInfo
    }
    deriving stock (Eq, Generic, Show)
    deriving anyclass (FromJSON, ToJSON)


data Diagnostic = Diagnostic
    { severity :: Severity
    , file :: FilePath
    , line :: Int
    , col :: Int
    , endLine :: Int
    , endCol :: Int
    , title :: Text
    , text :: Text
    }
    deriving stock (Eq, Generic, Show)
    deriving anyclass (FromJSON, ToJSON)


data Severity = SError | SWarning
    deriving stock (Eq, Show)


instance FromJSON Severity where
    parseJSON = withText "Severity" \case
        "error" -> pure SError
        "warning" -> pure SWarning
        other -> fail $ "unknown severity: " <> toString other


instance ToJSON Severity where
    toJSON SError = "error"
    toJSON SWarning = "warning"


stateLabel :: BuildPhase -> Text
stateLabel Building = "building"
stateLabel (Done result)
    | any (\m -> m.severity == SError) result.diagnostics = "error"
    | any (\m -> m.severity == SWarning) result.diagnostics = "warning"
    | otherwise = "ok"


newtype BuildStateRef = BuildStateRef (TVar BuildState)


initialBuildState :: DaemonInfo -> BuildState
initialBuildState di =
    BuildState
        { buildId = BuildId 0
        , phase = Building
        , daemonInfo = di
        }
