module Tricorder.Socket.Client
    ( queryStatus
    , queryStatusWait
    , queryWatch
    , Restarting (..)
    , querySource
    , queryDiagnostic
    , requestShutdown
    , isDaemonRunning
    ) where

import Data.Aeson (decode, eitherDecode, encode)
import Effectful (inject)
import Effectful.Exception (catchJust, trySync)
import Effectful.Reader.Static (Reader, ask)
import Effectful.State.Static.Shared (evalState, get, modify, put)
import System.IO.Error (isEOFError)

import Data.ByteString.Lazy qualified as BSL

import Atelier.Effects.Delay (Delay)
import Atelier.Effects.File (File)
import Atelier.Effects.Posix.Daemons (Daemons)
import Atelier.Time (Millisecond)
import Tricorder.BuildState (BuildState, Diagnostic)
import Tricorder.Effects.UnixSocket (UnixSocket, withConnection)
import Tricorder.GhcPkg.Types (ModuleName)
import Tricorder.Runtime (PidFile)
import Tricorder.Socket.Protocol (ClientMessage (..), DiagnosticQuery (..), Query (..), StatusQuery (..))
import Tricorder.SourceLookup (ModuleSourceResult)

import Atelier.Effects.Delay qualified as Delay
import Atelier.Effects.File qualified as File
import Atelier.Effects.Posix.Daemons qualified as Daemons
import Tricorder.Version qualified as Version


-- | Query the current build status (non-blocking).
queryStatus
    :: (File :> es, UnixSocket :> es)
    => FilePath
    -> Eff es (Either Text BuildState)
queryStatus sockPath = withConnection sockPath \h -> do
    sendQuery h (Status (StatusQuery {awaitDone = False}))
    receiveState h


-- | Query the build status, blocking until the current build cycle completes.
queryStatusWait
    :: (File :> es, UnixSocket :> es)
    => FilePath
    -> Eff es (Either Text BuildState)
queryStatusWait sockPath = withConnection sockPath \h -> do
    sendQuery h (Status (StatusQuery {awaitDone = True}))
    receiveState h


data Restarting = Restarting


-- | Connect and stream build updates, calling the handler after each completed build.
-- Retries automatically when the connection is lost or the daemon is restarting.
queryWatch
    :: forall es
     . (Delay :> es, File :> es, UnixSocket :> es)
    => FilePath
    -> (Either Restarting BuildState -> Eff es ())
    -> Eff es ()
queryWatch sockPath handler = evalState retryLimit retryLoop
  where
    retryLimit = 3 :: Int
    retryLoop = do
        retries <- get @Int
        if retries <= 0 then
            pure ()
        else do
            void $ trySync $ withConnection sockPath \h -> sendQuery h Watch >> loop h
            Delay.wait (500 :: Millisecond)
            modify $ subtract 1
            retryLoop

    loop h = do
        mLine <-
            catchJust
                (\e -> if isEOFError e then Just e else Nothing)
                (Just <$> File.hGetLine h)
                (\_ -> pure Nothing)
        case mLine of
            Nothing -> inject $ handler (Left Restarting)
            Just line ->
                case decode (BSL.fromStrict (encodeUtf8 (toText line))) of
                    Nothing -> pure ()
                    Just state -> do
                        put retryLimit
                        inject (handler (Right state)) >> loop h


-- | Look up the source for one or more modules via the daemon.
querySource
    :: (File :> es, UnixSocket :> es)
    => FilePath
    -> [ModuleName]
    -> Eff es (Either Text [ModuleSourceResult])
querySource sockPath moduleNames = withConnection sockPath \h -> do
    sendQuery h (Source moduleNames)
    line <- File.hGetLine h
    case eitherDecode (BSL.fromStrict (encodeUtf8 (toText line))) of
        Left err -> pure $ Left (toText err)
        Right results -> pure $ Right results


-- | Fetch the full body of a single diagnostic by 1-based index.
queryDiagnostic
    :: (File :> es, UnixSocket :> es)
    => FilePath
    -> Int
    -> Eff es (Either Text Diagnostic)
queryDiagnostic sockPath idx = withConnection sockPath \h -> do
    sendQuery h (DiagnosticAt (DiagnosticQuery {index = idx}))
    line <- File.hGetLine h
    case eitherDecode (BSL.fromStrict (encodeUtf8 (toText line))) of
        Left err -> pure $ Left (toText err)
        Right d -> pure $ Right d


requestShutdown :: (File :> es, UnixSocket :> es) => FilePath -> Eff es (Either Text ())
requestShutdown sockPath = withConnection sockPath \h -> do
    sendQuery h Quit
    line <- File.hGetLine h
    if eitherDecode (BSL.fromStrict (encodeUtf8 line)) == Right True then
        pure $ Right ()
    else
        pure $ Left "Failed to request shutdown"


isDaemonRunning :: (Daemons :> es, Reader PidFile :> es) => Eff es Bool
isDaemonRunning = do
    pidFile <- ask
    Daemons.isRunning pidFile


-- internals

sendQuery :: (File :> es) => Handle -> Query -> Eff es ()
sendQuery h q = File.hPutLBsLn h $ encode ClientMessage {clientVersion = Version.gitHash, payload = q}


receiveState :: (File :> es) => Handle -> Eff es (Either Text BuildState)
receiveState h = do
    line <- File.hGetLine h
    case eitherDecode (BSL.fromStrict (encodeUtf8 (toText line))) of
        Left err -> pure $ Left (toText err)
        Right state -> pure $ Right state
