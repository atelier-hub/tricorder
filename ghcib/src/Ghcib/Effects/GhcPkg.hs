module Ghcib.Effects.GhcPkg
    ( GhcPkg
    , findModule
    , getHaddockHtml
    , runGhcPkgIO
    , runGhcPkgScripted
    , GhcPkgScript (..)
    ) where

import Effectful (Effect, IOE)
import Effectful.Dispatch.Dynamic (interpret, reinterpret)
import Effectful.Exception (try)
import Effectful.State.Static.Shared (evalState, get, put)
import Effectful.TH (makeEffect)
import System.Process.Typed (proc, readProcessStdout_)

import Data.ByteString.Lazy qualified as BSL
import Data.Text qualified as T

import Ghcib.GhcPkg.Types (ModuleName (..), PackageId (..))


data GhcPkg :: Effect where
    FindModule :: ModuleName -> GhcPkg m (Maybe PackageId)
    GetHaddockHtml :: PackageId -> GhcPkg m (Maybe FilePath)


makeEffect ''GhcPkg


runGhcPkgIO :: (IOE :> es) => Eff (GhcPkg : es) a -> Eff es a
runGhcPkgIO = interpret \_ -> \case
    FindModule modName -> do
        out <- readProcessSafe "ghc-pkg" ["find-module", "--simple-output", toString (unModuleName modName)]
        pure $ out >>= fmap PackageId . listToMaybe . filter (not . T.null) . map T.strip . T.lines
    GetHaddockHtml pkgId -> do
        out <- readProcessSafe "ghc-pkg" ["field", toString (unPackageId pkgId), "haddock-html", "--simple-output"]
        pure $ out >>= listToMaybe . map toString . T.words


-- | Script element for the test interpreter.
data GhcPkgScript
    = -- | Return this value for the next 'findModule' call.
      NextFindModule (Maybe PackageId)
    | -- | Return this value for the next 'getHaddockHtml' call.
      NextGetHaddockHtml (Maybe FilePath)


-- | Scripted interpreter for testing. Does not require 'IOE'.
runGhcPkgScripted :: [GhcPkgScript] -> Eff (GhcPkg : es) a -> Eff es a
runGhcPkgScripted script = reinterpret (evalState script) \_ -> \case
    FindModule _ ->
        get >>= \case
            NextFindModule result : rest -> put rest >> pure result
            _ -> error "GhcPkgScripted: expected NextFindModule but queue was empty or mismatched"
    GetHaddockHtml _ ->
        get >>= \case
            NextGetHaddockHtml result : rest -> put rest >> pure result
            _ -> error "GhcPkgScripted: expected NextGetHaddockHtml but queue was empty or mismatched"


-- | Run a process and return its stdout as 'Text', or 'Nothing' on any error.
readProcessSafe :: (IOE :> es) => FilePath -> [String] -> Eff es (Maybe Text)
readProcessSafe cmd args = do
    result <- try @SomeException $ liftIO $ readProcessStdout_ (proc cmd args)
    pure $ case result of
        Left _ -> Nothing
        Right bs -> Just (decodeUtf8 (BSL.toStrict bs))
