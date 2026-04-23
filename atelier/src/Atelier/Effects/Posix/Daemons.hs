module Atelier.Effects.Posix.Daemons
    ( Daemons
    , PidFile (..)
    , daemonize
    , isRunning
    , killAndWait
    , runDaemons
    ) where

import Data.Default (def)
import Effectful (Effect, IOE, Limit (..), Persistence (..), UnliftStrategy (..))
import Effectful.Dispatch.Dynamic (interpretWith, localUnliftIO)
import Effectful.Exception (IOException, try)
import Effectful.Reader.Static (Reader, ask)
import Effectful.TH (makeEffect)

import System.Posix.Daemon qualified as Daemons


data Daemons :: Effect where
    -- | Daemonize the given program, ensuring it is cleanly separated from the
    -- spawning process.
    Daemonize :: m () -> Daemons m ()
    -- | Check whether a daemon is running for the provided PID file.
    IsRunning :: Daemons m Bool
    -- | Kill the daemon associated with the provided PID file, waiting for it
    -- to shut down.
    KillAndWait :: Daemons m ()


newtype PidFile = PidFile {getPidFile :: FilePath}


makeEffect ''Daemons


runDaemons :: (IOE :> es, Reader PidFile :> es) => Eff (Daemons : es) a -> Eff es a
runDaemons act = do
    PidFile pidFile <- ask
    interpretWith act \env -> \case
        Daemonize program ->
            localUnliftIO env (ConcUnlift Persistent Unlimited) \unlift ->
                Daemons.runDetached (Just pidFile) def $ unlift program
        IsRunning ->
            liftIO $ Daemons.isRunning pidFile
        KillAndWait ->
            void $ try @IOException $ liftIO $ Daemons.killAndWait pidFile
