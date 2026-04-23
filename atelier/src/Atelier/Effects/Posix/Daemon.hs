module Atelier.Effects.Posix.Daemon
    ( Daemon
    , PidFile (..)
    , daemonize
    , isRunning
    , killAndWait
    , runDaemon
    ) where

import Data.Default (def)
import Effectful (Effect, IOE, Limit (..), Persistence (..), UnliftStrategy (..))
import Effectful.Dispatch.Dynamic (interpretWith, localUnliftIO)
import Effectful.Exception (IOException, try)
import Effectful.Reader.Static (Reader, ask)
import Effectful.TH (makeEffect)

import System.Posix.Daemon qualified as Posix


data Daemon :: Effect where
    -- | Daemonize the given program, ensuring it is cleanly separated from the
    -- spawning process.
    Daemonize :: m () -> Daemon m ()
    -- | Check whether a daemon is running for the provided PID file.
    IsRunning :: Daemon m Bool
    -- | Kill the daemon associated with the provided PID file, waiting for it
    -- to shut down.
    KillAndWait :: Daemon m ()


newtype PidFile = PidFile {getPidFile :: FilePath}


makeEffect ''Daemon


runDaemon :: (IOE :> es, Reader PidFile :> es) => Eff (Daemon : es) a -> Eff es a
runDaemon act = do
    PidFile pidFile <- ask
    interpretWith act \env -> \case
        Daemonize program ->
            localUnliftIO env (ConcUnlift Persistent Unlimited) \unlift ->
                Posix.runDetached (Just pidFile) def $ unlift program
        IsRunning ->
            liftIO $ Posix.isRunning pidFile
        KillAndWait ->
            void $ try @IOException $ liftIO $ Posix.killAndWait pidFile
