-- | Generic key-value cache effect with pluggable eviction strategies
module Atelier.Effects.Cache
    ( -- * Effect
      Cache
    , cacheLookup
    , cacheInsert
    , cacheDelete
    , cacheModify

      -- * Re-exports
    , module Atelier.Effects.Cache.Config

      -- * Interpreters
    , runCacheTtl
    , runCacheForever
    ) where

import Data.Time (NominalDiffTime, UTCTime, addUTCTime)
import Effectful (Effect)
import Effectful.Concurrent (Concurrent)
import Effectful.Concurrent.STM (STM)
import Effectful.Dispatch.Dynamic (interpretWith)
import Effectful.Reader.Static (Reader, ask)
import Effectful.TH (makeEffect)
import StmContainers.Map (Map)

import Effectful.Concurrent.STM qualified as STM
import ListT qualified
import StmContainers.Map qualified as Map

import Atelier.Effects.Cache.Config
import Atelier.Effects.Clock (Clock, currentTime)
import Atelier.Effects.Conc (Conc)
import Atelier.Effects.Delay (Delay)
import Atelier.Effects.Log (Log)
import Atelier.Time (Microsecond, nominalDiffTime)
import Prelude hiding (Map)

import Atelier.Effects.Conc qualified as Conc
import Atelier.Effects.Delay qualified as Delay
import Atelier.Effects.Log qualified as Log


data Cache key value :: Effect where
    CacheLookup :: key -> Cache key value m (Maybe value)
    CacheInsert :: key -> value -> Cache key value m ()
    CacheDelete :: key -> Cache key value m ()
    CacheModify :: key -> (Maybe value -> value) -> Cache key value m value


makeEffect ''Cache


-- | Internal entry wrapping a value with its insertion timestamp
data CacheEntry value = CacheEntry
    { value :: !value
    , createdAt :: !UTCTime
    }


-- | Run the Cache effect with TTL-based eviction
--
-- Entries are evicted after @entryTtl@ from their first insertion.
-- Subsequent updates to the same key preserve the original timestamp.
-- A background thread runs every @cleanupInterval@ to remove expired entries.
runCacheTtl
    :: forall key value es a
     . ( Clock :> es
       , Conc :> es
       , Concurrent :> es
       , Delay :> es
       , Hashable key
       , Log :> es
       , Reader Config :> es
       )
    => Eff (Cache key value : es) a
    -> Eff es a
runCacheTtl action = do
    cfg <- ask @Config
    store <- STM.atomically (Map.new :: STM (Map key (CacheEntry value)))

    Conc.fork_ $ forever $ Log.withNamespace "Cache" do
        Delay.wait $ nominalDiffTime @Microsecond cfg.cleanupInterval
        now <- currentTime
        evicted <- STM.atomically $ evictExpiredEntries store cfg.entryTtl now

        when (evicted > 0)
            $ Log.debug
            $ "Evicted " <> show evicted <> " entries"

    interpretWith action $ \_ -> \case
        CacheLookup key ->
            fmap (.value) <$> STM.atomically (Map.lookup key store)
        CacheInsert key val -> do
            now <- currentTime
            STM.atomically $ do
                existing <- Map.lookup key store
                let entry = case existing of
                        Nothing -> CacheEntry {value = val, createdAt = now}
                        Just e -> e {value = val} -- preserve original timestamp
                Map.insert entry key store
        CacheDelete key ->
            STM.atomically $ Map.delete key store
        CacheModify key f -> do
            now <- currentTime
            STM.atomically $ do
                existing <- Map.lookup key store
                let newEntry = case existing of
                        Nothing -> CacheEntry {value = f Nothing, createdAt = now}
                        Just e -> e {value = f (Just e.value)}
                Map.insert newEntry key store
                pure newEntry.value


evictExpiredEntries
    :: (Hashable key)
    => Map key (CacheEntry value)
    -> NominalDiffTime
    -> UTCTime
    -> STM Int
evictExpiredEntries store ttl now =
    ListT.fold
        ( \count (k, v) ->
            if now >= addUTCTime ttl v.createdAt then
                Map.delete k store $> count + 1
            else
                pure count
        )
        0
        $ Map.listT store


-- | Run the Cache effect with no TTL (entries live forever).
--
-- Uses a plain STM 'Map' with no eviction. Useful for tests and
-- session-scoped caches where eviction is never needed.
runCacheForever
    :: forall key value es a
     . (Concurrent :> es, Hashable key)
    => Eff (Cache key value : es) a
    -> Eff es a
runCacheForever action = do
    store <- STM.atomically (Map.new :: STM (Map key value))
    interpretWith action $ \_ -> \case
        CacheLookup key ->
            STM.atomically $ Map.lookup key store
        CacheInsert key val ->
            STM.atomically $ Map.insert val key store
        CacheDelete key ->
            STM.atomically $ Map.delete key store
        CacheModify key f ->
            STM.atomically $ do
                existing <- Map.lookup key store
                let newVal = f existing
                Map.insert newVal key store
                pure newVal
