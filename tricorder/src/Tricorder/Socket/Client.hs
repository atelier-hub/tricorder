module Tricorder.Socket.Client
    ( queryStatus
    , queryStatusWait
    , queryWatch
    , querySource
    , socketPath
    , isDaemonRunning
    ) where

import Data.Aeson (decode, eitherDecode, encode)
import Effectful.Exception (try)
import Numeric (showHex)
import System.FilePath ((</>))

import Data.ByteString.Lazy qualified as BSL

import Atelier.Effects.File (File)
import Atelier.Effects.FileSystem (FileSystem, canonicalizePath, createDirectoryIfMissing, getXdgRuntimeDir)
import Tricorder.BuildState (BuildState)
import Tricorder.Effects.UnixSocket (UnixSocket, withConnection)
import Tricorder.GhcPkg.Types (ModuleName)
import Tricorder.Socket.Protocol (Query (..), StatusQuery (..))
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


-- | Check whether the daemon is running by attempting a socket connection.
isDaemonRunning :: (UnixSocket :> es) => FilePath -> Eff es Bool
isDaemonRunning sockPath = do
    result <- try @SomeException $ withConnection sockPath \_ -> pure ()
    pure $ isRight result


-- | Compute the Unix socket path for the given project root.
socketPath :: (FileSystem :> es) => FilePath -> Eff es FilePath
socketPath rawRoot = do
    root <- canonicalizePath rawRoot
    runtimeDir <- getXdgRuntimeDir
    let dir = runtimeDir </> "tricorder"
    createDirectoryIfMissing True dir
    pure $ dir </> hashPath root <> ".sock"


-- internals

sendQuery :: (File :> es) => Handle -> Query -> Eff es ()
sendQuery h q = File.hPutLBsLn h $ encode q


receiveState :: (File :> es) => Handle -> Eff es (Either Text BuildState)
receiveState h = do
    line <- File.hGetLine h
    case eitherDecode (BSL.fromStrict (encodeUtf8 (toText line))) of
        Left err -> pure $ Left (toText err)
        Right state -> pure $ Right state


-- | Polynomial hash of a file path, returned as a hex string.
hashPath :: FilePath -> String
hashPath path =
    let n = foldl' (\acc c -> acc * 31 + toInteger (ord c)) (0 :: Integer) path
    in  showHex (abs n `mod` (16 ^ (16 :: Integer))) ""
