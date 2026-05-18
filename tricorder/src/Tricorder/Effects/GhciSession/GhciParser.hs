module Tricorder.Effects.GhciSession.GhciParser
    ( GhciLoad (..)
    , GhciLoading (..)
    , GhciMessage (..)
    , GhciSeverity (..)
    , LoadResult (..)
    , collectResultCustom
    , parseReload
    , parseShowModules
    , stripAnsi
    , extractTitle
    , toRelative
    ) where

import Data.Char (isAlpha, isDigit, isSpace, toLower)
import System.FilePath (isAbsolute, makeRelative, splitDirectories, (</>))

import Data.List qualified as List
import Data.Set qualified as Set
import Data.Text qualified as T

import Tricorder.BuildState (Diagnostic, Severity (..))

import Tricorder.BuildState qualified as BuildState


-- | Severity of a GHCi diagnostic message.
data GhciSeverity = GWarning | GError
    deriving stock (Eq, Ord, Show)


-- | Payload for a @[N of M] Compiling Mod ( file, ... )@ line.
data GhciLoading = GhciLoading
    { index :: Int
    -- ^ N (this module's index in the compilation sequence)
    , total :: Int
    -- ^ M (total modules to compile)
    , moduleName :: Text
    , sourceFile :: FilePath
    }
    deriving stock (Eq, Show)


-- | Payload for a compiler diagnostic (error or warning).
data GhciMessage = GhciMessage
    { severity :: GhciSeverity
    , file :: FilePath
    , startPos :: (Int, Int)
    -- ^ (line, col), 1-based; (0,0) when unavailable
    , endPos :: (Int, Int)
    -- ^ equals startPos when no span
    , messageLines :: [Text]
    -- ^ raw lines (with any ANSI), header first
    }
    deriving stock (Eq, Show)


-- | A structured item from GHCi's reload output.
data GhciLoad
    = GLoading GhciLoading
    | GMessage GhciMessage
    | GLoadConfig FilePath
    deriving stock (Eq, Show)


-- | The result of a GHCi load or reload operation.
data LoadResult = LoadResult
    { moduleCount :: Int
    , compiledFiles :: Set FilePath
    -- ^ Files compiled in this cycle (derived from 'GLoading' items).
    -- Used by the session layer to decide which files' previous diagnostics to replace vs. retain.
    , diagnostics :: [Diagnostic]
    }
    deriving stock (Eq, Show)


-- | Make an absolute path relative to the given base directory, prefixed with @"./"@.
-- Paths already relative, or absolute paths outside @base@, are returned unchanged.
toRelative :: FilePath -> FilePath -> FilePath
toRelative base path
    | not (isAbsolute path) = path
    | otherwise = case splitDirectories (makeRelative base path) of
        (".." : _) -> path
        rel -> "." </> List.foldr1 (</>) rel


-- | Strip ANSI escape sequences of the form @ESC [ \<params\> \<letter\>@.
stripAnsi :: Text -> Text
stripAnsi t = case T.uncons t of
    Nothing -> t
    Just ('\ESC', rest) -> case T.uncons rest of
        Just ('[', rest') ->
            let afterParams = T.dropWhile (not . isAlpha) rest'
            in  stripAnsi (T.drop 1 afterParams)
        _ -> T.cons '\ESC' (stripAnsi rest)
    Just (c, rest) -> T.cons c (stripAnsi rest)


-- | Check if a line is a continuation of a diagnostic message body.
-- Applied to the raw (unstripped) line.
isMessageBody :: Text -> Bool
isMessageBody line =
    " " `T.isPrefixOf` line
        || "\t" `T.isPrefixOf` line
        || case T.break (== '|') line of
            (prefix, rest)
                | not (T.null rest) ->
                    T.all (\c -> isSpace c || isDigit c) prefix
            _ -> False


-- | Parse the output of @:reload@ from GHCi into structured items.
-- ANSI codes are stripped for pattern matching; original lines are stored in 'glMessage'.
parseReload :: [Text] -> [GhciLoad]
parseReload = go
  where
    go [] = []
    go (line : rest) =
        let stripped = stripAnsi line
        in  if
                -- Pattern 3: GHCi config loaded
                | "Loaded GHCi configuration from " `T.isPrefixOf` stripped ->
                    let file = toString $ T.drop (T.length "Loaded GHCi configuration from ") stripped
                    in  GLoadConfig file : go rest
                -- Pattern 1: Loading line
                | "[" `T.isPrefixOf` stripped ->
                    case parseLoading stripped of
                        Just item -> item : go rest
                        Nothing -> go rest
                -- Pattern 4: Summary lines (Ok/Failed)
                | "Ok, " `T.isPrefixOf` stripped
                    || "Failed, " `T.isPrefixOf` stripped ->
                    go rest
                -- Pattern 2a: <no location info>: error:
                | "<no location info>: error:" `T.isPrefixOf` stripped ->
                    let (body, remaining) = span isMessageBody rest
                    in  GMessage GhciMessage {severity = GError, file = "<no location info>", startPos = (0, 0), endPos = (0, 0), messageLines = line : body}
                            : go remaining
                -- Pattern 2b: Diagnostic message (file:pos:severity)
                | not (T.null stripped)
                , not (" " `T.isPrefixOf` stripped)
                , not ("\t" `T.isPrefixOf` stripped) ->
                    case parseDiagnostic stripped line rest of
                        Just (item, remaining) -> item : go remaining
                        Nothing -> go rest
                -- Everything else: discard
                | otherwise -> go rest

    -- Parse a "[N of M] Compiling ..." loading line.
    parseLoading :: Text -> Maybe GhciLoad
    parseLoading stripped = do
        insideAndAfter <- T.stripPrefix "[" stripped
        let (inside, after) = T.break (== ']') insideAndAfter
        guard (not (T.null after))
        let afterBracket = T.drop 1 after -- drop the ']'
        case T.words inside of
            [nTxt, "of", mTxt] -> do
                n <- readMaybe @Int (toString nTxt)
                m <- readMaybe @Int (toString mTxt)
                let trimmed = T.stripStart afterBracket
                guard ("Compiling" `T.isPrefixOf` trimmed)
                let afterCompiling = T.drop (T.length "Compiling ") trimmed
                let modName = T.takeWhile (not . isSpace) afterCompiling
                guard (not (T.null modName))
                let afterMod = T.dropWhile (/= '(') afterCompiling
                guard (not (T.null afterMod))
                let insideParen = T.drop 1 afterMod -- drop '('
                let filePath = T.takeWhile (\c -> c /= ',' && c /= ')') insideParen
                guard (not (T.null filePath))
                let fileTrimmed = toString (T.stripStart filePath)
                pure (GLoading GhciLoading {index = n, total = m, moduleName = modName, sourceFile = fileTrimmed})
            _ -> Nothing

    -- Parse a diagnostic message line (file:pos:severity:).
    -- Returns the parsed item and the remaining lines (after consuming continuation lines).
    parseDiagnostic :: Text -> Text -> [Text] -> Maybe (GhciLoad, [Text])
    parseDiagnostic stripped originalLine rest = do
        (file, afterFile) <- breakFileColon stripped
        ((pos1, pos2), afterPos) <- parsePosition afterFile
        let lower = T.toLower (T.stripStart afterPos)
        sev <-
            if "warning:" `T.isPrefixOf` lower then
                Just GWarning
            else
                if "error:" `T.isPrefixOf` lower then
                    Just GError
                else
                    Nothing
        let (body, remaining) = span isMessageBody rest
        pure (GMessage GhciMessage {severity = sev, file = toString file, startPos = pos1, endPos = pos2, messageLines = originalLine : body}, remaining)


-- | Parse a file path followed by a colon.
-- Handles Windows drive letters (e.g., @C:\\path\\file.hs:@).
breakFileColon :: Text -> Maybe (Text, Text)
breakFileColon s = case T.break (== ':') s of
    (_, t) | T.null t -> Nothing
    (a, colonAndB) ->
        let b = T.drop 1 colonAndB
        in  if T.length a == 1 && isAlpha (T.head a) then
                -- Windows drive letter: consume one more ':'-delimited segment
                case T.break (== ':') b of
                    (_, t) | T.null t -> Nothing
                    (pathRest, colonAndRest) ->
                        Just (a <> ":" <> pathRest, T.drop 1 colonAndRest)
            else
                Just (a, b)


-- | Parse a position in one of the GHCi formats:
--   @L:C:@, @L:C-C2:@, or @(L1,C1)-(L2,C2):@
parsePosition :: Text -> Maybe (((Int, Int), (Int, Int)), Text)
parsePosition s
    -- (L1,C1)-(L2,C2):
    | "(" `T.isPrefixOf` s = do
        let s1 = T.drop 1 s
        (l1, s2) <- readInt s1
        s3 <- T.stripPrefix "," s2
        (c1, s4) <- readInt s3
        s5 <- T.stripPrefix ")-((" s4 <|> T.stripPrefix ")-(" s4
        (l2, s6) <- readInt s5
        s7 <- T.stripPrefix "," s6
        (c2, s8) <- readInt s7
        s9 <- T.stripPrefix "):" s8
        pure (((l1, c1), (l2, c2)), s9)
    -- L:C: or L:C-C2:
    | otherwise = do
        (l, s1) <- readInt s
        s2 <- T.stripPrefix ":" s1
        (c, s3) <- readInt s2
        case T.uncons s3 of
            Just (':', rest) -> pure (((l, c), (l, c)), rest)
            Just ('-', s4) -> do
                (c2, s5) <- readInt s4
                s6 <- T.stripPrefix ":" s5
                pure (((l, c), (l, c2)), s6)
            _ -> Nothing
  where
    readInt :: Text -> Maybe (Int, Text)
    readInt t =
        let (digits, rest) = T.span isDigit t
        in  if T.null digits then
                Nothing
            else
                readMaybe (toString digits) <&> (,rest)


-- | Assemble a 'LoadResult' from a project root, parsed reload items, and
-- the @:show modules@ output.
collectResultCustom :: FilePath -> [GhciLoad] -> [(Text, FilePath)] -> LoadResult
collectResultCustom projectRoot loads modules =
    let rel = toRelative projectRoot
        compiledFiles = case [l.sourceFile | GLoading l <- loads] of
            [] -> Set.fromList (map (rel . snd) modules)
            fs -> Set.fromList (map rel fs)
    in  LoadResult
            { moduleCount = length modules
            , compiledFiles
            , diagnostics = toDiagnostics rel loads
            }


toDiagnostics :: (FilePath -> FilePath) -> [GhciLoad] -> [BuildState.Diagnostic]
toDiagnostics rel loads = mapMaybe toMsg loads
  where
    toMsg (GMessage m) | '<' : _ <- m.file = Nothing
    toMsg (GMessage m) =
        let (l, c) = m.startPos
            (el, ec) = m.endPos
        in  Just
                BuildState.Diagnostic
                    { severity = case m.severity of
                        GWarning -> SWarning
                        GError -> SError
                    , file = rel m.file
                    , line = l
                    , col = c
                    , endLine = el
                    , endCol = ec
                    , title = extractTitle (map toString m.messageLines)
                    , text = unlines (map toText m.messageLines)
                    }
    toMsg _ = Nothing


-- | Parse the output of @:show modules@ into (module name, file path) pairs.
parseShowModules :: [Text] -> [(Text, FilePath)]
parseShowModules = mapMaybe parseLine
  where
    parseLine line =
        let stripped = stripAnsi line
        in  case T.breakOn "( " stripped of
                (_, rest) | T.null rest -> Nothing
                (left, right) ->
                    let modName = T.takeWhile (not . isSpace) (T.stripStart left)
                        afterParen = T.drop 2 right -- drop "( "
                        filePath = T.takeWhile (/= ',') afterParen
                        fileTrimmed = toString (T.stripStart filePath)
                    in  if T.null modName || null fileTrimmed then
                            Nothing
                        else
                            Just (modName, fileTrimmed)


-- | Extract a short human-readable title from ghcid's @loadMessage@.
--
-- ghcid always places the GHCi header line (@"file:line:col: severity: rest"@) as
-- the first element of @loadMessage@.  The human-readable text is either:
--
--   * Inline, after @"error:"@ \/ @"warning:"@ in the header (old GHC style), or
--   * On subsequent indented lines (new GHC style, when header ends with a
--     diagnostic code such as @[GHC-83865]@ or @[-Wmissing-deriving-strategies]@).
--
-- Source-display lines (@"39 | ..."@, @"   | ^^^^"@) are skipped when
-- scanning body lines for content.
extractTitle :: [String] -> Text
extractTitle [] = ""
extractTitle (header : body) =
    fromMaybe (firstBodyLine body) (inlineFromHeader (toString (stripAnsi (toText header))))
  where
    -- Try to extract inline message content from the header.
    -- Returns Nothing when the content after the severity keyword is empty
    -- or consists only of diagnostic codes like "[GHC-83865]" or "[-Wfoo]".
    inlineFromHeader :: String -> Maybe Text
    inlineFromHeader h =
        let lower = map toLower h
        in  case headerAfter "error:" lower h <|> headerAfter "warning:" lower h of
                Nothing -> Nothing
                Just rest ->
                    let content = stripDiagCodes (dropWhile isSpace rest)
                    in  if null content then Nothing else Just (toText content)

    -- Return the suffix of 'original' starting just after 'needle',
    -- where 'needle' is located by searching 'haystack' (same-length strings).
    headerAfter :: String -> String -> String -> Maybe String
    headerAfter needle haystack original =
        fmap (\i -> drop (i + length needle) original)
            $ List.findIndex (needle `List.isPrefixOf`) (List.tails haystack)

    -- Strip leading @[...]@ diagnostic code blocks (e.g. "[GHC-83865]", "[-Wfoo]").
    stripDiagCodes :: String -> String
    stripDiagCodes s = case dropWhile isSpace s of
        '[' : rest ->
            let after = dropWhile isSpace (drop 1 (dropWhile (/= ']') rest))
            in  stripDiagCodes after
        other -> other

    -- Find the first body line that is not a source-display line.
    firstBodyLine :: [String] -> Text
    firstBodyLine xs =
        case [ t
             | x <- xs
             , let t = dropWhile isSpace (toString (stripAnsi (toText x)))
             , not (null t)
             , not (isSourceLine t)
             ] of
            (t : _) -> toText t
            [] -> ""

    -- Source-display lines have the form @"   | ..."@ or @"42 | ..."@,
    -- or are caret/tilde underlines (@"   ^^^^"@).
    isSourceLine :: String -> Bool
    isSourceLine s = case dropWhile (\c -> isDigit c || c == ' ') s of
        ('|' : _) -> True
        _ -> not (null s) && all (\c -> c `elem` ("^~_ " :: String)) s
