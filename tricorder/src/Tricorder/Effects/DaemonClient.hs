module Tricorder.Effects.DaemonClient
    ( DaemonClient
    , runRequest
    , runStream
    , runDaemonClientIO
    , runDaemonClient
    ) where

import Control.Exception (bracket)
import Data.Aeson (FromJSON, ToJSON, decode, eitherDecode, encode)
import Effectful (Effect, IOE)
import Effectful.Dispatch.Dynamic (interpretWith, localSeqUnlift)
import Effectful.Exception (finally)
import Effectful.Reader.Static (Reader, ask)
import Effectful.TH (makeEffect)
import Network.Socket
    ( Family (..)
    , SockAddr (..)
    , SocketType (..)
    , defaultProtocol
    , socket
    , socketToHandle
    )
import System.IO (hClose, hGetLine, hSetEncoding, utf8)

import Data.ByteString.Lazy qualified as BSL
import Data.Text.IO qualified as T
import Network.Socket qualified as Net
import System.IO qualified as IO

import Tricorder.Runtime (SocketPath (..))
import Tricorder.Socket.Protocol (Multiplicity (..), Request (..), toWire)


data DaemonClient :: Effect where
    RunRequest :: (FromJSON a) => Request Once a -> DaemonClient m (Either Text a)
    RunStream :: Request Many a -> (a -> m ()) -> DaemonClient m ()


makeEffect ''DaemonClient


runDaemonClientIO
    :: (IOE :> es)
    => FilePath
    -> Eff (DaemonClient : es) a
    -> Eff es a
runDaemonClientIO sockPath eff = interpretWith eff \env -> \case
    RunRequest req ->
        liftIO $ withSocketHandle sockPath \h -> do
            sendWire h (toWire req)
            line <- hGetLine h
            decodeAs $ BSL.fromStrict (encodeUtf8 (toText line))
    RunStream Watch callback ->
        localSeqUnlift env \unlift -> do
            h <- liftIO (openSocket sockPath)
            let loop = do
                    line <- liftIO (hGetLine h)
                    let raw = BSL.fromStrict (encodeUtf8 (toText line))
                    case decode raw of
                        Nothing -> pure ()
                        Just v -> unlift (callback v) >> loop
            liftIO (sendWire h (toWire Watch)) >> loop `finally` liftIO (hClose h)


runDaemonClient
    :: (IOE :> es, Reader SocketPath :> es)
    => Eff (DaemonClient : es) a
    -> Eff es a
runDaemonClient action = do
    SocketPath sp <- ask
    runDaemonClientIO sp action


-- internals

openSocket :: FilePath -> IO Handle
openSocket path = do
    sock <- socket AF_UNIX Stream defaultProtocol
    Net.connect sock (SockAddrUnix path)
    h <- socketToHandle sock ReadWriteMode
    hSetEncoding h utf8
    hSetBuffering h LineBuffering
    pure h


withSocketHandle :: FilePath -> (Handle -> IO a) -> IO a
withSocketHandle path = bracket (openSocket path) hClose


sendWire :: (ToJSON a) => Handle -> a -> IO ()
sendWire h val = do
    T.hPutStrLn h $ decodeUtf8 $ BSL.toStrict $ encode val
    IO.hFlush h


decodeAs :: (FromJSON a) => BSL.ByteString -> IO (Either Text a)
decodeAs raw = pure $ case eitherDecode raw of
    Left err -> Left (toText err)
    Right v -> Right v
