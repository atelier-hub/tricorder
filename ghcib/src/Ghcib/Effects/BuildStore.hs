module Ghcib.Effects.BuildStore
    ( -- * Effect
      BuildStore
    , getState
    , putState
    , waitUntilDone
    , waitForNext

      -- * Interpreters
    , runBuildStoreSTM
    , runBuildStoreRef
    , runBuildStoreScripted
    ) where

import Effectful (Effect)
import Effectful.Concurrent (Concurrent)
import Effectful.Concurrent.STM (TVar, atomically, newTVar, readTVar, writeTVar)
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
    interpret_
        ( \case
            GetState -> atomically (readTVar ref)
            PutState s -> atomically (writeTVar ref s)
            WaitUntilDone -> poll ref (not . isBuilding)
            WaitForNext bid -> poll ref \s -> not (isBuilding s) && s.buildId /= bid
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
        Done _ _ _ -> False

    emptyDaemonInfo = DaemonInfo {targets = [], watchDirs = [], sockPath = "", logFile = Nothing}


-- | Production interpreter that shares a 'BuildStateRef' TVar with writers
-- (e.g. 'GhciSession'). Use this in the daemon instead of 'runBuildStoreSTM'.
runBuildStoreRef :: (Concurrent :> es, Delay :> es) => BuildStateRef -> Eff (BuildStore : es) a -> Eff es a
runBuildStoreRef (BuildStateRef ref) =
    interpret_
        ( \case
            GetState -> atomically (readTVar ref)
            PutState s -> atomically (writeTVar ref s)
            WaitUntilDone -> pollRef ref (not . isBuilding)
            WaitForNext bid -> pollRef ref \s -> not (isBuilding s) && s.buildId /= bid
        )
  where
    isBuilding :: BuildState -> Bool
    isBuilding s = case s.phase of
        Building -> True
        Done _ _ _ -> False


pollRef :: (Concurrent :> es, Delay :> es) => TVar BuildState -> (BuildState -> Bool) -> Eff es BuildState
pollRef ref predicate = do
    s <- atomically (readTVar ref)
    if predicate s then
        pure s
    else
        wait (50 :: Millisecond) >> pollRef ref predicate


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
  where
    isBuilding :: BuildState -> Bool
    isBuilding s = case s.phase of
        Building -> True
        Done _ _ _ -> False

    advance :: (BuildState -> Bool) -> Eff (State [BuildState] : es) BuildState
    advance predicate =
        get >>= \case
            [] -> error "BuildStoreScripted: no matching state in list"
            s : rest
                | predicate s -> put rest >> pure s
                | otherwise -> put rest >> advance predicate
