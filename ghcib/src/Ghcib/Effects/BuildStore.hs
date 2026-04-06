module Ghcib.Effects.BuildStore
    ( -- * Effect
      BuildStore
    , getState
    , putState
    , waitUntilDone
    , waitForNext
    , setPhase
    , markDirty
    , waitDirty

      -- * Interpreters
    , runBuildStoreSTM
    , runBuildStoreRef
    , runBuildStoreScripted
    , runBuildStore
    ) where

import Effectful (Effect)
import Effectful.Concurrent (Concurrent)
import Effectful.Concurrent.STM (TVar, atomically, modifyTVar, newTVar, readTVar, writeTVar)
import Effectful.Dispatch.Dynamic (interpret_, reinterpret)
import Effectful.State.Static.Shared (State, evalState, get, modify, put)
import Effectful.TH (makeEffect)

import Atelier.Effects.Delay (Delay, wait)
import Atelier.Time (Millisecond)
import Ghcib.BuildState (BuildId, BuildPhase (..), BuildState (..), BuildStateRef (..), DaemonInfo (..), initialBuildState)


data BuildStore :: Effect where
    -- | Read the current build state without blocking.
    GetState :: BuildStore m BuildState
    -- | Overwrite the current build state.
    PutState :: BuildState -> BuildStore m ()
    -- | Block until the current build cycle completes (phase transitions to Done).
    WaitUntilDone :: BuildStore m BuildState
    -- | Block until a completed build with a different 'BuildId' is available.
    WaitForNext :: BuildId -> BuildStore m BuildState
    -- | Update the build id and phase without touching other fields (e.g. daemonInfo).
    SetPhase :: BuildId -> BuildPhase -> BuildStore m ()
    -- | Signal that source files have changed and a rebuild is needed.
    MarkDirty :: BuildStore m ()
    -- | Block until dirty, then atomically clear the flag and return.
    WaitDirty :: BuildStore m ()


makeEffect ''BuildStore


-- | Production interpreter backed by a 'TVar'.
--
-- 'waitUntilDone' and 'waitForNext' poll at 50ms intervals rather than using
-- STM @retry@, which avoids @BlockedIndefinitelyOnSTM@ during daemon shutdown:
-- between polls the thread is in an interruptible sleep and can receive
-- async exceptions (e.g. Ki's @ScopeClosing@) cleanly.
runBuildStoreSTM :: (Concurrent :> es, Delay :> es) => Eff (BuildStore : es) a -> Eff es a
runBuildStoreSTM eff = do
    ref <- atomically (newTVar (initialBuildState emptyDaemonInfo))
    dirtyRef <- atomically (newTVar False)
    interpret_
        ( \case
            GetState -> atomically (readTVar ref)
            PutState s -> atomically (writeTVar ref s)
            WaitUntilDone -> poll ref (not . isBuilding)
            WaitForNext bid -> poll ref \s -> not (isBuilding s) && s.buildId /= bid
            SetPhase bid phase -> atomically $ modifyTVar ref \bs -> bs {buildId = bid, phase = phase}
            MarkDirty -> atomically (writeTVar dirtyRef True)
            WaitDirty -> pollDirtyRef dirtyRef
        )
        eff
  where
    poll ref predicate = do
        s <- atomically (readTVar ref)
        if predicate s then
            pure s
        else
            wait (50 :: Millisecond) >> poll ref predicate

    isBuilding :: BuildState -> Bool
    isBuilding s = case s.phase of
        Building -> True
        Done _ -> False

    emptyDaemonInfo = DaemonInfo {targets = [], watchDirs = [], sockPath = "", logFile = Nothing}


-- | Production interpreter that shares a 'BuildStateRef' TVar with writers
-- (e.g. 'GhciSession'). Use this in the daemon instead of 'runBuildStoreSTM'.
runBuildStoreRef :: (Concurrent :> es, Delay :> es) => BuildStateRef -> Eff (BuildStore : es) a -> Eff es a
runBuildStoreRef BuildStateRef {stateRef = ref, dirtyRef} =
    interpret_
        ( \case
            GetState -> atomically (readTVar ref)
            PutState s -> atomically (writeTVar ref s)
            WaitUntilDone -> pollRef ref (not . isBuilding)
            WaitForNext bid -> pollRef ref \s -> not (isBuilding s) && s.buildId /= bid
            SetPhase bid phase -> atomically $ modifyTVar ref \bs -> bs {buildId = bid, phase = phase}
            MarkDirty -> atomically (writeTVar dirtyRef True)
            WaitDirty -> pollDirtyRef dirtyRef
        )
  where
    isBuilding :: BuildState -> Bool
    isBuilding s = case s.phase of
        Building -> True
        Done _ -> False


pollRef :: (Concurrent :> es, Delay :> es) => TVar BuildState -> (BuildState -> Bool) -> Eff es BuildState
pollRef ref predicate = do
    s <- atomically (readTVar ref)
    if predicate s then
        pure s
    else
        wait (50 :: Millisecond) >> pollRef ref predicate


pollDirtyRef :: (Concurrent :> es, Delay :> es) => TVar Bool -> Eff es ()
pollDirtyRef dirtyRef = do
    v <- atomically (readTVar dirtyRef)
    if v then
        atomically (writeTVar dirtyRef False)
    else
        wait (50 :: Millisecond) >> pollDirtyRef dirtyRef


-- | Scripted interpreter for testing.
--
-- Advances through a pre-loaded list of 'BuildState' values for blocking
-- operations. Useful for testing components that read build state without
-- needing a real 'TVar' or concurrency.
--
-- * 'getState' peeks at the head of the list without consuming it.
-- * 'putState' prepends a state, making it the new head.
-- * 'waitUntilDone' pops states until it finds one where @phase /= Building@.
-- * 'waitForNext' pops states until it finds a Done state with a different 'BuildId'.
runBuildStoreScripted :: [BuildState] -> Eff (BuildStore : es) a -> Eff es a
runBuildStoreScripted states = reinterpret (evalState states) $ \_ -> \case
    GetState ->
        get >>= \case
            [] -> error "BuildStoreScripted: getState called on empty state list"
            s : _ -> pure s
    PutState s -> modify (s :)
    WaitUntilDone -> advance (not . isBuilding)
    WaitForNext bid -> advance \s -> not (isBuilding s) && s.buildId /= bid
    SetPhase bid phase ->
        get >>= \case
            [] -> pure ()
            s : rest -> put (s {buildId = bid, phase = phase} : rest)
    MarkDirty -> pure ()
    WaitDirty -> pure ()
  where
    isBuilding :: BuildState -> Bool
    isBuilding s = case s.phase of
        Building -> True
        Done _ -> False

    advance :: (BuildState -> Bool) -> Eff (State [BuildState] : es) BuildState
    advance predicate =
        get >>= \case
            [] -> error "BuildStoreScripted: no matching state in list"
            s : rest
                | predicate s -> put rest >> pure s
                | otherwise -> put rest >> advance predicate


-- | Production interpreter for use in the daemon.
--
-- Creates a 'TVar' initialised with 'initialBuildState' for the given
-- 'DaemonInfo' and runs the supplied action under 'runBuildStoreRef'.
runBuildStore :: (Concurrent :> es, Delay :> es) => DaemonInfo -> Eff (BuildStore : es) a -> Eff es a
runBuildStore di eff = do
    ref <- atomically (newTVar (initialBuildState di))
    dirtyRef <- atomically (newTVar False)
    runBuildStoreRef BuildStateRef {stateRef = ref, dirtyRef} eff
