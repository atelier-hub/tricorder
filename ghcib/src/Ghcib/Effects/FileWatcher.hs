module Ghcib.Effects.FileWatcher
    ( -- * Effect
      FileWatcher
    , watchDirs

      -- * Interpreters
    , runFileWatcherIO
    , runFileWatcherScripted
    ) where

import Control.Concurrent (threadDelay)
import Control.Concurrent.STM (retry)
import Data.List (isInfixOf)
import Effectful (Effect, IOE)
import Effectful.Concurrent (Concurrent)
import Effectful.Concurrent.STM (atomically)
import Effectful.Dispatch.Dynamic (interpretWith, localSeqUnlift, localUnliftIO, reinterpret)
import Effectful.State.Static.Shared (evalState, get, put)
import Effectful.TH (makeEffect)
import System.FSNotify (Event, eventPath, watchTree, withManager)
import System.FilePath (takeExtension, takeFileName)

import Atelier.Effects.Conc (concStrat)


data FileWatcher :: Effect where
    -- | Watch the given directories recursively for relevant file changes,
    -- calling the callback with the changed file path. Returns whatever the
    -- callback returns; use with 'forever' for a continuous watch loop.
    WatchDirs :: [FilePath] -> (FilePath -> m a) -> FileWatcher m a


makeEffect ''FileWatcher


-- | Production interpreter backed by fsnotify.
-- Encapsulates the 'localUnliftIO' bridge and fsnotify internals.
runFileWatcherIO :: (IOE :> es) => Eff (FileWatcher : es) a -> Eff es a
runFileWatcherIO eff = interpretWith eff \env -> \case
    WatchDirs dirs callback ->
        localUnliftIO env concStrat \unliftIO ->
            withManager \mgr -> do
                for_ dirs \dir ->
                    watchTree mgr dir isRelevant \event ->
                        void $ unliftIO $ callback (eventPath event)
                forever $ threadDelay 1_000_000


-- | Scripted interpreter for testing.
-- Each 'watchDirs' call pops the next path from the list and invokes the
-- callback with it. Blocks indefinitely once the list is exhausted.
runFileWatcherScripted :: (Concurrent :> es) => [FilePath] -> Eff (FileWatcher : es) a -> Eff es a
runFileWatcherScripted paths = reinterpret (evalState paths) \env -> \case
    WatchDirs _ callback ->
        get >>= \case
            p : rest -> put rest >> localSeqUnlift env \unlift -> unlift (callback p)
            [] -> atomically retry


isRelevant :: Event -> Bool
isRelevant event =
    let path = eventPath event
        ext = takeExtension path
        fname = takeFileName path
    in  (ext `elem` [".hs", ".cabal"] || fname `elem` ["cabal.project", "package.yaml"])
            && not ("dist-newstyle" `isInfixOf` path)
