module Tricorder.Events.Restart
    ( Restart (..)
    , onEvent
    , onSessionReload
    ) where

import Effectful.State.Static.Shared (evalState, get, put)

import Atelier.Effects.Conc (Conc)
import Atelier.Effects.Publishing (Pub, Sub, publish)
import Tricorder.Session (Session)

import Atelier.Effects.Conc qualified as Conc
import Atelier.Effects.Publishing qualified as Sub
import Tricorder.SessionStore qualified as SessionStore


newtype Restart a = Restart a


onEvent
    :: (Conc :> es, Sub (Restart arg) :> es)
    => (arg -> Eff es b) -> Restart arg -> Eff es Void
onEvent action (Restart env) = do
    restart <- Conc.scoped do
        void $ Conc.fork $ action env
        Sub.listenOnce_
    onEvent action restart


onSessionReload
    :: ( Eq subSession
       , Pub (Restart subSession) :> es
       , Sub SessionStore.Reloaded :> es
       )
    => (Session -> subSession) -> Session -> Eff es Void
onSessionReload mkSubSession initialSession = evalState initial $ forever do
    SessionStore.Reloaded session <- Sub.listenOnce_
    let new = mkSubSession session
    old <- get
    when (old /= new) do
        put new
        publish $ Restart new
  where
    initial = mkSubSession initialSession
