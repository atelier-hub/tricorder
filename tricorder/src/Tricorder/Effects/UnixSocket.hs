module Tricorder.Effects.UnixSocket
    ( -- * Effect
      UnixSocket
    , bindSocket
    , acceptHandle
    , withConnection
    , readLine
    , sendLine
    , closeHandle
    , removeSocketFile
    , socketFileExists

      -- * Interpreters
    , runUnixSocketIO
    , runUnixSocketScripted
    , SocketScript (..)
    ) where

import Control.Exception (try)
import Effectful (Effect, IOE)
import Effectful.Dispatch.Dynamic (interpretWith, localSeqUnlift, reinterpret)
import Effectful.Exception (finally)
import Effectful.State.Static.Shared (evalState, get, put)
import Effectful.TH (makeEffect)
import Network.Socket
    ( Family (..)
    , SockAddr (..)
    , Socket
    , SocketType (..)
    , accept
    , bind
    , defaultProtocol
    , listen
    , socket
    , socketToHandle
    )
import System.Directory (doesPathExist, removeFile)
import System.IO (hClose, hGetLine, hPutStrLn, hSetEncoding, utf8)

import Network.Socket qualified as Net


data UnixSocket :: Effect where
    -- | Create, bind, and listen on a Unix socket at the given path.
    BindSocket :: FilePath -> UnixSocket m Socket
    -- | Accept the next incoming connection and return a line-buffered 'Handle'.
    AcceptHandle :: Socket -> UnixSocket m Handle
    -- | Connect to a Unix socket and run the callback with the resulting handle.
    -- The handle is closed when the callback returns.
    WithConnection :: FilePath -> (Handle -> m a) -> UnixSocket m a
    -- | Read a line from a connected handle.
    ReadLine :: Handle -> UnixSocket m Text
    -- | Write a line to a connected handle and flush.
    SendLine :: Handle -> Text -> UnixSocket m ()
    -- | Close a connected handle.
    CloseHandle :: Handle -> UnixSocket m ()
    -- | Remove the socket file, ignoring errors (e.g. file not found).
    RemoveSocketFile :: FilePath -> UnixSocket m ()
    -- | Check whether the socket file exists.
    SocketFileExists :: FilePath -> UnixSocket m Bool


makeEffect ''UnixSocket


-- | Production interpreter backed by real Unix sockets.
runUnixSocketIO :: (IOE :> es) => Eff (UnixSocket : es) a -> Eff es a
runUnixSocketIO eff = interpretWith eff \env -> \case
    BindSocket path -> liftIO do
        sock <- socket AF_UNIX Stream defaultProtocol
        bind sock (SockAddrUnix path)
        listen sock 5
        pure sock
    AcceptHandle sock -> liftIO do
        (conn, _) <- accept sock
        h <- socketToHandle conn ReadWriteMode
        hSetEncoding h utf8
        hSetBuffering h LineBuffering
        pure h
    WithConnection sockPath callback ->
        localSeqUnlift env \unlift -> do
            h <- liftIO do
                sock <- socket AF_UNIX Stream defaultProtocol
                Net.connect sock (SockAddrUnix sockPath)
                h <- socketToHandle sock ReadWriteMode
                hSetEncoding h utf8
                hSetBuffering h LineBuffering
                pure h
            unlift (callback h) `finally` liftIO (hClose h)
    ReadLine h -> liftIO $ toText <$> hGetLine h
    SendLine h line -> liftIO $ hPutStrLn h (toString line) >> hFlush h
    CloseHandle h -> liftIO $ hClose h
    RemoveSocketFile path ->
        liftIO $ void $ try @SomeException $ removeFile path
    SocketFileExists path ->
        liftIO $ doesPathExist path


-- | Script element for the test interpreter.
data SocketScript
    = -- | Return this 'Handle' for the next 'acceptHandle' call.
      NextAccept Handle
    | -- | Return this 'Bool' for the next 'socketFileExists' call.
      NextFileCheck Bool
    | -- | Use this 'Handle' for the next 'withConnection' call.
      NextConnect Handle
    | -- | Return this text for the next 'readLine' call.
      NextReadLine Text


-- | Scripted interpreter for testing.
--
-- 'bindSocket' creates a real (unbound) socket so that the returned 'Socket'
-- is a valid value, but does not actually bind to the filesystem.
-- 'acceptHandle' pops the next 'NextAccept' entry from the queue and sets
-- line buffering on it. 'removeSocketFile' is always a no-op.
-- 'socketFileExists' pops the next 'NextFileCheck' entry.
-- 'withConnection' pops the next 'NextConnect' entry and passes it to the callback.
runUnixSocketScripted :: (IOE :> es) => [SocketScript] -> Eff (UnixSocket : es) a -> Eff es a
runUnixSocketScripted script = reinterpret (evalState script) \env -> \case
    BindSocket _ ->
        liftIO $ Net.socket AF_UNIX Stream defaultProtocol
    AcceptHandle _ ->
        get >>= \case
            NextAccept h : rest -> do
                put rest
                liftIO $ hSetBuffering h LineBuffering
                pure h
            _ -> error "UnixSocketScripted: expected NextAccept but queue was empty or mismatched"
    WithConnection _ callback ->
        get >>= \case
            NextConnect h : rest -> do
                put rest
                localSeqUnlift env \unlift -> unlift (callback h)
            _ -> error "UnixSocketScripted: expected NextConnect but queue was empty or mismatched"
    ReadLine _ ->
        get >>= \case
            NextReadLine line : rest -> put rest >> pure line
            _ -> error "UnixSocketScripted: expected NextReadLine but queue was empty or mismatched"
    SendLine _ _ -> pure ()
    CloseHandle _ -> pure ()
    RemoveSocketFile _ -> pure ()
    SocketFileExists _ ->
        get >>= \case
            NextFileCheck b : rest -> put rest >> pure b
            _ -> error "UnixSocketScripted: expected NextFileCheck but queue was empty or mismatched"
