-- Pretty instances for domain types live here rather than in BuildState because
-- they depend on Style (a display concern). The orphan warning is intentional.
{-# OPTIONS_GHC -Wno-orphans #-}

module Ghcib.Render
    ( -- * Severity
      severityStyle

      -- * Document builders
    , buildStateDoc
    , diagnosticDoc
    , daemonInfoDoc
    , durationDoc

      -- * Plain-text formatting
    , diagnosticLine
    , diagnosticBlock
    , formatDuration
    , renderSourceResults
    ) where

import Data.Time (UTCTime)
import Data.Time.Format (defaultTimeLocale, formatTime)
import Data.Time.LocalTime (TimeZone, utc, utcToLocalTime)
import Effectful.Console.ByteString (Console)
import Prettyprinter
import System.FilePath (isAbsolute)

import Effectful.Console.ByteString qualified as Console

import Ghcib.BuildState
    ( BuildPhase (..)
    , BuildResult (..)
    , BuildState (..)
    , DaemonInfo (..)
    , Diagnostic (..)
    , Severity (..)
    )
import Ghcib.Effects.Display (Style (..))
import Ghcib.GhcPkg.Types (ModuleName (..), PackageId (..))
import Ghcib.SourceLookup (ModuleSourceResult (..))


-- | Map a 'Severity' to its display 'Style'.
severityStyle :: Severity -> Style
severityStyle SError = Err
severityStyle SWarning = Warn


buildStateDoc :: TimeZone -> BuildState -> Doc Style
buildStateDoc tz bs =
    statusDoc
        <> hardline
        <> hardline
        <> daemonInfoDoc bs.daemonInfo
  where
    statusDoc = case bs.phase of
        Building ->
            annotate Warn "Building..."
        Done result
            | null result.diagnostics ->
                annotate Ok "All good."
                    <+> buildSummaryDoc result.moduleCount result.durationMs
                    <+> timestampDoc tz result.completedAt
        Done result ->
            let msgs = result.diagnostics
                errCount = length $ filter (\m -> m.severity == SError) msgs
                warnCount = length $ filter (\m -> m.severity == SWarning) msgs
                header =
                    if errCount > 0 then
                        annotate Err (pretty errCount <> " error(s), " <> pretty warnCount <> " warning(s)")
                    else
                        annotate Warn (pretty warnCount <> " warning(s)")
            in  header
                    <+> durationDoc result.durationMs
                    <+> timestampDoc tz result.completedAt
                    <> hardline
                    <> hardline
                    <> vsep (map diagnosticDoc msgs)


buildSummaryDoc :: Int -> Int -> Doc ann
buildSummaryDoc mods ms = "(" <> pretty mods <+> "modules," <+> pretty (formatDuration ms) <> ")"


durationDoc :: Int -> Doc ann
durationDoc ms = "(" <> pretty (formatDuration ms) <> ")"


timestampDoc :: TimeZone -> UTCTime -> Doc ann
timestampDoc tz t = pretty ("— " <> formatTime defaultTimeLocale "%H:%M:%S" (utcToLocalTime tz t))


formatDuration :: Int -> String
formatDuration ms =
    if ms < 1000 then
        show ms <> "ms"
    else
        show (ms `div` 1000) <> "." <> show ((ms `mod` 1000) `div` 100) <> "s"


watchDirDoc :: FilePath -> Doc ann
watchDirDoc dir = "  -" <+> pretty displayDir
  where
    displayDir
        | isAbsolute dir = dir
        | dir == "." = "./"
        | otherwise = "./" <> dir


diagnosticDoc :: Diagnostic -> Doc Style
diagnosticDoc m =
    severityLabel <+> pretty loc <> hardline <> pretty (toString m.text) <> hardline
  where
    loc = m.file <> ":" <> show m.line <> ":" <> show m.col
    severityLabel = annotate (severityStyle m.severity) $ case m.severity of
        SError -> "error:"
        SWarning -> "warning:"


daemonInfoDoc :: DaemonInfo -> Doc Style
daemonInfoDoc di =
    annotate Emphasis "Targets:"
        <+> targetsDoc
        <> hardline
        <> annotate Emphasis "Watching:"
        <> hardline
        <> vsep (map watchDirDoc di.watchDirs)
        <> hardline
        <> annotate Emphasis "Socket:"
        <+> pretty di.sockPath
        <> foldMap (\p -> hardline <> annotate Emphasis "Log:" <+> pretty p) di.logFile
  where
    targetsDoc =
        if null di.targets then
            "(all)"
        else
            pretty (intercalate " " (map toString di.targets))


-- | Single-line diagnostic for plain-text / shell output.
--
-- Format: @E src\/Foo\/Bar.hs:42 \`something\` not in scope@
diagnosticLine :: Diagnostic -> String
diagnosticLine d =
    prefix d.severity <> " " <> d.file <> ":" <> show d.line <> " " <> toString d.title
  where
    prefix SError = "E"
    prefix SWarning = "W"


-- | One-liner followed by the full GHC message body (verbose mode).
diagnosticBlock :: Diagnostic -> String
diagnosticBlock d = diagnosticLine d <> "\n" <> toString d.text


instance Pretty Diagnostic where
    pretty m = unAnnotate (diagnosticDoc m)


instance Pretty DaemonInfo where
    pretty di = unAnnotate (daemonInfoDoc di)


instance Pretty BuildState where
    pretty bs = unAnnotate (buildStateDoc utc bs)


renderSourceResults :: (Console :> es) => [ModuleSourceResult] -> Eff es ()
renderSourceResults results = mapM_ renderOne results
  where
    renderOne (SourceFound modName src) = do
        when (length results > 1) $ Console.putStrLn (encodeUtf8 $ "-- " <> unModuleName modName)
        Console.putStr (encodeUtf8 src)
        when (length results > 1) $ Console.putStrLn ""
    renderOne (SourceNotFound modName) =
        Console.putStrLn
            $ encodeUtf8
            $ "Not found: " <> unModuleName modName <> " (module not in any installed package)"
    renderOne (SourceNoHaddock modName pkgId) =
        Console.putStrLn
            $ encodeUtf8
            $ "No source available: "
                <> unModuleName modName
                <> " (package "
                <> unPackageId pkgId
                <> " was built without documentation; try `cabal get "
                <> unPackageId pkgId
                <> "`)"
