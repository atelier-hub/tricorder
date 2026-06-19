-- | Side-channel observation of an oblivious Effectful program. The library separates instrumenting
-- a program from summarizing the run, in three stages:
--
--   * __Produce__ — a 'Plan' instruments an oblivious program: 'Tap's interpose on its effects to
--     emit signals (the @e@ lane) on each region boundary, 'Sampler's bracket each region to read a
--     resource (the @s@ lane). This is the only part that can't be a consumer: a consumer is a
--     fold, with no handle on the program, so it can't bracket the body to read a clock.
--   * __Stream__ — discharging the plan turns the run into a 'Moment' stream
--     ('Entered'\/'Exited'\/'Failed'\/'Measured'), the one artifact at the center.
--   * __Fold__ — a 'Consumer' is a left fold over that stream into a harvest; what the harvest /is/
--     is entirely the consumer's business. This module supplies the generic builders ('foldMoments',
--     'eachMoment', 'teeC'); "Atelier.Observe.Aggregate" supplies a 'collecting' consumer for the
--     hierarchical case (a 'Region' trie of two-laned 'Report's). That summary is a /policy/, kept
--     out of the core: a flat event log, an order-sensitive causal check, or an OpenTelemetry
--     exporter wants nothing to do with it, and pulls in none of it.
--
-- The core keeps two write-isolated signal lanes, a @'Tap'@ '<>' that merges instrumentation without
-- nesting the region, and an exception-safe discharge that captures an operation's input on entry so
-- it survives a throw. A __'Plan'__ is program-side instrumentation; a __'Consumer'__ is a left fold
-- over the 'Moment' stream; __'observe'__ threads one consumer over a plan, returning @(a, harvest)@
-- beside the program's untouched result.
module Atelier.Observe
    ( -- * Instrumenting an effect
      Tap (..)
    , watch
    , tracedBy
    , linkedTo
    , entering
    , leaving
    , failing
    , Observes

      -- * The plan
    , Plan
    , tap
    , sampling

      -- * Consumers
    , Consumer
    , consumer
    , foldMoments
    , eachMoment
    , teeC

      -- * Measurements
    , Sampler (..)
    , gauge

      -- * Moments
    , Moment (..)
    , Path

      -- * Discharge
    , observe
    , observeInto
    , silent
    ) where

import Control.Foldl (FoldM (..))
import Effectful (Dispatch (Dynamic), DispatchOf, Effect, Subset, inject)
import Effectful.Dispatch.Dynamic (interpose, interpret, localSeqUnlift, passthrough)
import Effectful.Exception (bracket, catch, onException, throwIO)
import Effectful.Reader.Static (ask, local, runReader)
import Effectful.State.Static.Local (State, get, modify, put, runState)
import Effectful.TH (makeEffect)
import Prelude hiding (trace)

import Control.Foldl qualified as L


-- The one internal observation effect. A 'Scope' carries its link targets and entry signals up
-- front, a function from a thrown exception to its failure signals, and a body that yields its exit
-- signals alongside the result (so the discharge can attach them to 'Exited'); a 'Trace' sets the
-- ambient identity. A 'Tap' is the only producer, a discharge the only consumer (internal).
data Obs i r e :: Effect where
    Scope :: r -> [i] -> [e] -> (SomeException -> [e]) -> m (a, [e]) -> Obs i r e m a
    Trace :: i -> m a -> Obs i r e m a


makeEffect ''Obs


-- The effect row an instrumented program runs in: the internal 'Obs' over the program's own
-- effects @es@ (internal).
type Observing es i r e = Obs i r e : es


-- | What 'tap' asks of each oblivious effect @eff@ it bundles: that @eff@ is a dynamically
-- dispatched effect reachable through the instrumented row. Give an instrumenting wrapper one
-- 'Observes' per effect it taps, e.g. @('Observes' es Foo i r e, 'Observes' es Bar i r e) =>
-- 'Plan' es i r e s@ — the row stays unnamed.
type Observes es eff i r e = (DispatchOf eff ~ Dynamic, eff :> Observing es i r e)


-- | Everything done to one oblivious effect @eff@, as a single descriptor:
--
--   * 'region' — which region label each operation files under (the 'Scope');
--   * 'under' — the optional trace each operation runs under ('Nothing' inherits the ambient
--     trace; 'Just' names one, e.g. a request id carried in the operation);
--   * 'linking' — the trace identities this operation's region links to, surfaced on 'Entered' for
--     an exporter to emit cross-trace links ('[]' links to none);
--   * 'onEnter' — signals from the operation's input, fired into 'Entered' before the work;
--   * 'onLeave' — signals from input and result, fired into 'Exited' after the work;
--   * 'onError' — signals from input and the thrown exception, fired into 'Failed' when the work
--     throws ('onLeave' never runs on that path — there is no result to derive it from).
--
-- Build the common cases with 'watch' and the 'entering'\/'leaving'\/'tracedBy'\/'linkedTo' setters
-- (or record updates). 'tap' applies it all in one interpose, fixing the nesting trace ⊃ region ⊃ signals.
data Tap eff i r e = Tap
    { region :: forall localEs b. eff (Eff localEs) b -> r
    , under :: forall localEs b. eff (Eff localEs) b -> Maybe i
    , linking :: forall localEs b. eff (Eff localEs) b -> [i]
    , onEnter :: forall localEs b. eff (Eff localEs) b -> [e]
    , onLeave :: forall localEs b. eff (Eff localEs) b -> b -> [e]
    , onError :: forall localEs b. eff (Eff localEs) b -> SomeException -> [e]
    }


-- | Merge two taps on the /same/ effect into one. The left tap's 'region' and 'under' classify the
-- operation — they are assumed to agree, since both instrument the same seam — and the three signal
-- functions concatenate, so every layer's 'onEnter'\/'onLeave'\/'onError' fires.
--
-- This is how you observe one region several ways /without nesting it/: @'tap' (seam '<>' checkA
-- '<>' checkB)@ installs a __single__ interpose, so the operation opens __one__ 'Scope' carrying
-- all the signals. Contrast @'tap' seam '<>' 'tap' checkA@, which installs two interposes — the
-- second 'passthrough's through the first, so the region nests inside itself. The 'Tap' @'<>'@
-- means \"more observations on the same region\"; the 'Plan' @'<>'@ means \"observe another
-- effect\".
--
-- There is no 'Monoid': a tap must always name a 'region', and @r@ has no identity.
instance Semigroup (Tap eff i r e) where
    t1 <> t2 =
        Tap
            { region = region t1
            , under = under t1
            , linking = \op -> linking t1 op <> linking t2 op
            , onEnter = \op -> onEnter t1 op <> onEnter t2 op
            , onLeave = \op b -> onLeave t1 op b <> onLeave t2 op b
            , onError = \op e -> onError t1 op e <> onError t2 op e
            }


-- | A 'Tap' that only files each operation under a region — no trace, no signals. The defaulting
-- constructor: layer on the parts you want with 'entering'\/'leaving'\/'tracedBy' (or record
-- updates), e.g. @watch (\\case Lower _ -> LowerOp) & leaving (\\(Lower _) (IR t) -> [Golden "ir" t])@.
watch :: (forall localEs b. eff (Eff localEs) b -> r) -> Tap eff i r e
watch label =
    Tap
        { region = label
        , under = \_ -> Nothing
        , linking = \_ -> []
        , onEnter = \_ -> []
        , onLeave = \_ _ -> []
        , onError = \_ _ -> []
        }


-- | Set the trace each operation runs under: @'watch' label & 'tracedBy' (\\op -> …)@. The setter
-- form of the 'under' field, for building a 'Tap' left-to-right without brace syntax.
tracedBy :: (forall localEs b. eff (Eff localEs) b -> Maybe i) -> Tap eff i r e -> Tap eff i r e
tracedBy f t = t {under = f}


-- | Set the trace identities each operation's region links to: @'watch' label & 'linkedTo' (\\op -> …)@.
-- The setter form of the 'linking' field. An exporter that maps regions to spans (e.g. OpenTelemetry)
-- may emit a cross-trace link to each named trace; consumers that ignore links are unaffected.
linkedTo :: (forall localEs b. eff (Eff localEs) b -> [i]) -> Tap eff i r e -> Tap eff i r e
linkedTo f t = t {linking = f}


-- | Set the entry signals derived from an operation's input: @'watch' label & 'entering' (\\op -> …)@.
-- The setter form of the 'onEnter' field.
entering :: (forall localEs b. eff (Eff localEs) b -> [e]) -> Tap eff i r e -> Tap eff i r e
entering f t = t {onEnter = f}


-- | Set the exit signals derived from an operation's input and result:
-- @'watch' label & 'leaving' (\\op result -> …)@. The setter form of the 'onLeave' field — the
-- everyday case, since most signals are result-derived.
leaving :: (forall localEs b. eff (Eff localEs) b -> b -> [e]) -> Tap eff i r e -> Tap eff i r e
leaving f t = t {onLeave = f}


-- | Set the failure signals derived from an operation's input and the exception it threw:
-- @'watch' label & 'failing' (\\op e -> …)@. The setter form of the 'onError' field.
failing :: (forall localEs b. eff (Eff localEs) b -> SomeException -> [e]) -> Tap eff i r e -> Tap eff i r e
failing f t = t {onError = f}


-- Apply a 'Tap' to an oblivious program: interpose on each operation of @eff@, open its region
-- with the entry signals, run it, and hand back the result paired with the exit signals — the
-- result itself unchanged (internal; 'tap' is the only caller).
instrument
    :: (DispatchOf eff ~ Dynamic, eff :> Observing es i r e)
    => Tap eff i r e
    -> Eff (Observing es i r e) a
    -> Eff (Observing es i r e) a
instrument t = interpose \env op ->
    let body = do
            b <- passthrough env op
            pure (b, onLeave t op b)
        observed = scope (region t op) (linking t op) (onEnter t op) (onError t op) body
    in  case under t op of
            Nothing -> observed
            Just i -> trace i observed


-- A program transformer that installs some taps; composes by function composition (internal).
newtype Instrument es = Instrument (forall a. Eff es a -> Eff es a)


instance Semigroup (Instrument es) where
    Instrument f <> Instrument g = Instrument (f . g)


instance Monoid (Instrument es) where
    mempty = Instrument id


-- | The program-side configuration of a run: the taps to install and the 'Sampler' to bracket
-- each region. Assemble with 'tap' and 'sampling', merge with @'<>'@; 'mempty' instruments
-- nothing. It carries no observers and no harvest type — what to do with the 'Moment's a run
-- produces is a 'Consumer', chosen at the discharge.
data Plan es i r e s = Plan (Instrument (Observing es i r e)) (Sampler es s)


instance Semigroup (Plan es i r e s) where
    Plan t1 s1 <> Plan t2 s2 = Plan (t1 <> t2) (s1 <> s2)


instance Monoid (Plan es i r e s) where
    mempty = Plan mempty mempty


-- | A 'Plan' that installs one 'Tap' and nothing else. Merge several with @'<>'@ to observe
-- several effects of one program.
tap
    :: (Observes es eff i r e)
    => Tap eff i r e
    -> Plan es i r e s
tap t = Plan (Instrument (instrument t)) mempty


-- | A 'Plan' that adds a 'Sampler' and nothing else: the resource it folds surfaces as a
-- 'Measured' 'Moment' that a 'Consumer' may handle.
sampling :: Sampler es s -> Plan es i r e s
sampling s = Plan mempty s


-- | What to do with a run's 'Moment' stream: a monadic left fold over the moments in the base row
-- @es@. It is exactly a @'FoldM' ('Eff' es)@, so the structure comes for free — it is an
-- 'Applicative' (combine consumers with 'teeC' \/ 'liftA2', fan out in one pass), a 'Functor' (map
-- the harvest), and a 'Profunctor' (adapt the moment stream with @premap@\/@prefilter@ from
-- "Control.Foldl"). Build the common ones with 'foldMoments' and 'eachMoment'; combine with 'teeC';
-- or use 'consumer' for a bespoke fold. For the hierarchical region rollup, "Atelier.Observe.Aggregate"
-- supplies a 'collecting' consumer built on these same combinators.
--
-- A 'Consumer' is /only/ a fold: it has no handle on the program's continuation or result, so it
-- cannot change what the program computes — it can only accumulate. Its @start@\/@stop@ are
-- bracketed by 'observe', so @stop@ runs (fed the partial accumulator) even when the program
-- throws — the hook for an exporter to flush and release on the failure path.
type Consumer es i r e s h = FoldM (Eff es) (Moment i r e s) h


-- | Build a 'Consumer' from a left fold: @start@ seeds the accumulator (or acquires a resource),
-- @step@ folds each 'Moment' into it (effectfully if it needs the base row), and @stop@ extracts
-- the harvest (or flushes). The accumulator is existential, so it is private to the consumer.
-- (foldl's 'FoldM' takes its fields @step@-first; this keeps the natural start\/step\/stop order.)
consumer
    :: Eff es x
    -> (x -> Moment i r e s -> Eff es x)
    -> (x -> Eff es h)
    -> Consumer es i r e s h
consumer start step stop = FoldM step start stop


-- | A consumer that folds the stream into a monoid by mapping each 'Moment' to a contribution
-- and @'<>'@-ing them in program order. Pure — no effects, so it runs under @runPureEff@. The
-- everyday case: an event log (@'foldMoments' (\\m -> [tag m])@), an aggregate, or the trie
-- consumer in "Atelier.Observe.Aggregate".
foldMoments :: (Monoid w) => (Moment i r e s -> w) -> Consumer es i r e s w
foldMoments f = L.generalize (L.foldMap f id)


-- | A consumer that runs an effect for each 'Moment' and accumulates nothing (harvest @()@).
-- The effect runs in the base row @es@, so this is where an OTel\/analytics sink lives — supply
-- what it needs with a constraint, e.g. @('IOE' ':>' es) => …@ to export. The body's result is
-- unchanged.
eachMoment :: (Moment i r e s -> Eff es ()) -> Consumer es i r e s ()
eachMoment = L.mapM_


-- | Run two consumers in a single pass and pair their harvests — the fan-out combinator, which is
-- just the 'Applicative' product of the two folds. One instrumented run can feed a 'collecting'
-- harvest /and/ an 'eachMoment' exporter at once: @'observe' (harvest \`teeC\` exporter) plan
-- prog@. (Fan out N consumers with 'liftA2'\/'sequenceA' directly.)
teeC :: Consumer es i r e s h1 -> Consumer es i r e s h2 -> Consumer es i r e s (h1, h2)
teeC = liftA2 (,)


-- | The ambient region path: the stack of enclosing 'Scope' labels, outermost first. A plain list,
-- so consumers can pattern-match it, key a map on it, and write it as a literal. The discharge
-- accumulates it as an @'Endo' [r]@ difference list (O(1) to extend per nesting level), materializing
-- to this @[r]@ once per 'Moment'.
type Path r = [r]


-- | Measures a resource (wall-clock, allocation, …) spent in a region. A discharge brackets
-- each region with the sampler and hands it a @record@ callback that files a measurement
-- against the current region, surfacing as a 'Measured' 'Moment'. Polymorphic over the stack it
-- runs on, so one sampler serves every discharge. Compose with @<>@ (nest) and @mempty@.
newtype Sampler es s
    = Sampler (forall esX x. (Subset es esX) => (s -> Eff esX ()) -> Eff esX x -> Eff esX x)


instance Semigroup (Sampler es s) where
    Sampler s1 <> Sampler s2 = Sampler \record act -> s1 record (s2 record act)


instance Monoid (Sampler es s) where
    mempty = Sampler \_ act -> act


-- | Build a 'Sampler' from a gauge: read @probe@ before and after the region and record what the
-- two readings contribute. Bracketed, so a region that throws still reports its measurement.
--
-- The bracket spans the region's /whole body/, nested regions included, so a gauge reading is
-- __inclusive__: a region's measurement covers everything that ran inside it. Aggregate the
-- measurement lane with @rollUp@ (which preserves these inclusive readings), not @cumulative@
-- (which would sum each nested region into its ancestors a second time) — both in "Atelier.Observe.Aggregate".
gauge :: Eff es p -> (p -> p -> s) -> Sampler es s
gauge probe delta = Sampler \record act ->
    bracket (inject probe) (\before -> inject probe >>= record . delta before) (\_ -> act)


-- | A single moment in a region's life, as the discharge reaches it. Each carries the ambient
-- trace identity ('Nothing' outside any trace) and the region's 'Path': 'Entered' opens a region
-- with the trace identities it links to (the @[i]@ link lane) and its entry signals (the @e@ lane),
-- 'Exited' closes it with its exit signals, 'Failed' closes
-- it /abnormally/ with the thrown exception and its failure signals (in place of 'Exited' when the
-- operation throws), 'Measured' carries a 'Sampler' reading (the @s@ lane). The two signal lanes
-- never cross. Maps onto OpenTelemetry as span-start \/ span-end \/ span-end-with-error-status \/
-- span-metric, with signals as the spans' start\/end attributes.
data Moment i r e s
    = Entered (Maybe i) [i] (Path r) [e]
    | Exited (Maybe i) (Path r) [e]
    | Failed (Maybe i) (Path r) [e] SomeException
    | Measured (Maybe i) (Path r) s


-- | The discharge: install the 'Plan's taps, run the program, and fold the 'Moment' stream
-- through the 'Consumer'. One 'interpret' over the 'Obs' effect produces the moments — a 'Scope'
-- fires 'Entered' (with the entry signals) then 'Exited' (with the exit signals the body yields,
-- and 'Measured' for each 'Sampler' reading), a 'Trace' sets the ambient identity. The consumer's
-- accumulator rides a discharge-private 'State', seeded by @start@ before the run and read into
-- @stop@ after, so the consumer needs no effect of its own beyond what its @step@ uses. Each
-- 'Moment' carries the trace identity active when its region opened.
--
-- __Exception-safe.__ 'Entered' has already fired (with the entry signals) before the body runs,
-- so an operation's input survives a throw. On a throwing operation the region closes with 'Failed'
-- — carrying the exception and the failure signals from 'onError' — in place of 'Exited' (there is
-- no result, so 'onLeave' cannot run), and the exception re-propagates. The whole run is also
-- wrapped in 'onException' so that, if the program throws, @stop@ still runs, fed the partial
-- accumulator recovered from the (exception-surviving) discharge 'State'; on that path @stop@\'s
-- harvest is discarded and the original exception re-propagates. @(a, h)@ is returned only when the
-- program completes normally.
observe
    :: Consumer es i r e s h
    -> Plan es i r e s
    -> Eff es a
    -> Eff es (a, h)
observe (FoldM step start stop) (Plan (Instrument install) (Sampler sample)) program = do
    x0 <- start
    (a, xFinal) <-
        runReader (mempty :: Endo (Path r))
            . runReader (Nothing :: Maybe i)
            . runState x0
            $ ( interpret
                    ( \env ->
                        let fire m = do
                                acc <- get
                                acc' <- inject (step acc m)
                                put acc'
                        in  \case
                                Scope r links entrySigs onErr act -> do
                                    mid <- ask
                                    -- the ancestor path as a difference list; extending it for the
                                    -- body and materializing this region's full path are both cheap
                                    prefix <- ask
                                    let full = appEndo prefix [r]
                                        body = localSeqUnlift env \unlift -> local (<> Endo (r :)) (unlift act)
                                    fire (Entered mid links full entrySigs)
                                    (result, exitSigs) <-
                                        sample (\res -> fire (Measured mid full res)) body
                                            `catch` \(e :: SomeException) -> fire (Failed mid full (onErr e) e) >> throwIO e
                                    fire (Exited mid full exitSigs)
                                    pure result
                                Trace i act ->
                                    localSeqUnlift env \unlift -> local (const (Just i)) (unlift act)
                    )
                    . inject
                    . install
                    . inject
                    $ program
              )
                -- Failure path: flush the partial accumulator through @stop@, then re-raise.
                `onException` (get >>= inject . stop)
    h <- stop xFinal
    pure (a, h)


-- | A discharge whose harvest survives a short-circuit. Like 'observe' it installs the 'Plan's
-- taps and folds the 'Moment' stream, but it folds each moment into a monoid held in a 'State' the
-- /caller/ runs, and returns only the program's result. The caller reads the harvest from that
-- 'State' after the run.
--
-- That is the whole point. 'observe' keeps its accumulator private and returns @(a, h)@ only on the
-- normal path — if the program short-circuits, the harvest is gone. Here the accumulator lives in
-- @es@, so when an interpreter composed /outside/ this call but /inside/ the 'State' converts a
-- failure to a value — @'Effectful.Error.Static.runError'@ turning a short-circuit into a 'Left' —
-- the harvest accumulated up to the failure is intact, the failing region's 'Measured' and 'Failed'
-- moments included. Run the 'State' /outside/ the error handler (so the unwinding stops at the
-- handler, not the state) and read it however the program ended:
--
-- @
-- (resultOrErr, harvest) <-
--     'runState' mempty . runError . \<base interpreters\>
--         $ 'observeInto' contribute plan program
-- @
--
-- Pair it with a monoidal fold — @collectMoment@ from "Atelier.Observe.Aggregate" for a trie harvest, or any
-- @'Moment' -> w@ (as 'foldMoments' takes). For the all-in-one @(result, harvest)@ of a run that
-- completes normally, use 'observe'.
observeInto
    :: forall i r e s w es a
     . (Monoid w, State w :> es)
    => (Moment i r e s -> w)
    -> Plan es i r e s
    -> Eff es a
    -> Eff es a
observeInto contribute (Plan (Instrument install) (Sampler sample)) program =
    runReader (mempty :: Endo (Path r))
        . runReader (Nothing :: Maybe i)
        $ ( interpret
                ( \env ->
                    let fire m = modify (<> contribute m)
                    in  \case
                            Scope r links entrySigs onErr act -> do
                                mid <- ask
                                prefix <- ask
                                let full = appEndo prefix [r]
                                    body = localSeqUnlift env \unlift -> local (<> Endo (r :)) (unlift act)
                                fire (Entered mid links full entrySigs)
                                (result, exitSigs) <-
                                    sample (\res -> fire (Measured mid full res)) body
                                        `catch` \(e :: SomeException) -> fire (Failed mid full (onErr e) e) >> throwIO e
                                fire (Exited mid full exitSigs)
                                pure result
                            Trace i act ->
                                localSeqUnlift env \unlift -> local (const (Just i)) (unlift act)
                )
                . inject
                . install
                . inject
                $ program
          )


-- | Production discharge: install the 'Plan's taps, then run — regions run, signals vanish,
-- nothing is sampled or forced, trace identities are discarded. One 'interpret' runs each
-- 'Scope'\/'Trace' body, dropping the entry signals, the yielded exit signals, and the unused
-- failure-signal function without forcing any of them.
silent :: Plan es i r e s -> Eff es a -> Eff es a
silent (Plan (Instrument install) _) =
    interpret
        ( \env -> \case
            Scope _ _ _ _ act -> localSeqUnlift env \unlift -> fst <$> unlift act
            Trace _ act -> localSeqUnlift env \unlift -> unlift act
        )
        . install
        . inject
