module Tricorder.Effects.BuildStore
    ( -- * Effect
      BuildStore (..)
    , getState
    , putState
    , waitUntilDone
    , waitForNext
    , waitForAnyChange
    , setPhase
    , modifyPhase
    , markDirty
    , waitDirty
    , hasWaiters

      -- * Interpreters
    , runBuildStoreSTM
    , runBuildStoreRef
    , runBuildStoreScripted
    , runBuildStore
    ) where

import Effectful (Effect)
import Effectful.Concurrent (Concurrent)
import Effectful.Concurrent.STM (TVar, atomically, modifyTVar, newTVar, readTVar, writeTVar)
import Effectful.Dispatch.Dynamic (interpret, reinterpret)
import Effectful.Exception (bracket_)
import Effectful.State.Static.Shared (State, evalState, get, modify, put)
import Effectful.TH (makeEffect)

import Atelier.Effects.Delay (Delay, wait)
import Atelier.Effects.Input (Input, input)
import Atelier.Effects.Publishing (Pub, publish)
import Atelier.Time (Millisecond)
import Tricorder.BuildState
    ( BuildId
    , BuildPhase (..)
    , BuildState (..)
    , BuildStateRef (..)
    , ChangeKind (..)
    , DaemonInfo (..)
    , EnteredNewPhase (..)
    , initialBuildState
    )


data BuildStore :: Effect where
    -- | Read the current build state without blocking.
    GetState :: BuildStore m BuildState
    -- | Overwrite the current build state.
    PutState :: BuildState -> BuildStore m ()
    -- | Block until the current build cycle completes (phase transitions to Done).
    WaitUntilDone :: BuildStore m BuildState
    -- | Block until a completed build with a different 'BuildId' is available.
    WaitForNext :: BuildId -> BuildStore m BuildState
    -- | Block until the build state changes from the given state (any field).
    WaitForAnyChange :: BuildState -> BuildStore m BuildState
    -- | Update the build id and phase without touching other fields (e.g. daemonInfo).
    SetPhase :: BuildId -> BuildPhase -> BuildStore m ()
    -- | Apply a function to the phase of the given build, atomically.
    -- No-ops if the current 'BuildId' does not match — this prevents a late
    -- callback from a cancelled batch from clobbering a fresher build's state.
    ModifyPhase :: BuildId -> (BuildPhase -> BuildPhase) -> BuildStore m ()
    -- | Signal that files have changed and a rebuild is needed.
    -- 'CabalChange' upgrades a pending 'SourceChange' but never downgrades.
    MarkDirty :: ChangeKind -> BuildStore m ()
    -- | Block until dirty, atomically clear the flag, and return the change kind.
    WaitDirty :: BuildStore m ChangeKind
    -- | Return True if any callers are currently blocked in 'waitUntilDone'.
    HasWaiters :: BuildStore m Bool


makeEffect ''BuildStore


-- | Production interpreter backed by a 'TVar'.
--
-- 'waitUntilDone' and 'waitForNext' poll at 50ms intervals rather than using
-- STM @retry@, which avoids @BlockedIndefinitelyOnSTM@ during daemon shutdown:
-- between polls the thread is in an interruptible sleep and can receive
-- async exceptions (e.g. Ki's @ScopeClosing@) cleanly.
runBuildStoreSTM
    :: ( Concurrent :> es
       , Delay :> es
       , Pub EnteredNewPhase :> es
       )
    => Eff (BuildStore : es) a -> Eff es a
runBuildStoreSTM eff = do
    ref <- atomically (newTVar (initialBuildState emptyDaemonInfo))
    dirtyRef <- atomically $ newTVar @(Maybe ChangeKind) Nothing
    waitersRef <- atomically $ newTVar @Int 0
    interpret
        ( \_ -> \case
            GetState -> atomically (readTVar ref)
            PutState s -> atomically (writeTVar ref s)
            WaitUntilDone ->
                bracket_
                    (atomically (modifyTVar waitersRef (+ 1)))
                    (atomically (modifyTVar waitersRef (subtract 1)))
                    (poll ref (not . isBuilding))
            WaitForNext bid -> poll ref \s -> not (isBuilding s) && s.buildId /= bid
            WaitForAnyChange prev -> poll ref (/= prev)
            SetPhase bid phase -> do
                atomically $ modifyTVar ref \bs -> bs {buildId = bid, phase = phase}
                publish (EnteredNewPhase bid phase)
            ModifyPhase bid f -> do
                mNew <- atomically do
                    bs <- readTVar ref
                    if bs.buildId == bid then do
                        let bs' = bs {phase = f bs.phase}
                        writeTVar ref bs'
                        pure (Just bs'.phase)
                    else
                        pure Nothing
                for_ mNew (publish . EnteredNewPhase bid)
            MarkDirty ck -> atomically (modifyTVar dirtyRef (max (Just ck)))
            WaitDirty -> pollDirtyRef dirtyRef
            HasWaiters -> fmap (> 0) $ atomically (readTVar waitersRef)
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
        Building _ -> True
        Restarting -> True
        Testing _ -> True
        Done _ -> False

    emptyDaemonInfo = DaemonInfo {targets = [], watchDirs = [], sockPath = "", logFile = "", metricsPort = Nothing}


-- | Production interpreter that shares a 'BuildStateRef' TVar with writers
-- (e.g. 'GhciSession'). Use this in the daemon instead of 'runBuildStoreSTM'.
runBuildStoreRef
    :: ( Concurrent :> es
       , Delay :> es
       , Input DaemonInfo :> es
       , Pub EnteredNewPhase :> es
       )
    => BuildStateRef -> Eff (BuildStore : es) a -> Eff es a
runBuildStoreRef BuildStateRef {stateRef = ref, dirtyRef, waitersRef} =
    interpret
        ( \_ -> \case
            GetState -> atomically (readTVar ref)
            PutState s -> atomically (writeTVar ref s)
            WaitUntilDone ->
                bracket_
                    (atomically (modifyTVar waitersRef (+ 1)))
                    (atomically (modifyTVar waitersRef (subtract 1)))
                    (pollRef ref (not . isBuilding))
            WaitForNext bid -> pollRef ref \s -> not (isBuilding s) && s.buildId /= bid
            WaitForAnyChange prev -> pollRef ref (/= prev)
            SetPhase bid phase -> do
                daemonInfo <- input
                atomically $ modifyTVar ref \bs -> bs {buildId = bid, phase = phase, daemonInfo}
                publish (EnteredNewPhase bid phase)
            ModifyPhase bid f -> do
                mNew <- atomically do
                    bs <- readTVar ref
                    if bs.buildId == bid then do
                        let bs' = bs {phase = f bs.phase}
                        writeTVar ref bs'
                        pure (Just bs'.phase)
                    else
                        pure Nothing
                for_ mNew (publish . EnteredNewPhase bid)
            MarkDirty ck -> atomically (modifyTVar dirtyRef (max (Just ck)))
            WaitDirty -> pollDirtyRef dirtyRef
            HasWaiters -> fmap (> 0) $ atomically (readTVar waitersRef)
        )
  where
    isBuilding :: BuildState -> Bool
    isBuilding s = case s.phase of
        Building _ -> True
        Restarting -> True
        Testing _ -> True
        Done _ -> False


pollRef :: (Concurrent :> es, Delay :> es) => TVar BuildState -> (BuildState -> Bool) -> Eff es BuildState
pollRef ref predicate = do
    s <- atomically (readTVar ref)
    if predicate s then
        pure s
    else
        wait (50 :: Millisecond) >> pollRef ref predicate


pollDirtyRef :: (Concurrent :> es, Delay :> es) => TVar (Maybe ChangeKind) -> Eff es ChangeKind
pollDirtyRef dirtyRef = do
    v <- atomically (readTVar dirtyRef)
    case v of
        Just ck -> atomically (writeTVar dirtyRef Nothing) >> pure ck
        Nothing -> wait (50 :: Millisecond) >> pollDirtyRef dirtyRef


-- | Scripted interpreter for testing.
--
-- Advances through a pre-loaded list of 'BuildState' values for blocking
-- operations. Useful for testing components that read build state without
-- needing a real 'TVar', concurrency, or pub/sub setup.
--
-- * 'getState' peeks at the head of the list without consuming it.
-- * 'putState' prepends a state, making it the new head.
-- * 'waitUntilDone' pops states until it finds one where @phase /= Building@.
-- * 'waitForNext' pops states until it finds a Done state with a different 'BuildId'.
-- * 'setPhase' / 'modifyPhase' rewrite the head; no events are published.
runBuildStoreScripted :: [BuildState] -> Eff (BuildStore : es) a -> Eff es a
runBuildStoreScripted states = reinterpret (evalState states) $ \_ -> \case
    GetState ->
        get >>= \case
            [] -> error "BuildStoreScripted: getState called on empty state list"
            s : _ -> pure s
    PutState s -> modify (s :)
    WaitUntilDone -> advance (not . isBuilding)
    WaitForNext bid -> advance \s -> not (isBuilding s) && s.buildId /= bid
    WaitForAnyChange prev -> advance (/= prev)
    SetPhase bid phase ->
        get >>= \case
            [] -> pure ()
            s : rest -> put (s {buildId = bid, phase = phase} : rest)
    ModifyPhase bid f ->
        get >>= \case
            [] -> pure ()
            s : rest
                | s.buildId == bid -> put (s {phase = f s.phase} : rest)
                | otherwise -> pure ()
    MarkDirty _ -> pure ()
    WaitDirty -> pure SourceChange
    HasWaiters -> pure False
  where
    isBuilding :: BuildState -> Bool
    isBuilding s = case s.phase of
        Building _ -> True
        Restarting -> True
        Testing _ -> True
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
runBuildStore
    :: ( Concurrent :> es
       , Delay :> es
       , Input DaemonInfo :> es
       , Pub EnteredNewPhase :> es
       )
    => Eff (BuildStore : es) a -> Eff es a
runBuildStore eff = do
    di <- input
    ref <- atomically (newTVar (initialBuildState di))
    dirtyRef <- atomically (newTVar Nothing)
    waitersRef <- atomically (newTVar (0 :: Int))
    runBuildStoreRef BuildStateRef {stateRef = ref, dirtyRef, waitersRef} eff
