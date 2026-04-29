module Tricorder.RPC
    ( runClient
    , runHandler
    ) where

import Effectful.Dispatch.Dynamic (LocalEnv, interpretWith, localSeqUnlift)
import Effectful.Reader.Static (Reader, ask)

import Atelier.Effects.Cache (Cache)
import Atelier.Effects.Delay (Delay, wait)
import Atelier.Effects.FileSystem (FileSystem)
import Atelier.Effects.Log (Log)
import Atelier.Effects.RPC (Client, Handler (..))
import Atelier.Effects.RPC.Unix (runClientUnix)
import Atelier.Effects.UnixSocket (UnixSocket)
import Atelier.Time (Millisecond)
import Tricorder.BuildState (BuildPhase (..), BuildResult (..), BuildState (..), Diagnostic)
import Tricorder.Effects.BuildStore (BuildStore, getState, waitForAnyChange, waitUntilDone)
import Tricorder.Effects.GhcPkg (GhcPkg)
import Tricorder.GhcPkg.Types (ModuleName, PackageId)
import Tricorder.RPC.Protocol (Protocol (..))
import Tricorder.Runtime (SocketPath (..))
import Tricorder.SourceLookup (lookupModuleSource)


runClient
    :: (Reader SocketPath :> es, UnixSocket :> es)
    => Eff (Client req : es) a
    -> Eff es a
runClient action = do
    SocketPath sp <- ask
    runClientUnix sp action


runHandler
    :: ( BuildStore :> es
       , Cache (PackageId, ModuleName) Text :> es
       , Cache ModuleName PackageId :> es
       , Delay :> es
       , FileSystem :> es
       , GhcPkg :> es
       , Log :> es
       )
    => Eff (Handler Protocol : es) a
    -> Eff es a
runHandler eff = interpretWith eff \env -> \case
    ServeOnce req -> case req of
        StatusNow -> getState
        StatusAwait -> awaitResult
        Source ms -> mapM lookupModuleSource ms
        DiagnosticAt i -> lookupDiagnostic i
    ServeMany Watch callback -> watchBuildState env callback


lookupDiagnostic :: (BuildStore :> es) => Int -> Eff es (Either Text Diagnostic)
lookupDiagnostic i = do
    state <- getState
    pure $ case state.phase of
        Done r -> case r.diagnostics !!? (i - 1) of
            Nothing -> Left $ "No diagnostic #" <> show i <> " (current build has " <> show (length r.diagnostics) <> ")"
            Just d -> Right d
        _ -> Left "Build in progress"


watchBuildState
    :: (BuildStore :> es)
    => LocalEnv localEs es
    -> (BuildState -> Eff localEs ())
    -> Eff es ()
watchBuildState env callback = localSeqUnlift env \unlift -> do
    state0 <- getState
    unlift (callback state0)
    let loop prev = do
            new <- waitForAnyChange prev
            unlift (callback new)
            loop new
    loop state0


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
