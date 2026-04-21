module Atelier.Effects.Conc
    ( -- * Effect
      Conc (..)
    , Thread
    , fork
    , fork_
    , await
    , awaitAll
    , forkTry

      -- * Scope
    , Scope (..)
    , scoped

      -- * Interpreters
    , runConcBase
    , runConc

      -- * Unlift Strategy
    , concStrat
    )
where

import Effectful (Effect, IOE, Limit (..), Persistence (..), UnliftStrategy (..), raise, withEffToIO)
import Effectful.Concurrent.STM (atomically, runConcurrent)
import Effectful.Dispatch.Dynamic (EffectHandler, interpose, interpret, localLend, localUnlift, localUnliftIO)
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
    Scoped :: m a -> Conc m a


newtype Scope = Scope Ki.Scope


newtype Thread a = Thread (Ki.Thread a)


makeEffect ''Conc


-- | Base interpreter: resolves 'Conc' operations using Ki.
--
-- Does not handle trace context propagation. Use 'Atelier.Effects.Conc.Traced.runConc'
-- for automatic span link propagation across forks.
runConcBase :: forall es a. (IOE :> es) => Scope -> Eff (Conc : es) a -> Eff es a
runConcBase (Scope scope0) = interpret $ handler @es scope0
  where
    handler :: forall es'. (IOE :> es') => Ki.Scope -> EffectHandler Conc es'
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
        Scoped m ->
            localUnlift env concStrat \unliftEff ->
                localLend @'[IOE] env concStrat \lend ->
                    withEffToIO concStrat \unliftIO ->
                        Ki.scoped \subScope ->
                            unliftIO
                                . unliftEff
                                . lend
                                . interpose (handler subScope)
                                . raise @IOE
                                $ m


-- | Run 'Conc' in a new Ki scope without trace context propagation.
--
-- Suitable for tests and contexts where tracing is not needed.
runConc :: (IOE :> es) => Eff (Conc : es) a -> Eff es a
runConc eff = withEffToIO concStrat $ \unlift ->
    Ki.scoped $ \scope ->
        unlift $ runConcBase (Scope scope) eff


concStrat :: UnliftStrategy
concStrat = ConcUnlift Persistent Unlimited
