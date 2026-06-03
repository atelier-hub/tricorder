module Atelier.Effects.Env
    ( Env
    , getEnvironment
    , runEnv
    , runEnvConst
    ) where

import Effectful (Effect, IOE)
import Effectful.Dispatch.Dynamic (interpret_)
import Effectful.TH (makeEffect)

import System.Environment qualified as System


data Env :: Effect where
    GetEnvironment :: Env m [(String, String)]


makeEffect ''Env


runEnv :: (IOE :> es) => Eff (Env : es) a -> Eff es a
runEnv = interpret_ $ \GetEnvironment -> liftIO System.getEnvironment


runEnvConst :: [(String, String)] -> Eff (Env : es) a -> Eff es a
runEnvConst env = interpret_ $ \GetEnvironment -> pure env
