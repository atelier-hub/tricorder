module Tricorder.Effects.SessionStore
    ( SessionStore (..)
    , SessionStoreReloaded (..)
    , get
    , reload
    , withSession
    , ActiveSession (..)
    , runSessionStore
    , runSessionStoreConst
    ) where

import Effectful (Effect)
import Effectful.Dispatch.Dynamic (interpret_, reinterpretWith_)
import Effectful.Reader.Static (Reader)
import Effectful.TH (makeEffect)
import Relude.Extra.Tuple (dup)

import Effectful.State.Static.Shared qualified as State

import Atelier.Config (LoadedConfig)
import Atelier.Effects.Conc (Conc)
import Atelier.Effects.FileSystem (FileSystem)
import Atelier.Effects.Publishing (Pub, Sub, publish)
import Tricorder.Runtime (ProjectRoot)
import Tricorder.Session (Session, loadSession)

import Atelier.Effects.Conc qualified as Conc
import Atelier.Effects.Publishing qualified as Sub


data SessionStore :: Effect where
    Get :: SessionStore m Session
    Reload :: SessionStore m ()


makeEffect ''SessionStore


data ActiveSession es = ActiveSession
    { session :: Session
    , reloadSession :: Eff es ()
    }


-- | Operate on the most recent 'Session' stored. Whenever the session is
-- reloaded, the passed action is cancelled, and started again with the new
-- 'Session'.
withSession
    :: ( Conc :> es
       , SessionStore :> es
       , Sub SessionStoreReloaded :> es
       )
    => (ActiveSession es -> Eff es a)
    -> Eff es Void
withSession act = forever $ Conc.scoped do
    session <- get
    _ <-
        Conc.fork
            $ act
            $ ActiveSession
                { session
                , reloadSession = reload
                }
    void $ Sub.listenOnce_ @SessionStoreReloaded


data SessionStoreReloaded = SessionStoreReloaded Session


runSessionStore
    :: ( FileSystem :> es
       , Pub SessionStoreReloaded :> es
       , Reader LoadedConfig :> es
       , Reader ProjectRoot :> es
       )
    => Eff (SessionStore : es) a -> Eff es a
runSessionStore act = do
    initialSession <- loadSession
    reinterpretWith_ (State.evalState initialSession) act \case
        Get -> State.get
        Reload -> do
            session <- State.stateM (\_ -> dup <$> loadSession)
            publish $ SessionStoreReloaded session


runSessionStoreConst :: Session -> Eff (SessionStore : es) a -> Eff es a
runSessionStoreConst session = interpret_ \case
    Get -> pure session
    Reload -> pure ()
