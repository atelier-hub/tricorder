module Tricorder.BuildState
    ( BuildId (..)
    , BuildState (..)
    , BuildPhase (..)
    , BuildProgress (..)
    , BuildResult (..)
    , TestRun (..)
    , TestOutcome (..)
    , DaemonInfo (..)
    , runDaemonInfo
    , Diagnostic (..)
    , Severity (..)
    , BuildStateRef (..)
    , ChangeKind (..)
    , initialBuildState
    , stateLabel
    ) where

import Data.Aeson (FromJSON (..), ToJSON (..), withText)
import Data.Time (UTCTime)
import Effectful.Concurrent.STM (TVar)
import Effectful.Reader.Static (Reader, ask, runReader)
import System.FilePath (makeRelative)

import Atelier.Effects.FileSystem (FileSystem)
import Tricorder.Config (Config (..), resolveWatchDirs)
import Tricorder.Runtime (ProjectRoot (..))

import Tricorder.Observability qualified as Observability
import Tricorder.Web.Config qualified as Web


newtype BuildId = BuildId Int
    deriving stock (Eq, Show)
    deriving newtype (FromJSON, ToJSON)


data DaemonInfo = DaemonInfo
    { targets :: [Text]
    , watchDirs :: [FilePath]
    , apiUrl :: Text
    , logFile :: Maybe FilePath
    , metricsPort :: Maybe Int
    }
    deriving stock (Eq, Generic, Show)
    deriving anyclass (FromJSON, ToJSON)


runDaemonInfo
    :: ( FileSystem :> es
       , Reader Config :> es
       , Reader Observability.Config :> es
       , Reader ProjectRoot :> es
       , Reader Web.Config :> es
       )
    => Eff (Reader DaemonInfo : es) a -> Eff es a
runDaemonInfo act = do
    cfg <- ask
    obsCfg <- ask @Observability.Config
    ProjectRoot projectRoot <- ask
    serverCfg <- ask @Web.Config
    watchDirs <- resolveWatchDirs cfg projectRoot
    let daemonInfo =
            DaemonInfo
                { targets = cfg.targets
                , watchDirs = map (makeRelative projectRoot) watchDirs
                , apiUrl = "http://" <> toText (Web.host serverCfg) <> ":" <> show (Web.port serverCfg)
                , logFile = obsCfg.logFile
                , metricsPort = if obsCfg.metrics.enabled then Just obsCfg.metrics.port else Nothing
                }
    runReader daemonInfo act


data TestOutcome = TestsRunning | TestsPassed | TestsFailed | TestsError Text
    deriving stock (Eq, Generic, Show)
    deriving anyclass (FromJSON, ToJSON)


data TestRun = TestRun
    { target :: Text
    , outcome :: TestOutcome
    , output :: Text
    }
    deriving stock (Eq, Generic, Show)
    deriving anyclass (FromJSON, ToJSON)


data BuildResult = BuildResult
    { completedAt :: UTCTime
    , durationMs :: Int
    , moduleCount :: Int
    , diagnostics :: [Diagnostic]
    , testRuns :: [TestRun]
    }
    deriving stock (Eq, Generic, Show)
    deriving anyclass (FromJSON, ToJSON)


data BuildProgress = BuildProgress
    { compiled :: Int
    , total :: Int
    }
    deriving stock (Eq, Generic, Show)
    deriving anyclass (FromJSON, ToJSON)


data BuildPhase
    = Building (Maybe BuildProgress)
    | Restarting
    | Testing BuildResult
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
stateLabel (Building _) = "building"
stateLabel Restarting = "restarting"
stateLabel (Testing _) = "testing"
stateLabel (Done result)
    | any (\m -> m.severity == SError) result.diagnostics = "error"
    | any (\m -> m.severity == SWarning) result.diagnostics = "warning"
    | otherwise = "ok"


-- | Classifies what kind of file change triggered a dirty signal.
-- 'CabalChange' takes priority over 'SourceChange': if both fire before the
-- next build starts, the session will be fully restarted rather than reloaded.
data ChangeKind = SourceChange | CabalChange deriving stock (Eq, Ord, Show)


data BuildStateRef = BuildStateRef
    { stateRef :: TVar BuildState
    , dirtyRef :: TVar (Maybe ChangeKind)
    }


initialBuildState :: DaemonInfo -> BuildState
initialBuildState di =
    BuildState
        { buildId = BuildId 0
        , phase = Building Nothing
        , daemonInfo = di
        }
