module Ghcib.BuildState
    ( BuildId (..)
    , BuildState (..)
    , BuildPhase (..)
    , DaemonInfo (..)
    , Message (..)
    , Severity (..)
    , BuildStateRef (..)
    , runBuildStateRef
    , initialBuildState
    , updateBuildPhase
    , stateLabel
    ) where

import Data.Aeson (FromJSON (..), ToJSON (..), object, withObject, withText, (.!=), (.:), (.:?), (.=))
import Data.Aeson.Types (Pair, Parser)
import Data.Time (UTCTime (..), fromGregorian)
import Data.Time.Units (fromMicroseconds, toMicroseconds)
import Effectful.Concurrent (Concurrent)
import Effectful.Concurrent.STM (TVar, atomically, modifyTVar, newTVar)
import Effectful.Reader.Static (Reader, runReader)

import Atelier.Time (Millisecond)


newtype BuildId = BuildId Int
    deriving stock (Eq, Show)
    deriving newtype (ToJSON)


data DaemonInfo = DaemonInfo
    { targets :: [Text]
    , watchDirs :: [FilePath]
    , sockPath :: FilePath
    , logFile :: Maybe FilePath
    }
    deriving stock (Eq, Show)


data BuildState = BuildState
    { buildId :: BuildId
    , phase :: BuildPhase
    , daemonInfo :: DaemonInfo
    }
    deriving stock (Eq, Show)


data BuildPhase
    = Building
    | Done UTCTime Millisecond [Message]
    deriving stock (Eq, Show)


data Message = Message
    { severity :: Severity
    , file :: FilePath
    , line :: Int
    , col :: Int
    , endLine :: Int
    , endCol :: Int
    , text :: Text
    }
    deriving stock (Eq, Show)


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


instance FromJSON Message where
    parseJSON = withObject "Message" \o ->
        Message
            <$> o .: "severity"
            <*> o .: "file"
            <*> o .: "line"
            <*> o .: "col"
            <*> o .: "endLine"
            <*> o .: "endCol"
            <*> o .: "text"


instance ToJSON Message where
    toJSON m =
        object
            [ "severity" .= m.severity
            , "file" .= m.file
            , "line" .= m.line
            , "col" .= m.col
            , "endLine" .= m.endLine
            , "endCol" .= m.endCol
            , "text" .= m.text
            ]


stateLabel :: BuildPhase -> Text
stateLabel Building = "building"
stateLabel (Done _ _ msgs)
    | any (\m -> m.severity == SError) msgs = "error"
    | any (\m -> m.severity == SWarning) msgs = "warning"
    | otherwise = "ok"


daemonInfoFields :: DaemonInfo -> [Pair]
daemonInfoFields di =
    [ "targets" .= di.targets
    , "watchDirs" .= di.watchDirs
    , "sockPath" .= di.sockPath
    , "logFile" .= di.logFile
    ]


instance ToJSON BuildState where
    toJSON bs =
        let bid = bs.buildId
            di = bs.daemonInfo
        in  case bs.phase of
                Building ->
                    object
                        $ [ "state" .= ("building" :: Text)
                          , "buildId" .= bid
                          ]
                            <> daemonInfoFields di
                Done completedAt dur msgs ->
                    object
                        $ [ "state" .= stateLabel (Done completedAt dur msgs)
                          , "buildId" .= bid
                          , "completedAt" .= completedAt
                          , "durationMs" .= (fromIntegral (toMicroseconds dur `div` 1000) :: Int)
                          , "messages" .= msgs
                          ]
                            <> daemonInfoFields di


instance FromJSON BuildState where
    parseJSON = withObject "BuildState" \o -> do
        bid <- BuildId <$> o .: "buildId"
        state <- (o .: "state") :: Parser Text
        phase <- case state of
            "building" -> pure Building
            _ -> do
                completedAt <- o .:? "completedAt" .!= UTCTime (fromGregorian 1970 1 1) 0
                durMs <- o .: "durationMs"
                msgs <- o .:? "messages" .!= []
                pure $ Done completedAt (fromMicroseconds (durMs * 1000 :: Integer)) msgs
        targets <- o .:? "targets" .!= []
        watchDirs <- o .:? "watchDirs" .!= []
        sockPath <- o .:? "sockPath" .!= ""
        logFile <- o .:? "logFile"
        let daemonInfo = DaemonInfo {targets, watchDirs, sockPath, logFile}
        pure $ BuildState bid phase daemonInfo


newtype BuildStateRef = BuildStateRef (TVar BuildState)


runBuildStateRef
    :: (Concurrent :> es)
    => DaemonInfo
    -> Eff (Reader BuildStateRef : es) a
    -> Eff es a
runBuildStateRef di eff = do
    ref <- atomically $ newTVar (initialBuildState di)
    runReader (BuildStateRef ref) eff


updateBuildPhase
    :: (Concurrent :> es)
    => BuildStateRef
    -> BuildId
    -> BuildPhase
    -> Eff es ()
updateBuildPhase (BuildStateRef ref) bid phase =
    atomically $ modifyTVar ref \bs -> bs {buildId = bid, phase = phase}


initialBuildState :: DaemonInfo -> BuildState
initialBuildState di =
    BuildState
        { buildId = BuildId 0
        , phase = Building
        , daemonInfo = di
        }
