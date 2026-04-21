-- | Effect and smart constructors for watching file system paths.
--
-- == Overview
--
-- Build a list of 'Watch' values describing what to observe, then pass them
-- to 'watchFilePaths'. The effect registers the OS-level watchers needed to
-- cover the list (deduplication by path prefix) and fires the callback at most
-- once per raw filesystem event for a path.
--
-- == Examples
--
-- Watch a source directory for Haskell files, ignoring build artefacts:
--
-- @
-- watchFilePaths [dirExt "src" ".hs" \`excluding\` containing "dist-newstyle"] callback
-- @
--
-- Watch source and test directories together:
--
-- @
-- watchFilePaths (map (\`dirExt\` ".hs") ["src", "test"]) callback
-- @
--
-- Watch cabal-related files anywhere under a project root:
--
-- @
-- watchFilePaths [dirWhere projectRoot isCabalFile] callback
--   where
--     isCabalFile f = takeExtension f == ".cabal"
--                  || takeFileName f \`elem\` ["cabal.project", "package.yaml"]
-- @
--
-- Combine source and cabal watches with a single callback that dispatches on
-- the path, with automatic debouncing:
--
-- @
-- watchFilePathsDebounced (sourceWatches ++ cabalWatches) (markDirty . changeKindFor)
-- @
module Atelier.Effects.FileWatcher
    ( -- * Watch specification
      Watch

      -- ** Constructors
    , dir
    , dirExt
    , dirWhere

      -- ** Combinators
    , excluding
    , containing

      -- * Effect
    , FileWatcher
    , watchFilePaths
    , watchFilePathsDebounced

      -- * Interpreters
    , runFileWatcherIO
    , runFileWatcherScripted

      -- * Internals (exported for testing)
    , deduplicateDirs
    , matchesAny
    ) where

import Control.Concurrent (threadDelay)
import Control.Concurrent.STM (retry)
import Data.List (nub)
import Effectful (Effect, IOE)
import Effectful.Concurrent (Concurrent)
import Effectful.Concurrent.STM (atomically)
import Effectful.Dispatch.Dynamic (interpretWith, localSeqUnlift, localUnliftIO, reinterpret)
import Effectful.State.Static.Shared (evalState, get, put)
import Effectful.TH (makeEffect)
import System.Directory (makeAbsolute)
import System.FSNotify (eventPath, watchTree, withManager)
import System.FilePath (takeExtension)

import Data.Text qualified as T

import Atelier.Effects.Conc (concStrat)
import Atelier.Effects.Debounce (Debounce, debounced)


-- | Specification of a directory to watch recursively, with a file predicate.
data Watch = Watch FilePath (FilePath -> Bool)


-- | Watch all files in a directory recursively.
dir :: FilePath -> Watch
dir p = Watch p (const True)


-- | Watch files matching a predicate in a directory recursively.
--
-- @
-- dirWhere "src" (\f -> takeExtension f == ".hs")
-- @
dirWhere :: FilePath -> (FilePath -> Bool) -> Watch
dirWhere = Watch


-- | Watch files with a specific extension in a directory recursively.
--
-- @
-- dirExt "src" ".hs"
-- @
dirExt :: FilePath -> Text -> Watch
dirExt p ext = dirWhere p (\f -> toText (takeExtension f) == ext)


-- | Narrow a 'Watch' to exclude files matching a predicate.
--
-- @
-- dirExt "src" ".hs" \`excluding\` containing "dist-newstyle"
-- @
excluding :: Watch -> (FilePath -> Bool) -> Watch
excluding (Watch p predicate) excl = Watch p (\f -> predicate f && not (excl f))


-- | Predicate: the file path contains the given fragment.
--
-- Intended for use with 'excluding':
--
-- @
-- dir "src" \`excluding\` containing "dist-newstyle"
-- @
containing :: Text -> FilePath -> Bool
containing fragment f = fragment `T.isInfixOf` toText f


data FileWatcher :: Effect where
    -- | Watch the given directories for changes, calling the callback with
    -- each matching file path. Registers the minimal set of OS watchers needed
    -- to cover all entries (deduplication by path prefix). The callback is
    -- invoked at most once per raw filesystem event regardless of how many
    -- entries match. Never returns.
    WatchFilePaths :: [Watch] -> (FilePath -> m a) -> FileWatcher m Void


makeEffect ''FileWatcher


-- | Like 'watchFilePaths' but automatically debounces by path.
-- Rapid successive events for the same file coalesce into a single callback.
watchFilePathsDebounced
    :: (Debounce FilePath :> es, FileWatcher :> es)
    => [Watch]
    -> (FilePath -> Eff es ())
    -> Eff es Void
watchFilePathsDebounced watches callback =
    watchFilePaths watches \path -> debounced path (callback path)


-- | Production interpreter backed by fsnotify.
runFileWatcherIO :: (IOE :> es) => Eff (FileWatcher : es) a -> Eff es a
runFileWatcherIO eff = interpretWith eff \env -> \case
    WatchFilePaths watches callback ->
        localUnliftIO env concStrat \unliftIO -> do
            absWatches <- forM watches \(Watch p predicate) ->
                (\absP -> Watch absP predicate) <$> makeAbsolute p
            withManager \mgr -> do
                let dedupedDirs = deduplicateDirs [p | Watch p _ <- absWatches]
                for_ dedupedDirs \d ->
                    watchTree mgr d (matchesAny absWatches . eventPath) \event ->
                        void $ unliftIO $ callback (eventPath event)
                forever $ threadDelay 1_000_000


-- | Scripted interpreter for testing.
-- Delivers all scripted paths to the callback in order, then blocks
-- indefinitely — matching the blocking semantics of 'runFileWatcherIO'.
-- The 'Watch' specification is ignored; the caller controls what paths are fed in.
runFileWatcherScripted :: (Concurrent :> es) => [FilePath] -> Eff (FileWatcher : es) a -> Eff es a
runFileWatcherScripted paths = reinterpret (evalState paths) \env -> \case
    WatchFilePaths _ callback ->
        localSeqUnlift env \unlift -> do
            paths' <- get
            put []
            for_ paths' (unlift . callback)
            atomically retry


-- Helpers

-- | Remove dirs that are proper subdirectories of another dir in the list.
deduplicateDirs :: [FilePath] -> [FilePath]
deduplicateDirs dirs = filter notRedundant (nub dirs)
  where
    notRedundant d = not $ any (\d' -> d' /= d && isStrictAncestor d' d) dirs


-- | @isStrictAncestor parent child@ is true iff @parent@ is a proper ancestor
-- of @child@ in the filesystem hierarchy.
isStrictAncestor :: FilePath -> FilePath -> Bool
isStrictAncestor parent child = (parent <> "/") `isPrefixOf` child


-- | Check whether a file path matches at least one 'Watch' entry.
matchesAny :: [Watch] -> FilePath -> Bool
matchesAny watches path = any matches watches
  where
    matches (Watch d predicate) = (d == path || isStrictAncestor d path) && predicate path
