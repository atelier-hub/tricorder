module Atelier.Effects.RPC.Unix
    ( runClientUnix
    ) where

import Control.Exception (bracket)
import Data.Aeson (FromJSON, ToJSON, decode, eitherDecode, encode)
import Effectful (IOE)
import Effectful.Dispatch.Dynamic (interpretWith, localSeqUnlift)
import Effectful.Exception (finally)
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

import Atelier.Effects.RPC (Client (..))


runClientUnix
    :: (IOE :> es)
    => FilePath
    -> Eff (Client req : es) a
    -> Eff es a
runClientUnix sockPath eff = interpretWith eff \env -> \case
    RunRequest req ->
        liftIO $ withSocketHandle sockPath \h -> do
            sendWire h req
            line <- hGetLine h
            decodeAs $ BSL.fromStrict (encodeUtf8 (toText line))
    RunStream req callback ->
        localSeqUnlift env \unlift -> do
            h <- liftIO (openSocket sockPath)
            let loop = do
                    line <- liftIO (hGetLine h)
                    let raw = BSL.fromStrict (encodeUtf8 (toText line))
                    case decode raw of
                        Nothing -> pure ()
                        Just v -> unlift (callback v) >> loop
            liftIO (sendWire h req) >> loop `finally` liftIO (hClose h)


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
