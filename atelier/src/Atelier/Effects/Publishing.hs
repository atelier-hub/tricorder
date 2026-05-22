module Atelier.Effects.Publishing
    ( Pub
    , Sub
    , listen
    , listen_
    , listenOnce
    , listenOnce_
    , publish
    , runPubSub
    , runPubWriter
    )
where

import Data.Time (UTCTime)
import Effectful (Effect)
import Effectful.Dispatch.Dynamic (interpretWith, interpretWith_, interpret_, localSeqUnlift)
import Effectful.Error.Static (runErrorNoCallStack, throwError)
import Effectful.TH (makeEffect)
import Effectful.Writer.Static.Shared (Writer, tell)

import Text.Show qualified as S

import Atelier.Effects.Chan (Chan)
import Atelier.Effects.Clock (Clock)
import Atelier.Effects.Monitoring.Tracing (SpanContext, Tracing)

import Atelier.Effects.Chan qualified as Chan
import Atelier.Effects.Clock qualified as Clock
import Atelier.Effects.Monitoring.Tracing qualified as Tracing


data Pub (event :: Type) :: Effect where
    Publish :: event -> Pub event m ()


data Sub (event :: Type) :: Effect where
    Listen :: (UTCTime -> event -> m ()) -> Sub event m Void


makeEffect ''Pub
makeEffect ''Sub


listen_ :: (Sub event :> es) => (event -> Eff es ()) -> Eff es Void
listen_ listener = listen $ \_timestamp event -> listener event


-- | Wait for a single event and then return said event.
listenOnce :: forall event es. (Sub event :> es) => Eff es (UTCTime, event)
listenOnce = do
    res <- runErrorNoCallStack
        $ listen
        $ \timestamp event -> throwError $ OnceEx (timestamp, event)
    case res of
        Left (OnceEx x) -> pure x
        Right v -> absurd v


-- | Same as 'listenOnce', but discards the timestamp.
listenOnce_ :: (Sub event :> es) => Eff es event
listenOnce_ = snd <$> listenOnce


data OnceEx ev = OnceEx ev
instance Show (OnceEx ev) where show _ = "OnceEx"


-- | Internal wrapper for events with trace context
data TracedEvent event = TracedEvent
    { event :: event
    , timestamp :: UTCTime
    , publisherSpanContext :: Maybe SpanContext
    }


-- | Runs Pub and Sub effects with an internal channel for a specific event type.
-- Automatically captures span context from the publisher and creates linked spans in listeners.
runPubSub
    :: forall event es a
     . ( Chan :> es
       , Clock :> es
       , Tracing :> es
       )
    => Eff (Pub event : Sub event : es) a -> Eff es a
runPubSub action = do
    (inChan, _) <- Chan.newChan @(TracedEvent event)

    let handlePub eff = interpretWith_ eff \case
            Publish event -> do
                timestamp <- Clock.currentTime
                -- Capture the current span context from the publisher
                publisherSpanContext <- Tracing.getSpanContext
                Chan.writeChan inChan TracedEvent {event, timestamp, publisherSpanContext}

        handleSub eff = interpretWith eff \env -> \case
            Listen listener -> localSeqUnlift env \unlift -> do
                chan <- Chan.dupChan inChan
                forever do
                    TracedEvent {event, timestamp, publisherSpanContext} <- Chan.readChan chan
                    Tracing.withLinkPropagation publisherSpanContext $ unlift $ listener timestamp event

    handleSub . handlePub $ action


-- | Handler that uses a provided Writer effect instead of actually publishing.
-- Useful for testing and inspecting what events were published.
runPubWriter :: forall event es a. (Writer [event] :> es) => Eff (Pub event : es) a -> Eff es a
runPubWriter =
    interpret_ \case
        Publish event -> tell [event]
