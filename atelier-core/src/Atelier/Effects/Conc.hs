module Atelier.Effects.Conc
    ( -- * Effect
      Conc (..)
    , Thread
    , fork
    , fork_
    , await
    , awaitAll
    , forkTry
    , race

      -- * Scope
    , Scope (..)
    , scoped
    , restartableForkWith
    , restartableForkLoop

      -- * Interpreters
    , runConcBase
    , runConc

      -- * Unlift Strategy
    , concStrat
    )
where

import Effectful
    ( Effect
    , IOE
    , Limit (..)
    , Persistence (..)
    , UnliftStrategy (..)
    , inject
    , withEffToIO
    )
import Effectful.Concurrent.MVar (Concurrent, newEmptyMVar, putMVar, takeMVar)
import Effectful.Concurrent.STM (atomically, runConcurrent)
import Effectful.Dispatch.Dynamic
    ( EffectHandler
    , interpose
    , interpret
    , localLend
    , localUnlift
    , localUnliftIO
    )
import Effectful.TH (makeEffect)

import Ki qualified


data Conc :: Effect where
    -- | Fork a thread that terminates. Use @void . fork@ to discard the handle.
    Fork :: m a -> Conc m (Thread a)
    -- | Fork a thread that never terminates (e.g. a server loop).
    -- The @Void@ return type enforces this — use 'fork' for threads that exit.
    Fork_ :: m Void -> Conc m ()
    Await :: Thread a -> Conc m a
    AwaitAll :: Conc m ()
    ForkTry :: (Exception e) => m a -> Conc m (Thread (Either e a))
    -- | Races two computations concurrently and returns the result of the
    -- operation that finished first.
    Race :: m a -> m b -> Conc m (Either a b)
    Scoped :: m a -> Conc m a


newtype Scope = Scope Ki.Scope


newtype Thread a = Thread (Ki.Thread a)


makeEffect ''Conc


-- | Forks an action in a loop, with a setup step that runs in the scope before
-- each fork. Each time @signal@ returns, the current fork is cancelled, and
-- setup and fork are run again. The setup result is passed to the forked
-- action, structurally guaranteeing it completes before the fork starts.
restartableForkWith :: (Conc :> es) => Eff es () -> Eff es r -> (r -> Eff es a) -> Eff es Void
restartableForkWith signal setup action = forever $ scoped do
    r <- setup
    _ <- fork (action r)
    signal


-- | Like 'restartableForkWith', but threads a value across iterations: the
-- signal returns the next @r@, which is passed to the next fork. The initial
-- @r@ seeds the first fork.
restartableForkLoop :: (Conc :> es) => r -> Eff es r -> (r -> Eff es a) -> Eff es Void
restartableForkLoop initial signal action = go initial
  where
    go r = scoped do
        _ <- fork (action r)
        r' <- signal
        go r'


-- | Base interpreter: resolves 'Conc' operations using Ki.
--
-- Does not handle trace context propagation. Use 'Atelier.Effects.Conc.Traced.runConc'
-- for automatic span link propagation across forks.
runConcBase :: forall es a. (Concurrent :> es, IOE :> es) => Scope -> Eff (Conc : es) a -> Eff es a
runConcBase (Scope scope0) = interpret $ handler @es scope0
  where
    handler :: forall es'. (Concurrent :> es', IOE :> es') => Ki.Scope -> EffectHandler Conc es'
    handler scope env = \case
        Fork action ->
            localUnliftIO env concStrat \unlift ->
                fmap Thread . liftIO . Ki.fork scope $ unlift action
        Fork_ action ->
            localUnliftIO env concStrat \unlift ->
                Ki.fork_ scope $ unlift action
        ForkTry action ->
            localUnliftIO env concStrat \unlift ->
                fmap Thread . liftIO . Ki.forkTry scope $ unlift action
        Await (Thread thread) ->
            runConcurrent . atomically $ Ki.await thread
        AwaitAll ->
            runConcurrent . atomically $ Ki.awaitAll scope
        Race ma mb ->
            localLend @'[Concurrent] env concStrat \lend ->
                localUnliftIO env concStrat \unlift ->
                    Ki.scoped \raceScope -> do
                        ref <- unlift $ inject $ lend newEmptyMVar
                        void
                            $ Ki.fork raceScope
                            $ unlift
                            $ lend . putMVar ref . Left =<< ma
                        void
                            $ Ki.fork raceScope
                            $ unlift
                            $ lend . putMVar ref . Right =<< mb
                        unlift $ lend $ takeMVar ref
        Scoped m ->
            localUnlift env concStrat \unliftEff ->
                localLend @'[IOE, Concurrent] env concStrat \lend ->
                    withEffToIO concStrat \unliftIO ->
                        Ki.scoped \subScope ->
                            unliftIO
                                . unliftEff
                                . lend
                                . interpose (handler subScope)
                                . inject
                                $ m


-- | Run 'Conc' in a new Ki scope without trace context propagation.
--
-- Suitable for tests and contexts where tracing is not needed.
runConc :: (Concurrent :> es, IOE :> es) => Eff (Conc : es) a -> Eff es a
runConc eff = withEffToIO concStrat $ \unlift ->
    Ki.scoped $ \scope ->
        unlift $ runConcBase (Scope scope) eff


concStrat :: UnliftStrategy
concStrat = ConcUnlift Persistent Unlimited
