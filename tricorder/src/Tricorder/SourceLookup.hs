module Tricorder.SourceLookup
    ( -- * Types
      ModuleName
    , PackageId
    , SourceQuery (..)
    , ModuleSourceResult (..)
    , ReExport (..)

      -- * Lookup
    , lookupModuleSource

      -- * HTML extraction
    , extractSource
    , extractFunctionSource
    , extractReExports
    , stripAnnotations
    , stripTags
    , unescapeEntities
    ) where

import Atelier.Effects.Cache (Cache, cacheInsert, cacheLookup)
import Atelier.Effects.FileSystem (FileSystem, doesFileExist, readFileLbs)
import Atelier.Effects.Log (Log)
import Data.Aeson (FromJSON, ToJSON)
import Data.List (findIndex)
import System.FilePath ((</>))

import Atelier.Effects.Log qualified as Log
import Data.ByteString.Lazy qualified as BSL
import Data.Text qualified as T

import Tricorder.Effects.GhcPkg (GhcPkg)
import Tricorder.GhcPkg.Types (ModuleName (..), PackageId (..), SourceQuery (..))

import Tricorder.Effects.GhcPkg qualified as GhcPkg


-- | A re-exported name or module from a module's export list.
data ReExport
    = -- | Whole-module re-export: @module GHC.Enum@
      ReExportModule Text
    | -- | Single name re-export: (name, source-module)
      ReExportName Text Text
    deriving stock (Eq, Generic, Show)
    deriving anyclass (FromJSON, ToJSON)


-- | The result of a source lookup for a single module.
data ModuleSourceResult
    = -- | Source was found; contains the stripped Haskell source text and re-exports.
      SourceFound SourceQuery Text [ReExport]
    | -- | The module is not provided by any installed package.
      SourceNotFound SourceQuery
    | -- | The package was found but has no haddock-html field (built without docs).
      SourceNoHaddock SourceQuery PackageId
    | -- | The module was found but the requested function was not in the source.
      FunctionNotFound SourceQuery
    deriving stock (Eq, Generic, Show)
    deriving anyclass (FromJSON, ToJSON)


-- ── Lookup logic ───────────────────────────────────────────────────────────

-- | Resolve and return the source for a single module.
--
-- Checks both cache levels before issuing any shell-outs.
lookupModuleSource
    :: ( Cache (PackageId, SourceQuery) (Text, [ReExport]) :> es
       , Cache ModuleName PackageId :> es
       , FileSystem :> es
       , GhcPkg :> es
       , Log :> es
       )
    => SourceQuery
    -> Eff es ModuleSourceResult
lookupModuleSource query = do
    mCachedPkg <- cacheLookup @ModuleName @PackageId query.moduleName
    pkgId <- case mCachedPkg of
        Just p -> do
            Log.debug $ "Source: " <> unModuleName query.moduleName <> " → " <> unPackageId p <> " (cached)"
            pure (Just p)
        Nothing -> do
            result <- GhcPkg.findModule query.moduleName
            Log.debug $ "Source: find-module " <> unModuleName query.moduleName <> " → " <> show result
            case result of
                Nothing -> pure Nothing
                Just p -> do
                    cacheInsert @ModuleName @PackageId query.moduleName p
                    pure (Just p)
    case pkgId of
        Nothing -> pure (SourceNotFound query)
        Just p -> do
            mCachedSrc <- cacheLookup @(PackageId, SourceQuery) @(Text, [ReExport]) (p, query)
            case mCachedSrc of
                Just (src, reExports) -> do
                    Log.debug $ "Source: " <> unModuleName query.moduleName <> " source hit (cached)"
                    pure (SourceFound query src reExports)
                Nothing -> do
                    mHtmlRoot <- GhcPkg.getHaddockHtml p
                    Log.debug $ "Source: haddock-html for " <> unPackageId p <> " → " <> show mHtmlRoot
                    case mHtmlRoot of
                        Nothing -> pure (SourceNoHaddock query p)
                        Just htmlRoot -> do
                            -- Haddock generates hyperlinked source in one of two layouts:
                            --   dotted:  src/Data.Map.Strict.html   (newer Haddock / haskell.nix)
                            --   slashed: src/Data/Map/Strict.html   (older Haddock / cabal local)
                            let htmlPathDotted = htmlRoot </> "src" </> toString (unModuleName query.moduleName) <> ".html"
                                htmlPathSlashed = htmlRoot </> "src" </> toString (T.map dotToSlash (unModuleName query.moduleName)) <> ".html"
                            Log.debug $ "Source: reading " <> toText htmlPathDotted
                            mHtml <-
                                readHaddockHtml htmlPathDotted >>= \case
                                    Just html -> pure (Just html)
                                    Nothing -> readHaddockHtml htmlPathSlashed
                            case mHtml of
                                Nothing -> do
                                    Log.debug $ "Source: file not found: " <> toText htmlPathDotted
                                    pure (SourceNoHaddock query p)
                                Just html -> do
                                    let reExports = extractReExports query.moduleName html
                                    case query.function of
                                        Nothing -> do
                                            let src = extractSource html
                                            cacheInsert @(PackageId, SourceQuery) @(Text, [ReExport]) (p, query) (src, reExports)
                                            pure (SourceFound query src reExports)
                                        Just fn ->
                                            case extractFunctionSource fn html of
                                                Just src -> do
                                                    cacheInsert @(PackageId, SourceQuery) @(Text, [ReExport]) (p, query) (src, reExports)
                                                    pure (SourceFound query src reExports)
                                                Nothing ->
                                                    pure (FunctionNotFound query)
  where
    dotToSlash '.' = '/'
    dotToSlash c = c


-- ── HTML extraction ────────────────────────────────────────────────────────

-- | Read the raw Haddock hyperlinked-source HTML file.
readHaddockHtml :: (FileSystem :> es) => FilePath -> Eff es (Maybe Text)
readHaddockHtml htmlPath = do
    exists <- doesFileExist htmlPath
    if not exists then
        pure Nothing
    else
        Just . decodeUtf8 . BSL.toStrict <$> readFileLbs htmlPath


-- | Extract the raw Haskell source from Haddock hyperlinked-source HTML.
-- Line spans are split and their numeric prefixes stripped before annotation
-- removal so that 'stripAnnotations' sees well-formed per-line chunks.
extractSource :: Text -> Text
extractSource html =
    let (_, after) = T.breakOn "<pre" html
    in  if T.null after then
            unescapeEntities (stripTags (stripAnnotations html))
        else
            let afterOpen = T.drop 1 $ T.dropWhile (/= '>') after
                content = fst $ T.breakOn "</pre>" afterOpen
                lineChunks = T.splitOn "<span id=\"line-" content
                -- hd is pre-span preamble (no N"> prefix); only tail chunks need stripping.
                stripped = case lineChunks of
                    [] -> ""
                    (hd : tl) -> T.concat (hd : map stripLineNumPrefix tl)
            in  unescapeEntities (stripTags (stripAnnotations stripped))


-- | Strip the @N"\>@ prefix from a chunk produced by splitting on @\<span id=\"line-@.
stripLineNumPrefix :: Text -> Text
stripLineNumPrefix chunk = T.drop 1 $ T.dropWhile (/= '>') chunk


-- | Extract the source of a single top-level binding from Haddock source HTML.
-- Finds the span with id matching the function name, then expands to the
-- surrounding blank-line-delimited block (type sig + docstring above, body below).
extractFunctionSource :: Text -> Text -> Maybe Text
extractFunctionSource funcName html =
    let (_, after) = T.breakOn "<pre" html
        afterOpen = T.drop 1 $ T.dropWhile (/= '>') after
        content = fst $ T.breakOn "</pre>" afterOpen
        lineChunks = T.splitOn "<span id=\"line-" content
        target = "id=\"" <> funcName <> "\""
    in  case findIndex (T.isInfixOf target) lineChunks of
            Nothing -> Nothing
            Just i ->
                let (pre, rest) = splitAt i lineChunks
                in  case rest of
                        [] -> Nothing
                        (defLine : post) ->
                            let before = reverse $ takeWhile (not . isBlankChunk) $ reverse pre
                                after' = takeWhile (not . isBlankChunk) post
                                selected = before <> [defLine] <> after'
                            in  Just $ unescapeEntities $ stripTags $ stripAnnotations $ T.concat (map stripLineNumPrefix selected)
  where
    isBlankChunk chunk =
        T.null (T.strip (stripTags (stripLineNumPrefix chunk)))


-- | Extract re-exported names\/modules from Haddock source HTML.
extractReExports :: ModuleName -> Text -> [ReExport]
extractReExports modName html =
    let afterMod = snd $ T.breakOn "<span class=\"hs-keyword\">module</span>" html
        exportRgn = fst $ T.breakOn "<span class=\"hs-keyword\">where</span>" afterMod
    in  go exportRgn
  where
    modFile = unModuleName modName <> ".html"

    go :: Text -> [ReExport]
    go region
        | T.null region = []
        | otherwise =
            let (before, rest) = T.breakOn "<a href=\"" region
            in  if T.null rest then
                    []
                else
                    let afterHref = T.drop (T.length "<a href=\"") rest
                        (href, rest2) = T.breakOn "\"" afterHref
                        afterClose = T.drop 1 rest2
                        isModRe = T.isInfixOf "<span class=\"hs-keyword\">module</span>" before
                        (_, rest3) = T.breakOn ">" afterClose
                        innerHtml = fst $ T.breakOn "</a>" (T.drop 1 rest3)
                        name = T.strip $ stripTags innerHtml
                        entry
                            | T.null name = Nothing
                            | isLocal href = Nothing
                            | isModRe = Just (ReExportModule name)
                            | otherwise = Just (reExportName href name)
                        rest' = T.drop (T.length "</a>") $ snd $ T.breakOn "</a>" rest
                    in  maybeToList entry <> go rest'

    isLocal :: Text -> Bool
    isLocal href =
        let modPart = T.dropEnd 5 modFile
            sf = T.map (\c -> if c == '.' then '/' else c) modPart <> ".html"
            hrefBase = fst $ T.breakOn "#" href -- strip fragment before comparing
        in  modFile `T.isSuffixOf` hrefBase || sf `T.isSuffixOf` hrefBase

    reExportName :: Text -> Text -> ReExport
    reExportName href name = ReExportName name (deriveModuleName href)
      where
        deriveModuleName h =
            let allParts = T.splitOn "/" h
                fileName = fromMaybe h $ viaNonEmpty last $ filter (not . T.null) allParts
                fileOnly = fst $ T.breakOn "#" fileName
                dotted' = fst $ T.breakOn ".html" fileOnly
            in  if T.isInfixOf "." dotted' then
                    dotted'
                else
                    let revParts = reverse allParts
                        modDirs = takeWhile isModComponent (drop 1 revParts)
                        prefix = T.intercalate "." (reverse modDirs)
                    in  if T.null prefix then dotted' else prefix <> "." <> dotted'

        isModComponent t =
            not (T.null t) && not (T.isPrefixOf "." t) && isUpper (T.head t)
          where
            isUpper c = c >= 'A' && c <= 'Z'


-- | Remove @\<span class=\"annottext\"\>...\<\/span\>@ blocks including their content.
-- Haddock embeds elaborated GHC types as hover tooltips; they must be excised
-- before 'stripTags' so they don't pollute the plain-text source output.
stripAnnotations :: Text -> Text
stripAnnotations t
    | T.null t = t
    | otherwise =
        let marker = "<span class=\"annottext\">"
            (before, rest) = T.breakOn marker t
        in  if T.null rest then
                before
            else
                let afterOpen = T.drop (T.length marker) rest
                    afterClose = T.drop (T.length "</span>") $ snd $ T.breakOn "</span>" afterOpen
                in  before <> stripAnnotations afterClose


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
