module Tricorder.Web.Server
    ( component
    , ShutdownRequested (..)
    ) where

import Control.Monad.Except (ExceptT (..))
import Effectful (IOE, Limit (..), Persistence (..), UnliftStrategy (..), withEffToIO)
import Effectful.Exception (try)
import Effectful.Reader.Static (Reader, ask)
import Network.Wai.Handler.Warp (defaultSettings, runSettings, setHost, setPort)
import Servant (NoContent (..), SourceIO)
import Servant.Server (Handler (..), hoistServer, serve)
import Servant.Server.Generic (AsServerT)

import Servant.Types.SourceT qualified as SourceT

import Atelier.Component (Component (..), defaultComponent)
import Atelier.Effects.Cache (Cache)
import Atelier.Effects.Delay (Delay)
import Atelier.Effects.Exit (Exit, exitSuccess)
import Atelier.Effects.FileSystem (FileSystem)
import Atelier.Effects.Log (Log)
import Atelier.Effects.Publishing (Pub, Sub)
import Atelier.Time (Millisecond)
import Tricorder.BuildState (BuildPhase (..), BuildResult (..), BuildState (..))
import Tricorder.Effects.BuildStore (BuildStore, getState, waitForAnyChange, waitUntilDone)
import Tricorder.Effects.GhcPkg (GhcPkg)
import Tricorder.SourceLookup (ModuleName, ModuleSourceResult, PackageId, lookupModuleSource)
import Tricorder.Web.API (API, DiagnosticResponse (..), Routes (..))
import Tricorder.Web.Config (Config (..))
import Tricorder.Web.Protocol (DiagnosticQuery (..))

import Atelier.Effects.Delay qualified as Delay
import Atelier.Effects.Log qualified as Log
import Atelier.Effects.Publishing qualified as Pub
import Atelier.Effects.Publishing qualified as Sub


component
    :: ( BuildStore :> es
       , Cache (PackageId, ModuleName) Text :> es
       , Cache ModuleName PackageId :> es
       , Delay :> es
       , Exit :> es
       , FileSystem :> es
       , GhcPkg :> es
       , IOE :> es
       , Log :> es
       , Pub ShutdownRequested :> es
       , Reader Config :> es
       , Sub ShutdownRequested :> es
       )
    => Component es
component =
    defaultComponent
        { name = "WebServer"
        , listeners = pure [Sub.listen_ triggerShutdown]
        , start = do
            cfg <- ask

            Log.info $ "Starting web server on " <> toText cfg.host <> ":" <> show cfg.port

            let settings = setPort cfg.port $ setHost (fromString cfg.host) defaultSettings
            servantApp <- withEffToIO (ConcUnlift Persistent Unlimited) \unlift ->
                pure
                    $ hoistServer
                        (Proxy @API)
                        (Handler . ExceptT . unlift . try)
                        server

            liftIO $ runSettings settings (serve (Proxy @API) servantApp)
        }


data ShutdownRequested = ShutdownRequested


triggerShutdown :: (Delay :> es, Exit :> es) => ShutdownRequested -> Eff es ()
triggerShutdown ShutdownRequested = do
    Delay.wait (500 :: Millisecond)
    exitSuccess


server
    :: ( BuildStore :> es
       , Cache (PackageId, ModuleName) Text :> es
       , Cache ModuleName PackageId :> es
       , Delay :> es
       , FileSystem :> es
       , GhcPkg :> es
       , IOE :> es
       , Log :> es
       , Pub ShutdownRequested :> es
       )
    => Routes (AsServerT (Eff es))
server =
    Routes
        { ping = pure True
        , status = respondStatus
        , watch = watchStream
        , source = respondSource
        , diagnostic = respondDiagnostic
        , quit = do
            Pub.publish ShutdownRequested
            pure NoContent
        }


respondStatus :: (BuildStore :> es, Delay :> es) => Bool -> Eff es BuildState
respondStatus False = getState
respondStatus True = respondWhenDone


-- | Wait for a completed build, then respond.
--
-- If the build is already done when this is called, we may be racing the file
-- watcher's debounce: a file was just changed but the reload hasn't been
-- dispatched yet (default debounce is 100ms). Poll for up to 250ms to let
-- any in-flight debounce fire before falling back to the current result.
respondWhenDone :: (BuildStore :> es, Delay :> es) => Eff es BuildState
respondWhenDone = awaitResult
  where
    awaitResult = do
        s <- getState
        case s.phase of
            Building _ -> waitUntilDone
            Restarting -> waitUntilDone
            Testing _ -> waitUntilDone
            Done _ -> awaitBuildStart (5 :: Int) s

    -- Poll up to n × 50ms for a build to start, then wait for it to finish.
    awaitBuildStart 0 s = pure s
    awaitBuildStart n _ = do
        Delay.wait (50 :: Millisecond)
        s' <- getState
        case s'.phase of
            Building _ -> waitUntilDone
            Restarting -> waitUntilDone
            Testing _ -> waitUntilDone
            Done _ -> awaitBuildStart (n - 1) s'


-- | Stream a JSON object after each state change.
watchStream :: (BuildStore :> es) => (IOE :> es) => Eff es (SourceIO BuildState)
watchStream = do
    withEffToIO (ConcUnlift Persistent Unlimited) \effToIO ->
        pure $ SourceT.fromStepT $ SourceT.Effect do
            state0 <- effToIO getState
            pure
                $ SourceT.Yield state0
                $ SourceT.fromActionStep (const True)
                $ effToIO
                $ waitForAnyChange state0


respondSource
    :: ( Cache (PackageId, ModuleName) Text :> es
       , Cache ModuleName PackageId :> es
       , FileSystem :> es
       , GhcPkg :> es
       , Log :> es
       )
    => [ModuleName] -> Eff es [ModuleSourceResult]
respondSource = traverse lookupModuleSource


respondDiagnostic :: (BuildStore :> es) => Maybe DiagnosticQuery -> Eff es DiagnosticResponse
respondDiagnostic Nothing = pure $ ErrorResponse "Missing index"
respondDiagnostic (Just (DiagnosticQuery idx)) = do
    state <- getState
    case state.phase of
        Done r -> case r.diagnostics !!? (idx - 1) of
            Nothing ->
                pure
                    $ ErrorResponse
                    $ "No diagnostic #"
                        <> show idx
                        <> " (current build has "
                        <> show (length r.diagnostics)
                        <> ")"
            Just d -> pure $ DiagnosticResponse d
        _ -> pure $ ErrorResponse "Build in progress"
