module Tricorder.SessionStore
    ( component
    , Reloaded (..)
    , ReloadRequested (..)
    , reloadSession
    ) where

import Effectful.Reader.Static (Reader)
import Effectful.State.Static.Shared (State)
import Relude.Extra.Tuple (dup)

import Effectful.State.Static.Shared qualified as State

import Atelier.Component (Component (..), defaultComponent)
import Atelier.Effects.FileSystem (FileSystem)
import Atelier.Effects.Publishing (Pub, Sub, publish)
import Tricorder.Config (LoadedConfig)
import Tricorder.Runtime (ProjectRoot)
import Tricorder.Session (Session, loadSession)

import Atelier.Effects.Publishing qualified as Sub


component
    :: ( FileSystem :> es
       , Pub Reloaded :> es
       , Reader LoadedConfig :> es
       , Reader ProjectRoot :> es
       , State Session :> es
       , Sub ReloadRequested :> es
       )
    => Component es
component =
    defaultComponent
        { name = "SessionStore"
        , listeners = pure [Sub.listen_ reloadSession]
        }


data ReloadRequested = ReloadRequested


data Reloaded = Reloaded Session
    deriving stock (Eq, Show)


reloadSession
    :: ( FileSystem :> es
       , Pub Reloaded :> es
       , Reader LoadedConfig :> es
       , Reader ProjectRoot :> es
       , State Session :> es
       )
    => ReloadRequested -> Eff es ()
reloadSession ReloadRequested = do
    session <- State.stateM (\_ -> dup <$> loadSession)
    publish $ Reloaded session
