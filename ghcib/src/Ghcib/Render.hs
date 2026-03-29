-- Pretty instances for domain types live here rather than in BuildState because
-- they depend on Style (a display concern). The orphan warning is intentional.
{-# OPTIONS_GHC -Wno-orphans #-}

module Ghcib.Render
    ( -- * Severity
      severityStyle

      -- * Document builders
    , buildStateDoc
    , messageDoc
    , daemonInfoDoc
    , durationDoc
    ) where

import Data.Time (UTCTime)
import Data.Time.Format (defaultTimeLocale, formatTime)
import Data.Time.Units (toMicroseconds)
import Prettyprinter
import System.FilePath (isAbsolute)

import Atelier.Time (Millisecond)
import Ghcib.BuildState
    ( BuildPhase (..)
    , BuildState (..)
    , DaemonInfo (..)
    , Message (..)
    , Severity (..)
    )
import Ghcib.Effects.Display (Style (..))


-- | Map a 'Severity' to its display 'Style'.
severityStyle :: Severity -> Style
severityStyle SError = Err
severityStyle SWarning = Warn


buildStateDoc :: BuildState -> Doc Style
buildStateDoc bs =
    statusDoc
        <> hardline
        <> hardline
        <> daemonInfoDoc bs.daemonInfo
  where
    statusDoc = case bs.phase of
        Building ->
            annotate Warn "Building..."
        Done completedAt dur [] ->
            annotate Ok "All good."
                <+> durationDoc dur
                <+> timestampDoc completedAt
        Done completedAt dur msgs ->
            let errCount = length $ filter (\m -> m.severity == SError) msgs
                warnCount = length $ filter (\m -> m.severity == SWarning) msgs
                header =
                    if errCount > 0 then
                        annotate Err (pretty errCount <> " error(s), " <> pretty warnCount <> " warning(s)")
                    else
                        annotate Warn (pretty warnCount <> " warning(s)")
            in  header
                    <+> durationDoc dur
                    <+> timestampDoc completedAt
                    <> hardline
                    <> hardline
                    <> vsep (map messageDoc msgs)


durationDoc :: Millisecond -> Doc ann
durationDoc dur = "(" <> pretty (formatDuration dur) <> ")"


timestampDoc :: UTCTime -> Doc ann
timestampDoc t = pretty ("— " <> formatTime defaultTimeLocale "%H:%M:%S" t)


formatDuration :: Millisecond -> String
formatDuration dur =
    let ms = toMicroseconds dur `div` 1000
    in  if ms < 1000 then
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


messageDoc :: Message -> Doc Style
messageDoc m =
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


instance Pretty Message where
    pretty m = unAnnotate (messageDoc m)


instance Pretty DaemonInfo where
    pretty di = unAnnotate (daemonInfoDoc di)


instance Pretty BuildState where
    pretty bs = unAnnotate (buildStateDoc bs)
