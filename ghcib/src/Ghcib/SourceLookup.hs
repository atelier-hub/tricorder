module Ghcib.SourceLookup
    ( -- * Types
      ModuleName
    , PackageId
    , ModuleSourceResult (..)

      -- * Lookup
    , lookupModuleSource

      -- * HTML extraction
    , extractSource
    , stripTags
    , unescapeEntities
    ) where

import Data.Aeson (FromJSON, ToJSON)
import System.FilePath ((</>))

import Data.ByteString.Lazy qualified as BSL
import Data.Text qualified as T

import Atelier.Effects.Cache (Cache, cacheInsert, cacheLookup)
import Atelier.Effects.FileSystem (FileSystem, doesFileExist, readFileLbs)
import Atelier.Effects.Log (Log)
import Ghcib.Effects.GhcPkg (GhcPkg)
import Ghcib.GhcPkg.Types (ModuleName (..), PackageId (..))

import Atelier.Effects.Log qualified as Log
import Ghcib.Effects.GhcPkg qualified as GhcPkg


-- | The result of a source lookup for a single module.
data ModuleSourceResult
    = -- | Source was found; contains the stripped Haskell source text.
      SourceFound ModuleName Text
    | -- | The module is not provided by any installed package.
      SourceNotFound ModuleName
    | -- | The package was found but has no haddock-html field (built without docs).
      SourceNoHaddock ModuleName PackageId
    deriving stock (Eq, Generic, Show)
    deriving anyclass (FromJSON, ToJSON)


-- ── Lookup logic ───────────────────────────────────────────────────────────

-- | Resolve and return the source for a single module.
--
-- Checks both cache levels before issuing any shell-outs.
lookupModuleSource
    :: ( Cache (PackageId, ModuleName) Text :> es
       , Cache ModuleName PackageId :> es
       , FileSystem :> es
       , GhcPkg :> es
       , Log :> es
       )
    => ModuleName
    -> Eff es ModuleSourceResult
lookupModuleSource modName = do
    mCachedPkg <- cacheLookup @ModuleName @PackageId modName
    pkgId <- case mCachedPkg of
        Just p -> do
            Log.debug $ "Source: " <> unModuleName modName <> " → " <> unPackageId p <> " (cached)"
            pure (Just p)
        Nothing -> do
            result <- GhcPkg.findModule modName
            Log.debug $ "Source: find-module " <> unModuleName modName <> " → " <> show result
            case result of
                Nothing -> pure Nothing
                Just p -> do
                    cacheInsert @ModuleName @PackageId modName p
                    pure (Just p)
    case pkgId of
        Nothing -> pure (SourceNotFound modName)
        Just p -> do
            mCachedSrc <- cacheLookup @(PackageId, ModuleName) @Text (p, modName)
            case mCachedSrc of
                Just src -> do
                    Log.debug $ "Source: " <> unModuleName modName <> " source hit (cached)"
                    pure (SourceFound modName src)
                Nothing -> do
                    mHtmlRoot <- GhcPkg.getHaddockHtml p
                    Log.debug $ "Source: haddock-html for " <> unPackageId p <> " → " <> show mHtmlRoot
                    case mHtmlRoot of
                        Nothing -> pure (SourceNoHaddock modName p)
                        Just htmlRoot -> do
                            -- Haddock generates hyperlinked source in one of two layouts:
                            --   dotted:  src/Data.Map.Strict.html   (newer Haddock / haskell.nix)
                            --   slashed: src/Data/Map/Strict.html   (older Haddock / cabal local)
                            let htmlPathDotted = htmlRoot </> "src" </> toString (unModuleName modName) <> ".html"
                                htmlPathSlashed = htmlRoot </> "src" </> toString (T.map dotToSlash (unModuleName modName)) <> ".html"
                            Log.debug $ "Source: reading " <> toText htmlPathDotted
                            mSrc <-
                                readHaddockSource htmlPathDotted >>= \case
                                    Just src -> pure (Just src)
                                    Nothing -> readHaddockSource htmlPathSlashed
                            case mSrc of
                                Nothing -> do
                                    Log.debug $ "Source: file not found: " <> toText htmlPathDotted
                                    pure (SourceNoHaddock modName p)
                                Just src -> do
                                    cacheInsert @(PackageId, ModuleName) @Text (p, modName) src
                                    pure (SourceFound modName src)
  where
    dotToSlash '.' = '/'
    dotToSlash c = c


-- ── HTML extraction ────────────────────────────────────────────────────────

-- | Read the Haddock hyperlinked-source HTML file and strip HTML to recover source.
readHaddockSource :: (FileSystem :> es) => FilePath -> Eff es (Maybe Text)
readHaddockSource htmlPath = do
    exists <- doesFileExist htmlPath
    if not exists then
        pure Nothing
    else
        Just . extractSource . decodeUtf8 . BSL.toStrict <$> readFileLbs htmlPath


-- | Extract the raw Haskell source from Haddock hyperlinked-source HTML.
--
-- 1. Finds the @\<pre id=\"src\"\>@ element.
-- 2. Takes everything up to the matching @\<\/pre\>@.
-- 3. Strips all @\<...\>@ tags.
-- 4. Unescapes HTML entities.
extractSource :: Text -> Text
extractSource html =
    let (_, after) = T.breakOn "<pre id=\"src\"" html
    in  if T.null after then
            -- Fallback: strip the whole file (shouldn't happen for valid haddock HTML)
            unescapeEntities (stripTags html)
        else
            let
                -- Drop up to and including the closing '>' of the opening <pre ...> tag
                afterOpen = T.drop 1 $ T.dropWhile (/= '>') after
                -- Take everything up to </pre>
                content = fst $ T.breakOn "</pre>" afterOpen
            in
                unescapeEntities (stripTags content)


-- | Remove all @\<...\>@ sequences from text.
stripTags :: Text -> Text
stripTags t
    | T.null t = t
    | otherwise =
        let (before, rest) = T.breakOn "<" t
        in  if T.null rest then
                before
            else
                before <> stripTags (T.drop 1 (T.dropWhile (/= '>') rest))


-- | Unescape the HTML entities produced by Haddock.
unescapeEntities :: Text -> Text
unescapeEntities =
    T.replace "&lt;" "<"
        . T.replace "&gt;" ">"
        . T.replace "&amp;" "&"
        . T.replace "&#39;" "'"
        . T.replace "&quot;" "\""
