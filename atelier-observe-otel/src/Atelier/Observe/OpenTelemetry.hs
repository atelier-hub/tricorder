-- | An OpenTelemetry exporter for "Atelier.Observe": a 'Consumer' that folds a run's 'Moment' stream
-- into OpenTelemetry spans through a 'OT.Tracer'. It is the streaming counterpart to the trie
-- harvest in "Atelier.Observe.Aggregate" — where that summarizes a finished run, this emits spans
-- live as the run unfolds.
--
-- The mapping:
--
--   * 'Entered' opens a span. Its parent is the span of the enclosing region (same trace identity,
--     one shorter 'Path'); a region with no enclosing span starts a fresh trace. The entry signals
--     become span attributes, and the 'Atelier.Observe.linkedTo' targets become span /links/ to the
--     root spans of those traces (resolved best-effort: a link to a trace not yet started is dropped).
--   * 'Exited' ends the span with 'OT.Ok' status, its exit signals added as attributes.
--   * 'Failed' ends the span with 'OT.Error' status, the exception recorded ('OT.recordException')
--     and its failure signals added as attributes.
--   * 'Measured' adds a span event carrying the sampler reading.
--
-- The signal and measurement lanes are polymorphic, so the caller supplies a 'Render' saying how a
-- region path becomes a span name and how each lane becomes attributes. The consumer's harvest is
-- @()@: spans are the side effect. Bracketed by 'Atelier.Observe.observe', its teardown ends any
-- span left open by a short-circuit, so a failing run still flushes well-formed spans.
module Atelier.Observe.OpenTelemetry
    ( exporting
    , Render (..)
    , simpleRender
    ) where

import Atelier.Observe (Consumer, Moment (..), Path, consumer)
import Effectful (IOE)

import Data.HashMap.Strict qualified as HM
import Data.Map.Strict qualified as Map
import Data.Text qualified as Text
import OpenTelemetry.Context qualified as Ctx
import OpenTelemetry.Trace.Core qualified as OT


-- | How to render the polymorphic lanes of a 'Moment' into the OpenTelemetry vocabulary: the region
-- 'Path' into a span name, and each signal (@e@) and sampler reading (@s@) into attributes. A span's
-- trace identity (@i@) can also contribute attributes, for correlation.
data Render i r e s = Render
    { renderName :: Path r -> Text
    -- ^ the span name for a region, from its full path
    , renderSignal :: e -> [(Text, OT.Attribute)]
    -- ^ attributes contributed by one signal (the @e@ lane), added on enter, leave, and failure
    , renderMeasurement :: s -> [(Text, OT.Attribute)]
    -- ^ attributes for a sampler reading (the @s@ lane), attached as a span event
    , renderTraceId :: i -> [(Text, OT.Attribute)]
    -- ^ attributes derived from a span's trace identity, for correlation
    }


-- | A 'Render' for the common case where the region label is 'Show'able: the span name is the
-- region path joined with dots and no attributes are emitted. Layer attributes on with record
-- updates, e.g. @'simpleRender' {renderSignal = \\sig -> …}@.
simpleRender :: (Show r) => Render i r e s
simpleRender =
    Render
        { renderName = Text.intercalate "." . map (Text.pack . show)
        , renderSignal = const []
        , renderMeasurement = const []
        , renderTraceId = const []
        }


-- The exporter's fold state: the spans currently open (keyed by trace identity and region path) and
-- the root span context of each trace identity, kept so cross-trace links can be resolved.
data Live i r = Live
    { openSpans :: Map.Map (Maybe i, Path r) OT.Span
    , rootCtxs :: Map.Map i OT.SpanContext
    }


-- | Fold a 'Moment' stream into OpenTelemetry spans through the given 'OT.Tracer'. Pair it with
-- 'Atelier.Observe.observe' (or fan out alongside another consumer with 'Atelier.Observe.teeC'):
--
-- @
-- (a, ()) <- 'Atelier.Observe.observe' ('exporting' tracer render) plan program
-- @
--
-- The 'OT.Tracer' comes from any provider — "Atelier.Observe.OpenTelemetry.Provider" for an OTLP one,
-- or an in-memory provider in tests.
exporting
    :: (IOE :> es, Ord i, Ord r)
    => OT.Tracer
    -> Render i r e s
    -> Consumer es i r e s ()
exporting tracer render = consumer (pure (Live Map.empty Map.empty)) step stop
  where
    step live = \case
        Entered mid links path entrySigs -> liftIO do
            let parent = Map.lookup (mid, parentPath path) live.openSpans
                ctx = maybe Ctx.empty (`Ctx.insertSpan` Ctx.empty) parent
                linkCtxs = mapMaybe (`Map.lookup` live.rootCtxs) links
                attrs =
                    HM.fromList
                        ( concatMap (renderSignal render) entrySigs
                            <> foldMap (renderTraceId render) mid
                        )
                args =
                    OT.defaultSpanArguments
                        { OT.attributes = attrs
                        , OT.links =
                            map (\c -> OT.NewLink {OT.linkContext = c, OT.linkAttributes = HM.empty}) linkCtxs
                        }
            sp <- OT.createSpanWithoutCallStack tracer ctx (renderName render path) args
            -- a region with no enclosing span is a trace root; remember its context for link resolution
            roots' <- case mid of
                Just i | isNothing parent -> do
                    sctx <- OT.getSpanContext sp
                    pure (Map.insert i sctx live.rootCtxs)
                _ -> pure live.rootCtxs
            pure live {openSpans = Map.insert (mid, path) sp live.openSpans, rootCtxs = roots'}
        Exited mid path exitSigs -> liftIO do
            onSpan live (mid, path) \sp -> do
                OT.addAttributes sp (HM.fromList (concatMap (renderSignal render) exitSigs))
                OT.setStatus sp OT.Ok
                OT.endSpan sp Nothing
            pure (close (mid, path) live)
        Failed mid path failSigs ex -> liftIO do
            onSpan live (mid, path) \sp -> do
                OT.addAttributes sp (HM.fromList (concatMap (renderSignal render) failSigs))
                OT.recordException sp HM.empty Nothing ex
                OT.setStatus sp (OT.Error (Text.pack (show ex)))
                OT.endSpan sp Nothing
            pure (close (mid, path) live)
        Measured mid path reading -> liftIO do
            onSpan live (mid, path) \sp ->
                OT.addEvent
                    sp
                    OT.NewEvent
                        { OT.newEventName = "measurement"
                        , OT.newEventAttributes = HM.fromList (renderMeasurement render reading)
                        , OT.newEventTimestamp = Nothing
                        }
            pure live
    -- teardown (the failure path included): end any span a short-circuit left open, so the run still
    -- flushes well-formed spans.
    stop live = liftIO (forM_ (Map.elems live.openSpans) \sp -> OT.endSpan sp Nothing)

    onSpan live key act = maybe (pure ()) act (Map.lookup key live.openSpans)
    close key live = live {openSpans = Map.delete key live.openSpans}


-- The enclosing region's path: this region's path with its own (innermost) label dropped.
parentPath :: Path r -> Path r
parentPath [] = []
parentPath [_] = []
parentPath (r : rs) = r : parentPath rs
