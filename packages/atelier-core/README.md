# atelier-core

Foundational effects and utilities for effect-based applications, built on [Effectful](https://github.com/haskell-effectful/effectful). Part of the **atelier** toolkit.

## Overview

`atelier-core` provides a set of composable Effectful effects and supporting
types for building structured, observable applications.

It also wraps a number of `IO`-based primitives (environment, clock, file
system, console, POSIX) as effects so they can be interpreted and tested
explicitly: `Atelier.Effects.Env`, `Atelier.Effects.Clock`,
`Atelier.Effects.FileSystem`, `Atelier.Effects.Console`,
`Atelier.Effects.Posix.*`, and more.

## License

MIT — see [LICENSE](LICENSE).
