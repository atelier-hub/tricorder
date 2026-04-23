module Tricorder.Socket.Client
    ( queryStatus
    , queryStatusWait
    , queryWatch
    , querySource
    , queryDiagnostic
    ) where

import Data.Aeson (decode, eitherDecode, encode)

import Data.ByteString.Lazy qualified as BSL

import Atelier.Effects.File (File)
import Tricorder.BuildState (BuildState, Diagnostic)
import Tricorder.Effects.UnixSocket (UnixSocket, withConnection)
import Tricorder.GhcPkg.Types (ModuleName)
import Tricorder.Socket.Protocol (DiagnosticQuery (..), Query (..), StatusQuery (..))
import Tricorder.SourceLookup (ModuleSourceResult)

import Atelier.Effects.File qualified as File


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


-- | Connect and stream build updates, calling the handler after each completed build.
queryWatch
    :: (File :> es, UnixSocket :> es)
    => FilePath
    -> (BuildState -> Eff es ())
    -> Eff es ()
queryWatch sockPath handler = withConnection sockPath \h -> do
    sendQuery h Watch
    loop h
  where
    loop h = do
        line <- File.hGetLine h
        case decode (BSL.fromStrict (encodeUtf8 (toText line))) of
            Nothing -> pure ()
            Just state -> handler state >> loop h


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


-- internals

sendQuery :: (File :> es) => Handle -> Query -> Eff es ()
sendQuery h q = File.hPutLBsLn h $ encode q


receiveState :: (File :> es) => Handle -> Eff es (Either Text BuildState)
receiveState h = do
    line <- File.hGetLine h
    case eitherDecode (BSL.fromStrict (encodeUtf8 (toText line))) of
        Left err -> pure $ Left (toText err)
        Right state -> pure $ Right state
