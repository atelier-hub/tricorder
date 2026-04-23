module Atelier.Effects.Posix.Daemon
    ( Daemon
    , PidFile (..)
    , daemonize
    , isRunning
    , killAndWait
    , runDaemon
    ) where

import Data.Default (def)
import Effectful (Dispatch (..), DispatchOf, Effect, IOE, Limit (..), Persistence (..), UnliftStrategy (..))
import Effectful.Dispatch.Dynamic (interpretWith, localUnliftIO, send)
import Effectful.Exception (IOException, try)

import System.Posix.Daemon qualified as Posix


data Daemon (tag :: k) :: Effect where
    Daemonize :: m () -> Daemon tag m ()
    IsRunning :: Daemon tag m Bool
    KillAndWait :: Daemon tag m ()


type instance DispatchOf (Daemon _) = 'Dynamic


newtype PidFile = PidFile {getPidFile :: FilePath}


daemonize :: forall tag es. (Daemon tag :> es) => Eff es () -> Eff es ()
daemonize program = send (Daemonize program :: Daemon tag (Eff es) ())


isRunning :: forall tag es. (Daemon tag :> es) => Eff es Bool
isRunning = send (IsRunning :: Daemon tag (Eff es) Bool)


killAndWait :: forall tag es. (Daemon tag :> es) => Eff es ()
killAndWait = send (KillAndWait :: Daemon tag (Eff es) ())


runDaemon :: (IOE :> es) => PidFile -> Eff (Daemon tag : es) a -> Eff es a
runDaemon (PidFile pidFile) act =
    interpretWith act \env -> \case
        Daemonize program ->
            localUnliftIO env (ConcUnlift Persistent Unlimited) \unlift ->
                Posix.runDetached (Just pidFile) def $ unlift program
        IsRunning ->
            liftIO $ Posix.isRunning pidFile
        KillAndWait ->
            void $ try @IOException $ liftIO $ Posix.killAndWait pidFile
