# Roadmap

## atelier
### Ideas
- **Optional `doctor` field on `Atelier.Component`**
    - Check status of components (any diagnostics accumulated during execution of the component).

## tricorder

### Features

- **Plugin-Based Structured Diagnostics** [[WP-002](tricorder/proposals/002-plugin-diagnostics/)] — introduce `tricorder-plugin`, a GHC compiler plugin that forwards native structured diagnostics (error codes, hints, related spans) to the daemon over a Unix socket. Falls back to the current behaviour for projects that do not install the plugin.

- **Package Search** [[WP-003](tricorder/proposals/003-source-lookup/)] — `tricorder search` command that queries a local Hoogle database and returns haddock source, with a `--contents` flag to include source inline. The daemon checks for and generates a local Hoogle database at startup.

### Ideas

- **Distribute as agent plugin**
    - Package this as a plugin for Claude and other providers.

- **Run tests after build**
    - Configurable command to run the tests if build is green.
    - Can we run the tests from ghci? That could be very quick.

- **Eager subsequent restarts**
    - When `startGhci` is doing a full compile and a second CabalChange arrives (hpack's .cabal regeneration), cancel the ongoing startup and restart rather than letting it finish and doing a second full restart.

- **Improve `watch` rendering**
    - Hide content below the fold in watch mode to keep summary at the top and display just the first few errors.
    - Add a hotkey to watch mode to toggle between verbose/concise mode.

- **Real-time streaming output**
    - Stream `tricorder status --wait` output as it becomes available rather than blocking until completion.
    - Print progress while building: "Building... (29/40 modules)".
    - Print diagnostics + summary when done.

- **Smart default targets**
    - Improve `resolveWatchDirs`, which currently falls back to `["."]` when no targets are set.

### Completed

- **Verbose diagnostic output** — `tricorder status --verbose` (or `-v`) to print the full GHC
  message body under each diagnostic, avoiding the need to re-query with `--json` when the
  one-line title isn't enough to diagnose an error.

- **Rename `Message` → `Diagnostic`** [[WP-001](tricorder/proposals/001-diagnostic-rename/)] — aligned wire protocol and codebase with LSP/GHC ecosystem terminology.

- **Text output for `tricorder status`** — human-readable text is now the default (`E file:line title` per diagnostic, summary line); `--json` flag preserves structured output for tool integration. Exit code reflects error presence.

- **Reliable rebuild triggering** — replaced debounce + channel queuing with a dirty-flag model; multiple saves during a build coalesce to exactly one follow-up build with no dropped or redundant rebuilds.

- **Cabal change detection** — changes to `.cabal`, `package.yaml`, or `cabal.project` now trigger a full GHCi session restart instead of a `:reload`, picking up new dependencies and target changes automatically.

- **`tricorder log`** — shows daemon log output; `--follow` / `-f` streams new lines as they are written.
