module Ghcib.Socket.Client
    ( queryStatus
    , queryStatusWait
    , queryWatch
    , socketPath
    , isDaemonRunning
    ) where

import Data.Aeson (decode, encode)
import Effectful (IOE)
import Effectful.Exception (try)
import Numeric (showHex)
import System.Directory (canonicalizePath, createDirectoryIfMissing)
import System.FilePath ((</>))
import System.IO (hGetLine, hPutStrLn)

import Data.ByteString.Lazy qualified as BSL

import Ghcib.BuildState (BuildState)
import Ghcib.Effects.UnixSocket (UnixSocket, withConnection)
import Ghcib.Socket.Protocol (Query (..), StatusQuery (..))


-- | Query the current build status (non-blocking).
queryStatus
    :: (IOE :> es, UnixSocket :> es)
    => FilePath
    -> Eff es (Either Text BuildState)
queryStatus sockPath = withConnection sockPath \h -> do
    liftIO $ sendQuery h (Status (StatusQuery {awaitDone = False}))
    receiveState h


-- | Query the build status, blocking until the current build cycle completes.
queryStatusWait
    :: (IOE :> es, UnixSocket :> es)
    => FilePath
    -> Eff es (Either Text BuildState)
queryStatusWait sockPath = withConnection sockPath \h -> do
    liftIO $ sendQuery h (Status (StatusQuery {awaitDone = True}))
    receiveState h


-- | Connect and stream build updates, calling the handler after each completed build.
queryWatch
    :: (IOE :> es, UnixSocket :> es)
    => FilePath
    -> (BuildState -> Eff es ())
    -> Eff es ()
queryWatch sockPath handler = withConnection sockPath \h -> do
    liftIO $ sendQuery h Watch
    loop h
  where
    loop h = do
        line <- liftIO $ hGetLine h
        case decode (BSL.fromStrict (encodeUtf8 (toText line))) of
            Nothing -> pure ()
            Just state -> handler state >> loop h


-- | Check whether the daemon is running by attempting a socket connection.
isDaemonRunning :: (UnixSocket :> es) => FilePath -> Eff es Bool
isDaemonRunning sockPath = do
    result <- try @SomeException $ withConnection sockPath \_ -> pure ()
    pure $ isRight result


-- | Compute the Unix socket path for the given project root.
socketPath :: FilePath -> IO FilePath
socketPath rawRoot = do
    root <- canonicalizePath rawRoot
    runtimeDir <- fromMaybe "/tmp" <$> lookupEnv "XDG_RUNTIME_DIR"
    let dir = runtimeDir </> "ghcib"
    createDirectoryIfMissing True dir
    pure $ dir </> hashPath root <> ".sock"


-- internals

sendQuery :: Handle -> Query -> IO ()
sendQuery h q = hPutStrLn h (decodeUtf8 (BSL.toStrict (encode q)))


receiveState :: (IOE :> es) => Handle -> Eff es (Either Text BuildState)
receiveState h = do
    line <- liftIO $ hGetLine h
    case decode (BSL.fromStrict (encodeUtf8 (toText line))) of
        Nothing -> pure $ Left "failed to parse response"
        Just state -> pure $ Right state


-- | Polynomial hash of a file path, returned as a hex string.
hashPath :: FilePath -> String
hashPath path =
    let n = foldl' (\acc c -> acc * 31 + toInteger (ord c)) (0 :: Integer) path
    in  showHex (abs n `mod` (16 ^ (16 :: Integer))) ""
