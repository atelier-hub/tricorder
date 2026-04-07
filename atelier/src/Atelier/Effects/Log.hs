-- | Log effect with hierarchical namespace support.
--
-- Provides structured logging with composable namespaces for better organization.
--
-- == Basic Usage
--
-- @
-- myComponent :: (Log :> es) => Eff es ()
-- myComponent = do
--     info "Starting component"
--     -- Logs: [INFO] [MyModule.myComponent#42] Starting component
-- @
--
-- == Using Namespaces
--
-- @
-- processData :: (Log :> es) => Eff es ()
-- processData = withNamespace "processor" $ do
--     info "Processing started"
--     -- Logs: [INFO] [processor] [MyModule.processData#10] Processing started
--
--     withNamespace "validation" $ do
--         info "Validating input"
--         -- Logs: [INFO] [processor.validation] [MyModule.processData#13] Validating input
-- @
module Atelier.Effects.Log
    ( -- * Effect
      Log
    , Message (..)
    , Config (..)
    , Severity (..)
    , log
    , info
    , warn
    , debug
    , err
    , withNamespace

      -- * Interpreters
    , runLog
    , runLogNoOp
    , runLogToHandle
    , runLogWriter
    ) where

import Data.Aeson (FromJSON (..))
import Data.Default (Default (..))
import Data.List (lookup)
import Effectful (Effect, IOE)
import Effectful.Dispatch.Dynamic (localSeqUnlift, reinterpret, reinterpretWith)
import Effectful.Reader.Static (Reader, ask, local, runReader)
import Effectful.TH (makeEffect)
import Effectful.Writer.Static.Shared (Writer, tell)

import Data.ByteString.Char8 qualified as B8

import Atelier.Effects.Env (Env, getEnvironment)
import Atelier.Types.JsonReadShow (JsonReadShow (..))
import Atelier.Types.QuietSnake (QuietSnake (..))


data Log :: Effect where
    LogMsg :: Message -> Log m ()
    WithNamespace :: Namespace -> m a -> Log m a
    GetNamespace :: Log m Namespace


data Message = Message
    { namespace :: Namespace
    , text :: Text
    , severity :: Severity
    , stack :: CallStack
    }


newtype Namespace = Namespace Text
    deriving stock (Eq, Show)
    deriving newtype (IsString)


instance Semigroup Namespace where
    Namespace "" <> Namespace b = Namespace b
    Namespace a <> Namespace "" = Namespace a
    Namespace a <> Namespace b = Namespace (a <> "." <> b)


data Config = Config
    { minimumSeverity :: Severity
    }
    deriving stock (Eq, Generic, Show)
    deriving (FromJSON) via QuietSnake Config


data Severity
    = DEBUG
    | INFO
    | WARN
    | ERROR
    deriving stock (Bounded, Enum, Eq, Ord, Read, Show)
    deriving (FromJSON) via (JsonReadShow Severity)


instance Default Config where
    def =
        Config
            { minimumSeverity = minBound
            }


makeEffect ''Log


log :: (HasCallStack, Log :> es) => Severity -> Text -> Eff es ()
log severity text = do
    namespace <- getNamespace
    withFrozenCallStack
        $ logMsg
            Message
                { stack = callStack
                , namespace
                , severity
                , text
                }


debug :: (HasCallStack, Log :> es) => Text -> Eff es ()
debug = withFrozenCallStack $ log DEBUG


info :: (HasCallStack, Log :> es) => Text -> Eff es ()
info = withFrozenCallStack $ log INFO


warn :: (HasCallStack, Log :> es) => Text -> Eff es ()
warn = withFrozenCallStack $ log WARN


err :: (HasCallStack, Log :> es) => Text -> Eff es ()
err = withFrozenCallStack $ log ERROR


-- | Consumes `Log` effects, and discards the logged messages
runLogNoOp :: Eff (Log : es) a -> Eff es a
runLogNoOp = reinterpret (runReader (Namespace "")) $ \env -> \case
    LogMsg _ -> pure ()
    WithNamespace ns act -> localSeqUnlift env $ \unlift ->
        local (<> ns) $ unlift act
    GetNamespace -> ask


runLog :: (Env :> es, IOE :> es, Reader Config :> es) => Eff (Log : es) a -> Eff es a
runLog action = do
    config <- ask
    env <- getEnvironment
    let overrideLog = (>>= readMaybe) $ lookup "LOG" env
        overrideLogging = (>>= readMaybe) $ lookup "LOGGING" env
        overrideDebug = (>>= \x -> if x == "0" then Nothing else Just DEBUG) $ lookup "DEBUG" env
    let severity =
            fromMaybe config.minimumSeverity
                $ overrideDebug <|> overrideLogging <|> overrideLog

    reinterpretWith (runReader (Namespace "")) action \lenv -> \case
        LogMsg msg ->
            liftIO $ when (msg.severity >= severity) do
                -- NOTE: We use hPutStr here with an appended newline because
                -- hPutStrLn is not atomic for ByteStrings longer than 1024 bytes.
                -- Data.Text.IO.hPutStrLn is not atomic for even short Texts.
                B8.hPutStr stdout
                    . encodeUtf8
                    . (<> "\n")
                    . formatMessage
                    $ msg
                hFlush stdout
        WithNamespace ns act -> localSeqUnlift lenv $ \unlift ->
            local (<> ns) $ unlift act
        GetNamespace -> ask


-- | Like 'runLog' but writes to the given 'Handle' instead of stdout.
-- Useful for daemons that want to write logs to a file.
runLogToHandle :: (IOE :> es) => Handle -> Severity -> Eff (Log : es) a -> Eff es a
runLogToHandle handle minSeverity action =
    reinterpretWith (runReader (Namespace "")) action \env -> \case
        LogMsg msg ->
            liftIO $ when (msg.severity >= minSeverity) do
                B8.hPutStr handle . encodeUtf8 . (<> "\n") . formatMessage $ msg
                hFlush handle
        WithNamespace ns act -> localSeqUnlift env $ \unlift ->
            local (<> ns) $ unlift act
        GetNamespace -> ask


runLogWriter :: (Writer [Message] :> es) => Eff (Log : es) a -> Eff es a
runLogWriter = reinterpret (runReader (Namespace "")) $ \env -> \case
    LogMsg msg -> tell [msg]
    WithNamespace ns act -> localSeqUnlift env $ \unlift ->
        local (<> ns) $ unlift act
    GetNamespace -> ask


formatMessage :: Message -> Text
formatMessage msg =
    mconcat
        [ square $ show msg.severity
        , " "
        , showNamespace msg.namespace
        , msg.text
        ]
  where
    showNamespace (Namespace "") = ""
    showNamespace (Namespace ns) = square ns <> " "


square :: Text -> Text
square s = "[" <> s <> "]"
