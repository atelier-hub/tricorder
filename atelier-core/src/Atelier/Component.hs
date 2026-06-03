module Atelier.Component
    ( Component (..)
    , defaultComponent
    , Listener
    , Trigger
    , runComponent
    , runSystem
    ) where

import Text.Casing (fromHumps, toQuietSnake)

import Atelier.Effects.Conc (Conc)
import Atelier.Effects.Log (Log)
import Atelier.Effects.Monitoring.Tracing (Tracing, withSpan)

import Atelier.Effects.Conc qualified as Conc
import Atelier.Effects.Log qualified as Log


-- | Type aliases for semantic clarity
type Listener es = Eff es Void


type Trigger es = Eff es Void


-- | Component interface for modular application structure
data Component es = Component
    { name :: ~Text
    -- ^ Component name for tracing
    , setup :: Eff es ()
    -- ^ Setup component (runs before listeners/triggers start)
    , listeners :: Eff es [Listener es]
    -- ^ Event listeners (react to events)
    , triggers :: Eff es [Trigger es]
    -- ^ Triggers (initiate periodic/scheduled work)
    , start :: Eff es ()
    -- ^ Post-start actions (runs after all components have started)
    }


defaultComponent :: (HasCallStack) => Component es
defaultComponent =
    Component
        { name = error "Missing component name"
        , setup = pure ()
        , listeners = pure []
        , triggers = pure []
        , start = pure ()
        }


-- | Run a component by forking its listeners and triggers
runComponent :: (Conc :> es, Tracing :> es) => Component es -> Eff es ()
runComponent c = withSpan c.name $ do
    ls <- c.listeners
    ts <- c.triggers
    traverse_ Conc.fork_ ls
    traverse_ Conc.fork_ ts


-- | Run multiple components with structured lifecycle coordination
--
-- Executes components in three sequential phases:
--   1. Run @setup for all components (initialization before activation)
--   2. Fork all listeners and triggers (components become active)
--   3. Fork @start for all components (background startup actions)
--
-- This separation allows components to prepare resources during setup, then perform
-- work during start that depends on listeners already running (e.g., publishing events).
-- The start phase is forked to allow parallel execution across components.
runSystem
    :: forall es
     . (Conc :> es, Log :> es, Tracing :> es)
    => [Component es]
    -> Eff es ()
runSystem components = Conc.scoped do
    -- Phase 1: Setup all components
    traverse_ setupComponent components

    -- Phase 2: Start all components (fork listeners/triggers)
    traverse_ startComponent components

    -- Phase 3: Fork post-start actions
    traverse_ postStartComponent components

    Conc.awaitAll
  where
    setupComponent :: Component es -> Eff es ()
    setupComponent c = do
        let name = formatName c.name
        Log.debug $ "Setting up component: " <> name
        withSpan (name <> ":setup")
            $ c.setup

    startComponent :: Component es -> Eff es ()
    startComponent c = do
        let name = formatName c.name
        Log.debug $ "Starting listeners/triggers for component: " <> name
        runComponent c

    postStartComponent :: Component es -> Eff es ()
    postStartComponent c = do
        let name = formatName c.name
        Log.debug $ "Forking start phase for component: " <> name
        void . Conc.fork
            $ withSpan (name <> ":start")
            $ c.start


formatName :: Text -> Text
formatName = toText . toQuietSnake . fromHumps . toString
