module Tricorder.Builder.Dispatch
    ( BuilderState (..)
    , DiagnosticMap
    , DispatchAction (..)
    , KnownTargetNames (..)
    , dispatch
    , emptyBuilderState
    , fileMatchesAnyTarget
    , filterToWatchDirs
    , mergeDiagnostics
    ) where

import Atelier.Effects.FileWatcher (FileEvent (..))
import Data.Default (Default (..))
import System.FilePath (isAbsolute, normalise, splitDirectories, takeExtension, (</>))

import Data.List qualified as List
import Data.Map.Strict qualified as Map
import Data.Set qualified as Set

import Tricorder.BuildState (Diagnostic (..))
import Tricorder.Effects.GhciSession (LoadResult (..), LoadedModule (..))
import Tricorder.Effects.GhciSession.GhciParser (pathSuffixesAsModuleName)


-- | The Builder's per-GHCi-session cache: what it last saw from GHCi plus its
-- accumulated diagnostics. Reset on every GHCi restart in
-- @buildWithGhciOnChange@; 'BuildId' is intentionally /not/ here because it
-- counts across restarts.
data BuilderState = BuilderState
    { loadedModules :: Map FilePath LoadedModule
    , knownTargets :: KnownTargetNames
    , diagnosticMap :: DiagnosticMap
    }
    deriving stock (Eq, Show)


instance Default BuilderState where
    def = emptyBuilderState


emptyBuilderState :: BuilderState
emptyBuilderState =
    BuilderState
        { loadedModules = mempty
        , knownTargets = KnownTargetNames mempty
        , diagnosticMap = mempty
        }


type DiagnosticMap = Map FilePath [Diagnostic]


-- | Merge a new 'LoadResult' into the accumulated per-file diagnostic map.
--
-- Files in 'compiledFiles' have their previous diagnostics cleared and replaced
-- by any new diagnostics produced for them in this cycle. Files absent from
-- 'compiledFiles' were skipped by incremental compilation and retain their
-- previous diagnostics unchanged.
mergeDiagnostics :: DiagnosticMap -> LoadResult -> DiagnosticMap
mergeDiagnostics prev LoadResult {compiledFiles, diagnostics} =
    let cleared = foldr Map.delete prev compiledFiles
        newByFile = Map.fromListWith (++) [(d.file, [d]) | d <- diagnostics]
    in  Map.union newByFile cleared


-- | GHCi's current target set, as raw entries from @:show targets@
-- (typically dotted module names under @cabal repl --enable-multi-repl@).
-- Survives every compile failure mode, so the dispatcher can recognise a
-- target even when it's absent from the path-keyed module map.
newtype KnownTargetNames = KnownTargetNames {unKnownTargetNames :: Set Text}
    deriving stock (Eq, Show)


-- | Whether a file path corresponds to one of GHCi's targets.
--
-- @:show targets@ entries are either dotted module names (e.g.
-- @Tricorder.CLI.Main@) or file paths (e.g. @app/Main.hs@). GHCi uses the path
-- form when a module name is ambiguous across home units — i.e. every
-- executable/test 'Main'. We match both forms.
--
-- The path form matters because a /failed/ executable 'Main' drops out of
-- @:show modules@ but survives in @:show targets@ as its path. Without matching
-- it, fixing the executable would dispatch a no-op 'Add' instead of a 'Reload',
-- leaving the diagnostic stale.
fileMatchesAnyTarget :: KnownTargetNames -> FilePath -> Bool
fileMatchesAnyTarget (KnownTargetNames targets) fp =
    any (`Set.member` targets) (pathSuffixesAsModuleName fp)
        || any (pathTargetMatches fp . toString) (Set.toList targets)


-- | Whether a path-shaped @:show targets@ entry refers to the given file,
-- compared on directory-segment boundaries (so @app/Main.hs@ matches
-- @./tricorder/app/Main.hs@ but @pp/Main.hs@ does not). Module-name targets
-- (no @.hs@ extension) are left to the module-name branch above.
pathTargetMatches :: FilePath -> FilePath -> Bool
pathTargetMatches file target =
    takeExtension target == ".hs"
        && splitDirectories (normalise target) `List.isSuffixOf` splitDirectories (normalise file)


-- | A GHCi command to issue in response to a source file change.
data DispatchAction
    = Reload
    | Add FilePath
    | Unadd Text
    deriving stock (Eq, Show)


-- | Decide what GHCi action a source-file change requires.
--
-- The path-keyed module map misses targets that failed on first load,
-- so we fall back to 'KnownTargetNames' for those — otherwise we would
-- issue @:add@ (a no-op for an already-tracked cabal target), leaving
-- stale diagnostics in place.
dispatch
    :: KnownTargetNames
    -> Maybe LoadedModule
    -> FilePath
    -> FileEvent
    -> Maybe DispatchAction
dispatch knownTargets known fp event = case known of
    Just lm -> Just $ case event of
        Added -> Reload
        Modified -> Reload
        Removed -> Unadd lm.moduleName
    Nothing
        | fileMatchesAnyTarget knownTargets fp -> case event of
            Added -> Just Reload
            Modified -> Just Reload
            Removed -> Nothing
        | otherwise -> case event of
            Added -> Just (Add fp)
            Modified -> Just (Add fp)
            Removed -> Nothing


-- | Keep only diagnostics whose file is under one of the watched directories.
--
-- Diagnostics from outside the project (e.g. @.h@ files in the Nix store) and
-- those with mangled filenames produced by the C preprocessor (e.g.
-- @"In file included from ..."@) are dropped here, before they can enter the
-- accumulation map where they would be impossible to evict.
filterToWatchDirs :: FilePath -> [FilePath] -> [Diagnostic] -> [Diagnostic]
filterToWatchDirs _ [] diags = diags
filterToWatchDirs projectRoot watchDirs diags =
    filter (isUnderAnyWatchDir . (.file)) diags
  where
    absWatchDirs = map toAbsWd watchDirs
    toAbsWd wd
        | wd == "." = projectRoot
        | isAbsolute wd = wd
        | otherwise = projectRoot </> wd
    isUnderAnyWatchDir file
        | not (isAbsolute file) && not ("./" `isPrefixOf` file) = False
        | isAbsolute file =
            any (\wd -> (wd ++ "/") `isPrefixOf` file || wd == file) absWatchDirs
        | otherwise =
            let absFile = projectRoot </> drop 2 file
            in  any (\wd -> (wd ++ "/") `isPrefixOf` absFile || wd == absFile) absWatchDirs
