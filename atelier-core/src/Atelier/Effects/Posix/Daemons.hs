module Atelier.Effects.Posix.Daemons
    ( Daemons
    , PidFile (..)
    , daemonize
    , isRunning
    , forceKillAndWait
    , runDaemons
    ) where

import Data.Default (def)
import Effectful (Effect, IOE, Limit (..), Persistence (..), UnliftStrategy (..))
import Effectful.Dispatch.Dynamic (interpretWith, localUnliftIO)
import Effectful.Exception (trySync)
import Effectful.TH (makeEffect)

import System.Posix.Daemon qualified as Daemons


data Daemons :: Effect where
    -- | Daemonize the given program, ensuring it is cleanly separated from the
    -- spawning process.
    Daemonize :: PidFile -> m () -> Daemons m ()
    -- | Check whether a daemon is running for the provided PID file.
    IsRunning :: PidFile -> Daemons m Bool
    -- | Kill the daemon associated with the provided PID file using `SIGKILL`.
    ForceKillAndWait :: PidFile -> Daemons m (Either SomeException ())


newtype PidFile = PidFile {getPidFile :: FilePath}


makeEffect ''Daemons


runDaemons :: (IOE :> es) => Eff (Daemons : es) a -> Eff es a
runDaemons act = do
    interpretWith act \env -> \case
        Daemonize (PidFile pidFile) program ->
            localUnliftIO env (ConcUnlift Persistent Unlimited) \unlift -> do
                Daemons.runDetached (Just pidFile) def
                    $ unlift program
        IsRunning (PidFile pidFile) ->
            liftIO $ Daemons.isRunning pidFile
        ForceKillAndWait (PidFile pidFile) ->
            trySync $ liftIO $ Daemons.brutalKill pidFile
