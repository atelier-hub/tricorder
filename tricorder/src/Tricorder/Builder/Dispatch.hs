module Tricorder.Builder.Dispatch
    ( DiagnosticMap
    , KnownTargetNames (..)
    , fileMatchesAnyTarget
    , filterToWatchDirs
    , mergeDiagnostics
    , resolveKnownTargets
    ) where

import System.FilePath (isAbsolute, (</>))

import Data.Map.Strict qualified as Map
import Data.Set qualified as Set

import Tricorder.BuildState (Diagnostic (..))
import Tricorder.Effects.GhciSession (LoadResult (..), LoadedModule (..))
import Tricorder.Effects.GhciSession.GhciParser (pathSuffixesAsModuleName)


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


-- | Path↔module-name map for the next cycle: this round's @:show modules@
-- plus carryover from @prev@ for targets that failed mid-session and so
-- dropped out. Never-compiled targets are absent here (no path↔name
-- mapping); the dispatcher recognises those via 'KnownTargetNames'.
resolveKnownTargets
    :: Map FilePath LoadedModule
    -- ^ Previous known-targets map (carryover source).
    -> LoadResult
    -> Map FilePath LoadedModule
resolveKnownTargets prev lr =
    let primary = lr.loadedModules
        primaryNames = Set.fromList [lm.moduleName | lm <- Map.elems primary]
        prevByName = Map.fromList [(lm.moduleName, (path, lm)) | (path, lm) <- Map.toList prev]
        carryover =
            Map.fromList
                [ (path, lm)
                | name <- lr.targetNames
                , not (Set.member name primaryNames)
                , Just (path, lm) <- [Map.lookup name prevByName]
                ]
    in  Map.union primary carryover


-- | GHCi's current target set, as raw entries from @:show targets@
-- (typically dotted module names under @cabal repl --enable-multi-repl@).
-- Survives every compile failure mode, so the dispatcher can recognise a
-- target even when it's absent from the path-keyed module map.
newtype KnownTargetNames = KnownTargetNames {unKnownTargetNames :: Set Text}
    deriving stock (Eq, Show)


-- | Whether a file path corresponds to one of GHCi's targets.
fileMatchesAnyTarget :: KnownTargetNames -> FilePath -> Bool
fileMatchesAnyTarget (KnownTargetNames targets) fp =
    any (`Set.member` targets) (pathSuffixesAsModuleName fp)


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
