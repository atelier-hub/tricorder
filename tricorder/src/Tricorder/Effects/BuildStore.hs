module Tricorder.Effects.BuildStore
    ( -- * Effect
      BuildStore (..)
    , getState
    , putState
    , waitUntilDone
    , waitForNext
    , waitForAnyChange
    , setPhase
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
import Effectful.Concurrent.STM (TChan, TVar, atomically, dupTChan, modifyTVar, newBroadcastTChan, newTVar, readTChan, readTVar, retry, writeTChan, writeTVar)
import Effectful.Dispatch.Dynamic (interpret_, reinterpret)
import Effectful.Exception (bracket_)
import Effectful.State.Static.Shared (State, evalState, get, modify, put)
import Effectful.TH (makeEffect)

import Atelier.Effects.Input (Input, input)
import Tricorder.BuildState
    ( BuildId
    , BuildPhase (..)
    , BuildState (..)
    , BuildStateRef (..)
    , ChangeKind (..)
    , DaemonInfo (..)
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
-- Blocking operations use STM @retry@ rather than polling, so a transient
-- 'Done' state cannot be missed by a poll cycle landing on the surrounding
-- 'Building' phases. 'atomically' is interruptible, so async exceptions
-- (e.g. Ki's @ScopeClosing@) propagate during daemon shutdown.
runBuildStoreSTM :: (Concurrent :> es) => Eff (BuildStore : es) a -> Eff es a
runBuildStoreSTM eff = do
    ref <- atomically (newTVar (initialBuildState emptyDaemonInfo))
    dirtyRef <- atomically $ newTVar @(Maybe ChangeKind) Nothing
    waitersRef <- atomically $ newTVar @Int 0
    transitions <- atomically (newBroadcastTChan @BuildState)
    interpret_
        ( \case
            GetState -> atomically (readTVar ref)
            PutState s -> setState ref transitions s
            WaitUntilDone ->
                bracket_
                    (atomically (modifyTVar waitersRef (+ 1)))
                    (atomically (modifyTVar waitersRef (subtract 1)))
                    (waitForState ref transitions (not . isBuilding))
            WaitForNext bid ->
                waitForState ref transitions \s -> not (isBuilding s) && s.buildId /= bid
            WaitForAnyChange prev -> waitForState ref transitions (/= prev)
            SetPhase bid phase -> atomically do
                modifyTVar ref \bs -> bs {buildId = bid, phase = phase}
                readTVar ref >>= writeTChan transitions
            MarkDirty ck -> atomically (modifyTVar dirtyRef (max (Just ck)))
            WaitDirty -> takeDirty dirtyRef
            HasWaiters -> fmap (> 0) $ atomically (readTVar waitersRef)
        )
        eff
  where
    emptyDaemonInfo = DaemonInfo {targets = [], watchDirs = [], sockPath = "", logFile = "", metricsPort = Nothing}


-- | Production interpreter that shares a 'BuildStateRef' TVar with writers
-- (e.g. 'GhciSession'). Use this in the daemon instead of 'runBuildStoreSTM'.
runBuildStoreRef
    :: ( Concurrent :> es
       , Input DaemonInfo :> es
       )
    => BuildStateRef -> Eff (BuildStore : es) a -> Eff es a
runBuildStoreRef BuildStateRef {stateRef = ref, dirtyRef, waitersRef, transitions} =
    interpret_
        ( \case
            GetState -> atomically (readTVar ref)
            PutState s -> setState ref transitions s
            WaitUntilDone ->
                bracket_
                    (atomically (modifyTVar waitersRef (+ 1)))
                    (atomically (modifyTVar waitersRef (subtract 1)))
                    (waitForState ref transitions (not . isBuilding))
            WaitForNext bid ->
                waitForState ref transitions \s -> not (isBuilding s) && s.buildId /= bid
            WaitForAnyChange prev -> waitForState ref transitions (/= prev)
            SetPhase bid phase -> do
                daemonInfo <- input
                atomically do
                    modifyTVar ref \bs -> bs {buildId = bid, phase = phase, daemonInfo}
                    readTVar ref >>= writeTChan transitions
            MarkDirty ck -> atomically (modifyTVar dirtyRef (max (Just ck)))
            WaitDirty -> takeDirty dirtyRef
            HasWaiters -> fmap (> 0) $ atomically (readTVar waitersRef)
        )


isBuilding :: BuildState -> Bool
isBuilding s = case s.phase of
    Building _ -> True
    Restarting -> True
    Testing _ -> True
    Done _ -> False


-- | Atomically replace the build state and broadcast it. Used by
-- 'PutState' so direct overrides also surface on the transitions channel.
setState :: (Concurrent :> es) => TVar BuildState -> TChan BuildState -> BuildState -> Eff es ()
setState ref transitions s = atomically do
    writeTVar ref s
    writeTChan transitions s


-- | Block until the build state satisfies @predicate@, then return it.
--
-- Subscribes to 'transitions' before reading the current state, so every
-- subsequent state change is observable as a discrete message even if the
-- TVar value is overwritten before the waiter is rescheduled. This is what
-- prevents a transient 'Done' from being missed when 'Building (N+1)'
-- follows it within the scheduler's wake-up latency.
waitForState
    :: (Concurrent :> es)
    => TVar BuildState
    -> TChan BuildState
    -> (BuildState -> Bool)
    -> Eff es BuildState
waitForState ref transitions predicate = do
    myChan <- atomically (dupTChan transitions)
    -- Snapshot AFTER subscribing so we don't race past a transition: any
    -- state change that happens between subscribing and reading 'ref' also
    -- lands on 'myChan', so the loop will pick it up.
    s0 <- atomically (readTVar ref)
    if predicate s0 then pure s0 else drainUntilMatch myChan
  where
    drainUntilMatch ch = do
        s <- atomically (readTChan ch)
        if predicate s then pure s else drainUntilMatch ch


-- | Atomically take the dirty marker, blocking until one is set.
takeDirty :: (Concurrent :> es) => TVar (Maybe ChangeKind) -> Eff es ChangeKind
takeDirty dirtyRef = atomically do
    readTVar dirtyRef >>= \case
        Just ck -> writeTVar dirtyRef Nothing >> pure ck
        Nothing -> retry


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
    WaitForAnyChange prev -> advance (/= prev)
    SetPhase bid phase -> do
        get >>= \case
            [] -> pure ()
            s : rest -> put (s {buildId = bid, phase = phase} : rest)
    MarkDirty _ -> pure ()
    WaitDirty -> pure SourceChange
    HasWaiters -> pure False
  where
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
       , Input DaemonInfo :> es
       )
    => Eff (BuildStore : es) a -> Eff es a
runBuildStore eff = do
    di <- input
    ref <- atomically (newTVar (initialBuildState di))
    dirtyRef <- atomically (newTVar Nothing)
    waitersRef <- atomically (newTVar (0 :: Int))
    transitions <- atomically newBroadcastTChan
    runBuildStoreRef BuildStateRef {stateRef = ref, dirtyRef, waitersRef, transitions} eff
