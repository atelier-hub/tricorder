module Tricorder.Socket.Server (component, socketMonitorTrigger, SocketRemoved (..)) where

import Data.Aeson (ToJSON, decode, encode)
import Effectful.Exception (finally, throwIO)
import Effectful.Reader.Static (Reader, ask)

import Data.ByteString.Lazy qualified as BSL

import Atelier.Component (Component (..), Trigger, defaultComponent)
import Atelier.Effects.Cache (Cache)
import Atelier.Effects.Conc (Conc)
import Atelier.Effects.Delay (Delay, wait)
import Atelier.Effects.FileSystem (FileSystem)
import Atelier.Effects.Log (Log)
import Atelier.Time (Millisecond)
import Tricorder.BuildState (BuildPhase (..), BuildState (..))
import Tricorder.Effects.BuildStore (BuildStore, getState, waitForAnyChange, waitUntilDone)
import Tricorder.Effects.GhcPkg (GhcPkg)
import Tricorder.Effects.UnixSocket
    ( UnixSocket
    , acceptHandle
    , bindSocket
    , closeHandle
    , readLine
    , removeSocketFile
    , sendLine
    , socketFileExists
    )
import Tricorder.Socket.Protocol (ErrorResponse (..), Query (..), StatusQuery (..))
import Tricorder.Socket.SocketPath (SocketPath (..))
import Tricorder.SourceLookup (ModuleName, PackageId, lookupModuleSource)

import Atelier.Effects.Conc qualified as Conc


data SocketRemoved = SocketRemoved
    deriving stock (Eq, Show)
    deriving anyclass (Exception)


-- | SocketServer component.
-- Listens on a Unix socket and responds to status/watch/source queries.
component
    :: ( BuildStore :> es
       , Cache (PackageId, ModuleName) Text :> es
       , Cache ModuleName PackageId :> es
       , Conc :> es
       , Delay :> es
       , FileSystem :> es
       , GhcPkg :> es
       , Log :> es
       , Reader SocketPath :> es
       , UnixSocket :> es
       )
    => Component es
component =
    defaultComponent
        { name = "SocketServer"
        , setup = do
            SocketPath sockPath <- ask
            removeSocketFile sockPath
        , triggers = pure [acceptTrigger, socketMonitorTrigger]
        }


acceptTrigger
    :: ( BuildStore :> es
       , Cache (PackageId, ModuleName) Text :> es
       , Cache ModuleName PackageId :> es
       , Conc :> es
       , Delay :> es
       , FileSystem :> es
       , GhcPkg :> es
       , Log :> es
       , Reader SocketPath :> es
       , UnixSocket :> es
       )
    => Trigger es
acceptTrigger = do
    SocketPath sockPath <- ask
    sock <- bindSocket sockPath
    forever do
        h <- acceptHandle sock
        void $ Conc.forkTry @SomeException $ handleConnection h `finally` closeHandle h


-- | Poll for the socket file's existence every 500ms.
-- Throws 'SocketRemoved' when the file is gone, causing the component system to shut down.
socketMonitorTrigger
    :: ( Delay :> es
       , Reader SocketPath :> es
       , UnixSocket :> es
       )
    => Trigger es
socketMonitorTrigger = do
    SocketPath sockPath <- ask
    forever do
        wait (500 :: Millisecond)
        exists <- socketFileExists sockPath
        unless exists $ throwIO SocketRemoved


handleConnection
    :: ( BuildStore :> es
       , Cache (PackageId, ModuleName) Text :> es
       , Cache ModuleName PackageId :> es
       , Delay :> es
       , FileSystem :> es
       , GhcPkg :> es
       , Log :> es
       , UnixSocket :> es
       )
    => Handle
    -> Eff es ()
handleConnection h = do
    line <- readLine h
    case decode (BSL.fromStrict (encodeUtf8 line)) of
        Nothing -> sendJson h (ErrorResponse "invalid request")
        Just query -> dispatch query h


dispatch
    :: ( BuildStore :> es
       , Cache (PackageId, ModuleName) Text :> es
       , Cache ModuleName PackageId :> es
       , Delay :> es
       , FileSystem :> es
       , GhcPkg :> es
       , Log :> es
       , UnixSocket :> es
       )
    => Query
    -> Handle
    -> Eff es ()
dispatch query h = case query of
    Status (StatusQuery False) -> respondOnce h
    Status (StatusQuery True) -> respondWhenDone h
    Watch -> watchStream h
    Source moduleNames -> respondSource moduleNames h


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
            Restarting -> waitUntilDone
            Testing _ -> waitUntilDone
            Done _ -> awaitBuildStart (5 :: Int) s

    -- Poll up to n × 50ms for a build to start, then wait for it to finish.
    awaitBuildStart 0 s = pure s
    awaitBuildStart n _ = do
        wait (50 :: Millisecond)
        s' <- getState
        case s'.phase of
            Building -> waitUntilDone
            Restarting -> waitUntilDone
            Testing _ -> waitUntilDone
            Done _ -> awaitBuildStart (n - 1) s'


-- | Stream a JSON object after each state change (loops until handle closes or error).
watchStream :: (BuildStore :> es, UnixSocket :> es) => Handle -> Eff es ()
watchStream h = do
    state0 <- getState
    sendJson h state0
    loop state0
  where
    loop prev = do
        newState <- waitForAnyChange prev
        sendJson h newState
        loop newState


-- | Look up source for each requested module and send the results as a JSON array.
respondSource
    :: ( Cache (PackageId, ModuleName) Text :> es
       , Cache ModuleName PackageId :> es
       , FileSystem :> es
       , GhcPkg :> es
       , Log :> es
       , UnixSocket :> es
       )
    => [ModuleName]
    -> Handle
    -> Eff es ()
respondSource moduleNames h = do
    results <- mapM lookupModuleSource moduleNames
    sendJson h results


sendJson :: (ToJSON a, UnixSocket :> es) => Handle -> a -> Eff es ()
sendJson h val = sendLine h (decodeUtf8 (BSL.toStrict (encode val)))
