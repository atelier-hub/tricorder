# Roadmap

## ghcib

### Known Issues

- **Cabal changes not applied until daemon restart** — changes to `.cabal`, `package.yaml`, or
  `cabal.project` are detected but only trigger a `:reload`, which is insufficient. New
  dependencies and target changes require a full GHCi session restart. Workaround: `ghcib stop && ghcib start`.

### Features

- **Plugin-Based Structured Diagnostics** [[WP-002](ghcib/proposals/002-plugin-diagnostics/)] — introduce `ghcib-plugin`, a GHC compiler plugin that forwards native structured diagnostics (error codes, hints, related spans) to the daemon over a Unix socket. Falls back to the current behaviour for projects that do not install the plugin.

- **Package Search** [[WP-003](ghcib/proposals/003-source-lookup/)] — `ghcib search` command that queries a local Hoogle database and returns haddock source, with a `--contents` flag to include source inline. The daemon checks for and generates a local Hoogle database at startup.

### Ideas

- **GHC error code linking** — surface `[GHC-XXXXX]` error codes as links to
  `errors.haskell.org` in terminal output.
  - _Depends on:_ WP-002

- **Real-time streaming output** — stream `ghcib status --wait` output as it becomes
  available rather than blocking until completion.
    - Print progress while building: "Building... (29/40 modules)"
    - Print diagnostics + summary when done

- **Verbose diagnostic output** — `ghcib status --verbose` (or `-v`) to print the full GHC
  message body under each diagnostic, avoiding the need to re-query with `--json` when the
  one-line title isn't enough to diagnose an error.

- **Smart default targets** — when no targets are specified, auto-discover test suites
  from the `.cabal` file and include them explicitly. Also improve `resolveWatchDirs`,
  which currently falls back to `["."]` when no targets are set.

### Completed

- **Rename `Message` → `Diagnostic`** [[WP-001](ghcib/proposals/001-diagnostic-rename/)] — aligned wire protocol and codebase with LSP/GHC ecosystem terminology.
- **Text output for `ghcib status`** — human-readable text is now the default (`E file:line title` per diagnostic, summary line); `--json` flag preserves structured output for tool integration. Exit code reflects error presence.
- **Reliable rebuild triggering** — replaced debounce + channel queuing with a dirty-flag model; multiple saves during a build coalesce to exactly one follow-up build with no dropped or redundant rebuilds.
