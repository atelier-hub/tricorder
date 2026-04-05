# Roadmap

## ghcib

### Known Issues

- **Stale warnings dropped on incremental reloads** — ghcib only stores messages from
  the latest reload cycle. GHC's incremental compilation skips unchanged files, so
  their warnings are never re-emitted and disappear from ghcib's state. Fix: accumulate
  messages across reload cycles, merging by file so that a recompiled file replaces its
  previous messages while untouched files retain theirs.

### Features

- **Plugin-Based Structured Diagnostics** [[WP-002](ghcib/proposals/002-plugin-diagnostics/)] — introduce `ghcib-plugin`, a GHC compiler plugin that forwards native structured diagnostics (error codes, hints, related spans) to the daemon over a Unix socket. Falls back to the current behaviour for projects that do not install the plugin.
  - _Depends on:_ WP-001

- **Package Search** [[WP-003](ghcib/proposals/003-source-lookup/)] — `ghcib search` command that queries a local Hoogle database and returns haddock source, with a `--contents` flag to include source inline. The daemon checks for and generates a local Hoogle database at startup.

### Ideas

- **GHC error code linking** — surface `[GHC-XXXXX]` error codes as links to
  `errors.haskell.org` in terminal output and the JSON protocol.
  - _Depends on:_ WP-002

- **Real-time streaming output** — investigate how to make it possible for `ghcib status` output to JSONL to enable real-time streaming of status updates.
    - An initial status if building: "Building... (29/40 modules)"
    - Another message (with diagnostics) when done or failed: "Done (40 modules, etc.)"

- **Reduce diagnostic verbosity** — the `diagnostics` array can be large; 
  - Limiting count by default unless explicitly requested
  - Only displaying diagnostic titles by default.
    - Config: different modes for number of diagnostics above or below a certain threshold.
      - `>t` => titles only
      - `<=t` => full messages

- **Smart default targets** — when no targets are specified, auto-discover test suites
  from the `.cabal` file and include them explicitly. Also improve `resolveWatchDirs`,
  which currently falls back to `["."]` when no targets are set.
