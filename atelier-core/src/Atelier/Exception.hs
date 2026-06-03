module Atelier.Exception
    ( isGracefulShutdown
    , trySyncIO
    , catchSyncIO
    , isSyncException
    ) where

import Effectful.Exception (SomeAsyncException, isSyncException)

import Control.Exception qualified as E


-- | Determine if an exception represents a graceful shutdown (any async exception).
--
-- Async exceptions indicate intentional cancellation (e.g., Ki's ScopeClosing,
-- or UserInterrupt from SIGINT), as opposed to real errors that warrant logging
-- or retry logic.
isGracefulShutdown :: SomeException -> Bool
isGracefulShutdown = isJust . fromException @SomeAsyncException


-- | Like `Control.Exception.try`, but will only catch synchronous exceptions.
trySyncIO :: IO a -> IO (Either SomeException a)
trySyncIO f = withFrozenCallStack catchSyncIO (fmap Right f) (pure . Left)


catchSyncIO :: (HasCallStack) => IO a -> (SomeException -> IO a) -> IO a
catchSyncIO f g =
    f `E.catch` \e ->
        if isSyncException e then
            g e
        else
            E.throwIO e
