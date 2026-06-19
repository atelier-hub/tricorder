# atelier-observe

Side-channel observation of **oblivious** [Effectful](https://github.com/haskell-effectful/effectful) programs. Instrument a program from the outside, watch it run as a stream of moments, and fold that stream however you like — without the program ever knowing it is watched. Part of the **atelier** toolkit.

## The shape

Three stages, kept deliberately apart:

- **Produce** — a `Tap` interposes on one oblivious effect to emit signals on each region boundary (and a `Sampler` brackets each region to read a resource like wall-clock or allocation). A `Plan` assembles taps and samplers; merge with `<>`.
- **Stream** — discharging a `Plan` over a run turns it into a `Moment` stream: `Entered` / `Exited` / `Failed` / `Measured`. This is the one artifact at the centre, and it maps onto OpenTelemetry as span-start / span-end / span-end-with-error / span-metric.
- **Fold** — a `Consumer` is a left fold (`Control.Foldl.FoldM`) over that stream into a harvest. What the harvest *is* is entirely the consumer's business: an event log, an aggregate, a streaming exporter.

```haskell
(result, harvest) <- observe someConsumer somePlan program
```

The discharge is a side channel: a `Consumer` is *only* a fold, so it can never change what the program computes. `observe` brackets the consumer's start/stop, so an exporter still flushes when the program throws.

## Modules

- **`Atelier.Observe`** — the irreducible core: `Tap`, `Plan`, `Consumer`, `Moment`, and the `observe` / `observeInto` / `silent` discharges.
- **`Atelier.Observe.Aggregate`** — one summary *policy*: a `Region` trie of two-laned `Report`s keyed into `Traces`, with the `collecting` consumer. It is a pure function of the public `Moment` stream, so the core never depends on it — a flat log or a streaming exporter pulls in none of it.

## Part of atelier

- [`atelier-prelude`](https://github.com/atelier-hub/tricorder/tree/main/atelier-prelude) — relude-based custom prelude adapted for Effectful
- [`atelier-core`](https://github.com/atelier-hub/tricorder/tree/main/atelier-core) — foundational effects and utilities
- [`atelier-observe`](https://github.com/atelier-hub/tricorder/tree/main/atelier-observe) — this package
- [`atelier-db`](https://github.com/atelier-hub/tricorder/tree/main/atelier-db) — relational database effect (Hasql/Rel8)
- [`atelier-testing`](https://github.com/atelier-hub/tricorder/tree/main/atelier-testing) — database-backed test utilities

## License

MIT — see [LICENSE](LICENSE).
