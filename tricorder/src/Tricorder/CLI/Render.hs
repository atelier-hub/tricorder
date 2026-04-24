module Tricorder.CLI.Render
    ( -- * Plain-text formatting
      diagnosticLine
    , diagnosticLineIndexed
    , diagnosticBlock
    , formatDuration
    , renderSourceResults
    ) where

import Atelier.Effects.Console (Console)
import Tricorder.BuildState
    ( Diagnostic (..)
    , Severity (..)
    )
import Tricorder.GhcPkg.Types (ModuleName (..), PackageId (..))
import Tricorder.SourceLookup (ModuleSourceResult (..))

import Atelier.Effects.Console qualified as Console


formatDuration :: Int -> Text
formatDuration ms =
    if ms < 1000 then
        show ms <> "ms"
    else
        show (ms `div` 1000) <> "." <> show ((ms `mod` 1000) `div` 100) <> "s"


-- | Single-line diagnostic for plain-text / shell output.
--
-- Format: @E src\/Foo\/Bar.hs:42 \`something\` not in scope@
diagnosticLine :: Diagnostic -> Text
diagnosticLine d =
    prefix d.severity <> " " <> toText d.file <> ":" <> show d.line <> " " <> d.title
  where
    prefix SError = "E"
    prefix SWarning = "W"


-- | Like 'diagnosticLine' but prefixed with a 1-based index.
--
-- Format: @[N] E src\/Foo\/Bar.hs:42 \`something\` not in scope@
diagnosticLineIndexed :: Int -> Diagnostic -> Text
diagnosticLineIndexed n d = "[" <> show n <> "] " <> diagnosticLine d


-- | One-liner followed by the full GHC message body (verbose mode).
diagnosticBlock :: Diagnostic -> Text
diagnosticBlock d = diagnosticLine d <> "\n" <> d.text


renderSourceResults :: (Console :> es) => [ModuleSourceResult] -> Eff es ()
renderSourceResults results = mapM_ renderOne results
  where
    renderOne (SourceFound modName src) = do
        when (length results > 1) $ Console.putTextLn $ "-- " <> unModuleName modName
        Console.putText src
        when (length results > 1) $ Console.putStrLn ""
    renderOne (SourceNotFound modName) =
        Console.putTextLn
            $ "Not found: " <> unModuleName modName <> " (module not in any installed package)"
    renderOne (SourceNoHaddock modName pkgId) =
        Console.putTextLn
            $ "No source available: "
                <> unModuleName modName
                <> " (package "
                <> unPackageId pkgId
                <> " was built without documentation; try `cabal get "
                <> unPackageId pkgId
                <> "`)"
