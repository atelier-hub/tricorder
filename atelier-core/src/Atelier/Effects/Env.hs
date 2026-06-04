-- | An effect for reading process environment variables.
--
-- 'runEnv' reads the real process environment; 'runEnvConst' supplies a fixed
-- association list for tests.
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


-- | Effect for reading the process environment.
data Env :: Effect where
    -- | The full environment as a list of @(name, value)@ pairs.
    GetEnvironment :: Env m [(String, String)]


makeEffect ''Env


-- | Interpret 'Env' against the real process environment.
runEnv :: (IOE :> es) => Eff (Env : es) a -> Eff es a
runEnv = interpret_ $ \GetEnvironment -> liftIO System.getEnvironment


-- | Interpret 'Env' with a fixed environment, for tests.
runEnvConst :: [(String, String)] -> Eff (Env : es) a -> Eff es a
runEnvConst env = interpret_ $ \GetEnvironment -> pure env
