module Tricorder.Effects.GhciSession
    ( -- * Effect
      GhciSession
    , Controls (..)
    , withGhci

      -- * Types
    , LoadResult (..)

      -- * Interpreters
    , runGhciSessionIO
    , runGhciSessionScripted

      -- * Parsing utilities
    , extractTitle
    ) where

import Control.Exception (throwIO)
import Data.Char (isAlpha, isDigit, isSpace, toLower)
import Effectful
    ( Effect
    , IOE
    , Limit (..)
    , Persistence (..)
    , UnliftStrategy (..)
    , withEffToIO
    )
import Effectful.Dispatch.Dynamic
    ( interpret
    , localLend
    , localSeqLift
    , localSeqUnlift
    , localUnlift
    , reinterpret
    )
import Effectful.Exception (bracket)
import Effectful.State.Static.Shared (State, evalState, state)
import Effectful.TH (makeEffect)
import Language.Haskell.Ghcid (Load (..))
import System.Directory (getCurrentDirectory)
import System.FilePath (isAbsolute, makeRelative, splitDirectories, (</>))
import System.Process (waitForProcess)

import Data.List qualified as List
import Data.Set qualified as Set
import Language.Haskell.Ghcid qualified as Ghcid

import Atelier.Effects.Log (Log)
import Atelier.Exception (trySyncIO)
import Tricorder.BuildState
    ( BuildPhase (..)
    , BuildProgress (..)
    , Diagnostic (..)
    , Severity (..)
    )
import Tricorder.Effects.BuildStore (BuildStore, getState, setPhase)
import Tricorder.Runtime (ProjectRoot (..))

import Atelier.Effects.Log qualified as Log
import Tricorder.BuildState qualified as BuildState


-- | The result of a GHCi load or reload operation.
data LoadResult = LoadResult
    { moduleCount :: Int
    , compiledFiles :: Set FilePath
    -- ^ Files that were compiled in this cycle (derived from 'Language.Haskell.Ghcid.Loading' items).
    -- Used by 'Tricorder.GhciSession.mergeDiagnostics' to decide which files' previous
    -- diagnostics to replace vs. retain.
    , diagnostics :: [Diagnostic]
    }
    deriving stock (Eq, Show)


data GhciSession :: Effect where
    -- | Start a new GHCi session and run the handler with that session active.
    -- The handler is also provided an action to reload the GHCi session,
    -- returning new messages with module counts. The GHCi session is closed
    -- when the handler returns.
    WithGhci :: Text -> ProjectRoot -> (LoadResult -> Controls m -> m a) -> GhciSession m a


data Controls m = Controls
    { reload :: m LoadResult
    , interrupt :: m ()
    }


makeEffect ''GhciSession


-- | Production interpreter backed by the real ghcid library.
-- Manages the 'Ghcid.Ghci' handle via 'State'.
runGhciSessionIO :: (BuildStore :> es, IOE :> es, Log :> es) => Eff (GhciSession : es) a -> Eff es a
runGhciSessionIO = interpret $ \env -> \case
    WithGhci cmd (ProjectRoot dir) handler -> do
        let mkSession = withEffToIO (ConcUnlift Persistent Unlimited) \unlift -> do
                Ghcid.startGhci (toString cmd) (Just dir) \_ line -> do
                    unlift $ Log.debug $ "GhciSession callback: " <> toText line
                    whenJust (parseProgress line) \(n, m) ->
                        unlift do
                            Log.debug $ "GhciSession: progress " <> show n <> "/" <> show m
                            bs <- getState
                            setPhase bs.buildId
                                $ Building
                                $ Just
                                $ BuildProgress {compiled = n, total = m}

            stopSession (ghci, _) =
                liftIO $ stopGhciSilently ghci

        bracket mkSession stopSession \(ghci, loads) ->
            localLend @'[IOE] env (ConcUnlift Persistent Unlimited) \lendIOE ->
                localUnlift env (ConcUnlift Persistent Unlimited) \unlift -> do
                    initialLoadResult <- liftIO $ collectResult ghci loads
                    unlift
                        $ handler
                            initialLoadResult
                            Controls
                                { reload =
                                    lendIOE
                                        $ liftIO
                                        $ Ghcid.reload ghci >>= collectResult ghci
                                , interrupt =
                                    lendIOE
                                        $ liftIO
                                        $ Ghcid.interrupt ghci
                                }


-- | Scripted interpreter for testing.
--
-- Each call to 'startGhci' or 'reloadGhci' pops the next result from the
-- pre-loaded list. 'Left' results are re-thrown as exceptions, simulating
-- GHCi crashes. 'stopGhci' is always a no-op.
--
-- Requires 'IOE' so that 'Left' exceptions can be thrown into the effectful
-- context, enabling tests of error-handling logic.
runGhciSessionScripted :: forall es a. (IOE :> es) => [Either SomeException LoadResult] -> Eff (GhciSession : es) a -> Eff es a
runGhciSessionScripted results = reinterpret (evalState results) $ \env ->
    let popResult :: Eff (State [Either SomeException LoadResult] : es) LoadResult
        popResult = do
            x <- state \case
                x : xs -> (x, xs)
                [] -> error "GhciSessionScripted: no more results in queue"
            case x of
                Left ex -> liftIO (throwIO ex)
                Right r -> pure r
    in  \case
            WithGhci _ _ handler -> do
                initial <- popResult
                localSeqLift env \liftEff ->
                    localSeqUnlift env \unlift ->
                        unlift
                            $ handler
                                initial
                                Controls
                                    { reload = liftEff popResult
                                    , interrupt = pure ()
                                    }


stopGhciSilently :: Ghcid.Ghci -> IO ()
stopGhciSilently ghci = do
    void $ trySyncIO $ Ghcid.stopGhci ghci
    void $ trySyncIO $ waitForProcess (Ghcid.process ghci)


collectResult :: Ghcid.Ghci -> [Load] -> IO LoadResult
collectResult ghci loads = do
    projectRoot <- getCurrentDirectory
    let rel = toRelative projectRoot
    modules <- Ghcid.showModules ghci
    -- When -fhide-source-paths is on (default since GHC 9.2), GHCi omits the
    -- "[N of M] Compiling ..." lines from :reload output, so no Loading items
    -- are produced.  Mirror the fallback in ghcid's startGhciProcess: if no
    -- Loading items were found, treat all currently-loaded modules as compiled.
    let compiledFiles = case [f | Ghcid.Loading {loadFile = f} <- loads] of
            [] -> Set.fromList (map (rel . snd) modules)
            fs -> Set.fromList (map rel fs)
    pure LoadResult {moduleCount = length modules, compiledFiles, diagnostics = toDiagnostics rel loads}


toDiagnostics :: (FilePath -> FilePath) -> [Load] -> [Diagnostic]
toDiagnostics rel loads = mapMaybe toMsg loads
  where
    -- Skip GHCi-internal diagnostics (e.g. <interactive>, <no location info>).
    -- These are never from real source files and cannot be cleared by
    -- incremental recompilation, so they would persist in the accumulated map.
    toMsg (Ghcid.Message _ ('<' : _) _ _ _) = Nothing
    toMsg (Ghcid.Message sev file (l, c) (el, ec) msgLines) =
        Just
            BuildState.Diagnostic
                { severity = case sev of
                    Ghcid.Warning -> SWarning
                    Ghcid.Error -> SError
                , file = rel file
                , line = l
                , col = c
                , endLine = el
                , endCol = ec
                , title = extractTitle msgLines
                , text = unlines (map toText msgLines)
                }
    toMsg _ = Nothing


-- | Make an absolute path relative to the given base directory, prefixed with
-- @"./"@.  Paths already relative, or absolute paths outside @base@, are
-- returned unchanged.
toRelative :: FilePath -> FilePath -> FilePath
toRelative base path
    | not (isAbsolute path) = path
    | otherwise = case splitDirectories (makeRelative base path) of
        (".." : _) -> path -- not under base, keep absolute
        rel -> "." </> joinPath rel
  where
    joinPath = List.foldr1 (</>)


-- | Parse @"[N of M] Compiling ..."@ progress lines from GHCi output.
--
-- GHC pads the module index for alignment (e.g. @"[ 1 of 47]"@), so we
-- extract the content between @[@ and @]@ before splitting on whitespace.
parseProgress :: String -> Maybe (Int, Int)
parseProgress line = do
    rest <- List.stripPrefix "[" (dropWhile isSpace (stripAnsi line))
    let (inside, after) = break (== ']') rest
    guard (not (null after))
    guard ("Compiling" `List.isPrefixOf` dropWhile isSpace (drop 1 after))
    case words (toText inside) of
        [nTxt, "of", mTxt] -> (,) <$> readMaybe (toString nTxt) <*> readMaybe (toString mTxt)
        _ -> Nothing


-- | Strip ANSI escape sequences of the form @ESC [ \<params\> \<letter\>@.
stripAnsi :: String -> String
stripAnsi [] = []
stripAnsi ('\ESC' : '[' : rest) =
    stripAnsi (drop 1 (dropWhile (not . isAlpha) rest))
stripAnsi (c : rest) = c : stripAnsi rest


-- | Extract a short human-readable title from ghcid's 'loadMessage'.
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
    fromMaybe (firstBodyLine body) (inlineFromHeader (stripAnsi header))
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
             , let t = dropWhile isSpace (stripAnsi x)
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
