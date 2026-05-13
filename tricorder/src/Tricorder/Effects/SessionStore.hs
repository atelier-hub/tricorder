module Tricorder.Effects.SessionStore
    ( SessionStore (..)
    , SessionStoreReloaded (..)
    , get
    , withSession
    , withSubSession
    , ActiveSession (..)
    , Reloader (..)
    , runSessionStore
    , runSessionStoreConst
    ) where

import Effectful (Effect, inject)
import Effectful.Concurrent (Concurrent)
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
import Atelier.Types.Semaphore qualified as Sem


data SessionStore :: Effect where
    Get :: SessionStore m Session
    RawReload :: SessionStore m ()


makeEffect ''SessionStore


data ActiveSession es = ActiveSession
    { session :: Session
    , reloader :: Reloader es
    }


newtype Reloader es = Reloader {reload :: Eff es ()}


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
                , reloader = Reloader rawReload
                }
    void $ Sub.listenOnce_ @SessionStoreReloaded


-- | Tracks the parts of 'Session' that the caller cares about, and restarts
-- the passed function whenever those parts change based on the 'subSession's
-- 'Eq' instance.
withSubSession
    :: forall subSession es a
     . ( Conc :> es
       , Concurrent :> es
       , Eq subSession
       , SessionStore :> es
       , Sub SessionStoreReloaded :> es
       )
    => (Session -> subSession)
    -> Session
    -> (Reloader es -> subSession -> Eff es a)
    -> Eff es Void
withSubSession mkSubSession initialSession action =
    State.evalState (mkSubSession initialSession) do
        -- Used to signal the thread running the passed function to restart
        -- the function.
        restartSem <- Sem.new

        Conc.fork_ $ withSession \activeSession -> do
            let newSubSession = mkSubSession activeSession.session
            oldSubSession <- State.get @subSession
            when (newSubSession /= oldSubSession) do
                State.put newSubSession
                -- Sub session is changed. Signal the thread managing the
                -- passed function to restart said function.
                Sem.signal restartSem

        -- Run the passed function and wait for the signal to restart.
        forever $ Conc.scoped do
            cfg <- State.get
            _ <- Conc.fork $ inject $ action (Reloader rawReload) cfg
            -- Passing this 'Sem.wait' ends the scope, killing all
            -- associated threads, and restarts the passed function again,
            -- fetching a new, fresh `subSession`.
            Sem.wait restartSem


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
        RawReload -> do
            session <- State.stateM (\_ -> dup <$> loadSession)
            publish $ SessionStoreReloaded session


runSessionStoreConst :: Session -> Eff (SessionStore : es) a -> Eff es a
runSessionStoreConst session = interpret_ \case
    Get -> pure session
    RawReload -> pure ()
