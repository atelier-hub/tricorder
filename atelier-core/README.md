# Atelier

A family of Haskell packages providing foundational infrastructure for
effect-based applications, built on
[Effectful](https://github.com/haskell-effectful/effectful).

## Packages

### `atelier-core`

Core effects and utilities:

| Module | Purpose |
|---|---|
| `Atelier.Component` | Structured component lifecycle (`setup → listeners → start`) |
| `Atelier.Config` | Configuration with environment variable overrides |
| `Atelier.Effects.Log` | Structured logging with hierarchical namespaces |
| `Atelier.Effects.Conc` | Thread management via Ki (structured concurrency) |
| `Atelier.Effects.Cache` | Caching with singleflight deduplication |
| `Atelier.Effects.Publishing` | Event publishing |
| `Atelier.Effects.Monitoring.*` | OpenTelemetry tracing and Prometheus metrics |

### `atelier-db`

Relational database access via Rel8/Hasql, exposed as an Effectful effect
(`Atelier.Effects.DB`).

### `atelier-prelude`

Custom prelude based on [relude](https://github.com/kowainik/relude), enforcing Effectful conventions.

### `atelier-testing`

Test utilities for database-backed tests using [tmp-postgres](https://github.com/jfischoff/tmp-postgres).
