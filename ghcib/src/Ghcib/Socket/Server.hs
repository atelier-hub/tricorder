module Ghcib.Socket.Server (component, socketMonitorTrigger, SocketRemoved (..)) where

import Data.Aeson (ToJSON, decode, encode)
import Effectful.Exception (finally, throwIO)

import Data.ByteString.Lazy qualified as BSL

import Atelier.Component (Component (..), Trigger, defaultComponent)
import Atelier.Effects.Conc (Conc)
import Atelier.Effects.Delay (Delay, wait)
import Atelier.Time (Millisecond)
import Ghcib.BuildState (BuildPhase (..), BuildState (..))
import Ghcib.Effects.BuildStore (BuildStore, getState, waitForNext, waitUntilDone)
import Ghcib.Effects.UnixSocket
    ( UnixSocket
    , acceptHandle
    , bindSocket
    , closeHandle
    , readLine
    , removeSocketFile
    , sendLine
    , socketFileExists
    )
import Ghcib.Socket.Protocol (ErrorResponse (..), Query (..), StatusQuery (..))

import Atelier.Effects.Conc qualified as Conc


data SocketRemoved = SocketRemoved
    deriving stock (Eq, Show)
    deriving anyclass (Exception)


-- | SocketServer component.
-- Listens on a Unix socket and responds to status/watch queries.
component
    :: ( BuildStore :> es
       , Conc :> es
       , Delay :> es
       , UnixSocket :> es
       )
    => FilePath
    -> Component es
component sockPath =
    defaultComponent
        { name = "SocketServer"
        , setup = removeSocketFile sockPath
        , triggers = pure [acceptTrigger sockPath, socketMonitorTrigger sockPath]
        }


acceptTrigger
    :: ( BuildStore :> es
       , Conc :> es
       , Delay :> es
       , UnixSocket :> es
       )
    => FilePath
    -> Trigger es
acceptTrigger sockPath = do
    sock <- bindSocket sockPath
    forever do
        h <- acceptHandle sock
        void $ Conc.forkTry @SomeException $ handleConnection h `finally` closeHandle h


-- | Poll for the socket file's existence every 500ms.
-- Throws 'SocketRemoved' when the file is gone, causing the component system to shut down.
socketMonitorTrigger :: (Delay :> es, UnixSocket :> es) => FilePath -> Trigger es
socketMonitorTrigger sockPath = forever do
    wait (500 :: Millisecond)
    exists <- socketFileExists sockPath
    unless exists $ throwIO SocketRemoved


handleConnection :: (BuildStore :> es, Delay :> es, UnixSocket :> es) => Handle -> Eff es ()
handleConnection h = do
    line <- readLine h
    case decode (BSL.fromStrict (encodeUtf8 line)) of
        Nothing -> sendJson h (ErrorResponse "invalid request")
        Just query -> dispatch query h


dispatch :: (BuildStore :> es, Delay :> es, UnixSocket :> es) => Query -> Handle -> Eff es ()
dispatch query h = case query of
    Status (StatusQuery False) -> respondOnce h
    Status (StatusQuery True) -> respondWhenDone h
    Watch -> watchStream h


respondOnce :: (BuildStore :> es, UnixSocket :> es) => Handle -> Eff es ()
respondOnce h = getState >>= sendJson h


-- | Wait for a completed build, then respond.
--
-- If the build is already done when this is called, we may be racing the file
-- watcher's debounce: a file was just changed but the reload hasn't been
-- dispatched yet (default debounce is 100ms). Poll for up to 250ms to let
-- any in-flight debounce fire before falling back to the current result.
respondWhenDone :: (BuildStore :> es, Delay :> es, UnixSocket :> es) => Handle -> Eff es ()
respondWhenDone h = awaitResult >>= sendJson h
  where
    awaitResult = do
        s <- getState
        case s.phase of
            Building -> waitUntilDone
            Done _ -> awaitBuildStart (5 :: Int) s

    -- Poll up to n × 50ms for a build to start, then wait for it to finish.
    awaitBuildStart 0 s = pure s
    awaitBuildStart n _ = do
        wait (50 :: Millisecond)
        s' <- getState
        case s'.phase of
            Building -> waitUntilDone
            Done _ -> awaitBuildStart (n - 1) s'


-- | Stream a JSON object after each completed build (loops until handle closes or error).
watchStream :: (BuildStore :> es, UnixSocket :> es) => Handle -> Eff es ()
watchStream h = do
    state0 <- getState
    sendJson h state0
    loop state0.buildId
  where
    loop bid = do
        newState <- waitForNext bid
        sendJson h newState
        loop newState.buildId


sendJson :: (ToJSON a, UnixSocket :> es) => Handle -> a -> Eff es ()
sendJson h val = sendLine h (decodeUtf8 (BSL.toStrict (encode val)))
