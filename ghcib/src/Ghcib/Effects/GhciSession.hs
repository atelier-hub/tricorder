module Ghcib.Effects.GhciSession
    ( -- * Effect
      GhciSession
    , startGhci
    , reloadGhci
    , stopGhci

      -- * Types
    , LoadResult (..)

      -- * Interpreters
    , runGhciSessionIO
    , runGhciSessionScripted
    ) where

import Control.Exception (throwIO, try)
import Effectful (Effect, IOE)
import Effectful.Dispatch.Dynamic (reinterpret)
import Effectful.State.Static.Shared (State, evalState, get, put)
import Effectful.TH (makeEffect)
import Language.Haskell.Ghcid (Load (..))

import Data.Set qualified as Set
import Language.Haskell.Ghcid qualified as Ghcid

import Ghcib.BuildState (Diagnostic (..), Severity (..))

import Ghcib.BuildState qualified as BuildState


-- | The result of a GHCi load or reload operation.
data LoadResult = LoadResult
    { moduleCount :: Int
    , compiledFiles :: Set FilePath
    -- ^ Files that were compiled in this cycle (derived from 'Language.Haskell.Ghcid.Loading' items).
    -- Used by 'Ghcib.GhciSession.mergeDiagnostics' to decide which files' previous
    -- diagnostics to replace vs. retain.
    , diagnostics :: [Diagnostic]
    }
    deriving stock (Eq, Show)


data GhciSession :: Effect where
    -- | Start a new GHCi session. If a session is already running it is
    -- stopped first. Returns the initial compilation messages with module count.
    StartGhci :: Text -> FilePath -> GhciSession m LoadResult
    -- | Send @:reload@ to the current session and return new messages with module count.
    ReloadGhci :: GhciSession m LoadResult
    -- | Stop the current session. No-op if no session is running.
    StopGhci :: GhciSession m ()


makeEffect ''GhciSession


-- | Production interpreter backed by the real ghcid library.
-- Manages the 'Ghcid.Ghci' handle via 'State'.
runGhciSessionIO :: (IOE :> es) => Eff (GhciSession : es) a -> Eff es a
runGhciSessionIO = reinterpret (evalState (Nothing :: Maybe Ghcid.Ghci)) $ \_ -> \case
    StartGhci cmd dir -> do
        mOld <- get
        whenJust mOld \old -> liftIO $ stopGhciSilently old
        (ghci, loads) <- liftIO $ Ghcid.startGhci (toString cmd) (Just dir) (\_ _ -> pure ())
        put (Just ghci)
        liftIO $ collectResult ghci loads
    ReloadGhci ->
        get >>= \case
            Nothing -> error "GhciSession: reloadGhci called before startGhci"
            Just ghci -> liftIO do
                loads <- Ghcid.reload ghci
                collectResult ghci loads
    StopGhci ->
        get >>= \mGhci -> whenJust mGhci \ghci -> do
            liftIO $ stopGhciSilently ghci
            put (Nothing :: Maybe Ghcid.Ghci)


-- | Scripted interpreter for testing.
--
-- Each call to 'startGhci' or 'reloadGhci' pops the next result from the
-- pre-loaded list. 'Left' results are re-thrown as exceptions, simulating
-- GHCi crashes. 'stopGhci' is always a no-op.
--
-- Requires 'IOE' so that 'Left' exceptions can be thrown into the effectful
-- context, enabling tests of error-handling logic.
runGhciSessionScripted :: forall es a. (IOE :> es) => [Either SomeException LoadResult] -> Eff (GhciSession : es) a -> Eff es a
runGhciSessionScripted results = reinterpret (evalState results) $ \_ ->
    let popResult :: Eff (State [Either SomeException LoadResult] : es) LoadResult
        popResult =
            get >>= \case
                [] -> error "GhciSessionScripted: no more results in queue"
                Left ex : rest -> put rest >> liftIO (throwIO ex)
                Right r : rest -> put rest >> pure r
    in  \case
            StartGhci _ _ -> popResult
            ReloadGhci -> popResult
            StopGhci -> pure ()


stopGhciSilently :: Ghcid.Ghci -> IO ()
stopGhciSilently ghci = void $ try @SomeException $ Ghcid.stopGhci ghci


collectResult :: Ghcid.Ghci -> [Load] -> IO LoadResult
collectResult ghci loads = do
    modules <- Ghcid.showModules ghci
    -- When -fhide-source-paths is on (default since GHC 9.2), GHCi omits the
    -- "[N of M] Compiling ..." lines from :reload output, so no Loading items
    -- are produced.  Mirror the fallback in ghcid's startGhciProcess: if no
    -- Loading items were found, treat all currently-loaded modules as compiled.
    let compiledFiles = case [f | Ghcid.Loading {loadFile = f} <- loads] of
            [] -> Set.fromList (map snd modules)
            fs -> Set.fromList fs
    pure LoadResult {moduleCount = length modules, compiledFiles, diagnostics = toDiagnostics loads}


toDiagnostics :: [Load] -> [Diagnostic]
toDiagnostics loads = mapMaybe toMsg loads
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
                , file = file
                , line = l
                , col = c
                , endLine = el
                , endCol = ec
                , title = maybe "" toText (listToMaybe msgLines)
                , text = unlines (map toText msgLines)
                }
    toMsg _ = Nothing
