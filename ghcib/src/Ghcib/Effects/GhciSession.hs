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

import Language.Haskell.Ghcid qualified as Ghcid

import Ghcib.BuildState (Message (..), Severity (..))

import Ghcib.BuildState qualified as BuildState


-- | The result of a GHCi load or reload operation.
data LoadResult = LoadResult
    { moduleCount :: Int
    , messages :: [Message]
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
runGhciSessionScripted :: forall es a. (IOE :> es) => [Either SomeException [Message]] -> Eff (GhciSession : es) a -> Eff es a
runGhciSessionScripted results = reinterpret (evalState results) $ \_ ->
    let popResult :: Eff (State [Either SomeException [Message]] : es) LoadResult
        popResult =
            get >>= \case
                [] -> error "GhciSessionScripted: no more results in queue"
                Left ex : rest -> put rest >> liftIO (throwIO ex)
                Right msgs : rest -> put rest >> pure LoadResult {moduleCount = 0, messages = msgs}
    in  \case
            StartGhci _ _ -> popResult
            ReloadGhci -> popResult
            StopGhci -> pure ()


stopGhciSilently :: Ghcid.Ghci -> IO ()
stopGhciSilently ghci = void $ try @SomeException $ Ghcid.stopGhci ghci


collectResult :: Ghcid.Ghci -> [Load] -> IO LoadResult
collectResult ghci loads = do
    moduleCount <- length <$> Ghcid.showModules ghci
    pure LoadResult {moduleCount, messages = toMessages loads}


toMessages :: [Load] -> [Message]
toMessages loads = mapMaybe toMsg loads
  where
    toMsg (Ghcid.Message sev file (l, c) (el, ec) msgLines) =
        Just
            BuildState.Message
                { severity = case sev of
                    Ghcid.Warning -> SWarning
                    Ghcid.Error -> SError
                , file = file
                , line = l
                , col = c
                , endLine = el
                , endCol = ec
                , text = unlines (map toText msgLines)
                }
    toMsg _ = Nothing
