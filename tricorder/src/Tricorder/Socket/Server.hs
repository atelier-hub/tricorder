module Tricorder.Socket.Server (component, SocketRemoved (..)) where

import Data.Aeson (ToJSON, decode, encode)
import Effectful.Exception (finally)
import Effectful.Reader.Static (Reader, ask)

import Data.ByteString.Lazy qualified as BSL

import Atelier.Component (Component (..), Trigger, defaultComponent)
import Atelier.Effects.Cache (Cache)
import Atelier.Effects.Conc (Conc)
import Atelier.Effects.Delay (Delay, wait)
import Atelier.Effects.FileSystem (FileSystem)
import Atelier.Effects.Log (Log)
import Atelier.Time (Millisecond)
import Tricorder.BuildState (BuildPhase (..), BuildResult (..), BuildState (..))
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
    )
import Tricorder.Runtime (SocketPath (..))
import Tricorder.Socket.Protocol
    ( ErrorResponse (..)
    , Multiplicity (..)
    , Request (..)
    , SomeRequest (..)
    , fromWire
    )
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
        , triggers = pure [acceptTrigger]
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
        Just query -> case fromWire query of
            OnceReq req -> handleOnce req >>= sendJson h
            ManyReq req -> handleMany req (sendJson h)


handleOnce
    :: ( BuildStore :> es
       , Cache (PackageId, ModuleName) Text :> es
       , Cache ModuleName PackageId :> es
       , Delay :> es
       , FileSystem :> es
       , GhcPkg :> es
       , Log :> es
       )
    => Request Once a
    -> Eff es a
handleOnce = \case
    StatusNow -> getState
    StatusAwait -> awaitResult
    Source ms -> mapM lookupModuleSource ms
    DiagnosticAt i -> do
        state <- getState
        pure $ case state.phase of
            Done r -> case r.diagnostics !!? (i - 1) of
                Nothing -> Left $ "No diagnostic #" <> show i <> " (current build has " <> show (length r.diagnostics) <> ")"
                Just d -> Right d
            _ -> Left "Build in progress"


handleMany
    :: (BuildStore :> es)
    => Request Many a
    -> (a -> Eff es ())
    -> Eff es ()
handleMany Watch emit = do
    state0 <- getState
    emit state0
    loop state0
  where
    loop prev = do
        new <- waitForAnyChange prev
        emit new
        loop new


-- | Wait for a completed build, then respond.
--
-- If the build is already done when this is called, we may be racing the file
-- watcher's debounce: a file was just changed but the reload hasn't been
-- dispatched yet (default debounce is 100ms). Poll for up to 250ms to let
-- any in-flight debounce fire before falling back to the current result.
awaitResult :: (BuildStore :> es, Delay :> es) => Eff es BuildState
awaitResult = do
    s <- getState
    case s.phase of
        Building -> waitUntilDone
        Restarting -> waitUntilDone
        Testing _ -> waitUntilDone
        Done _ -> awaitBuildStart (5 :: Int) s
  where
    awaitBuildStart 0 s = pure s
    awaitBuildStart n _ = do
        wait (50 :: Millisecond)
        s' <- getState
        case s'.phase of
            Building -> waitUntilDone
            Restarting -> waitUntilDone
            Testing _ -> waitUntilDone
            Done _ -> awaitBuildStart (n - 1) s'


sendJson :: (ToJSON a, UnixSocket :> es) => Handle -> a -> Eff es ()
sendJson h val = sendLine h (decodeUtf8 (BSL.toStrict (encode val)))
