# Roadmap

## Known Issues

### ghcib

- **Stale warnings dropped on incremental reloads** — ghcib only stores messages from the latest reload cycle. GHC's incremental compilation skips unchanged files, so their warnings are never re-emitted and disappear from ghcib's state. Fix: accumulate messages across reload cycles, merging by file so that a recompiled file replaces its previous messages while untouched files retain theirs.

## ghcib

- **Reduce error verbosity** — `messages` array can be large; consider limiting count unless explicitly requested

- **Tap into the ghci stream** — `Ghcid.startGhci` receives a load stream that is currently ignored (`\_ _ -> pure ()`); could be used for richer or more timely data

- **JSONL output format** — switch `ghcib status` output to JSONL to enable real-time streaming of status updates (possibly related to the ghci stream idea above)

- **Smart default targets** — when no targets are specified, currently defaults to `all`. Instead, auto-discover test suites from the `.cabal` file and include them explicitly. Example: `cabal repl --enable-multi-repl all hoard-test atelier-test`. Also improve `resolveWatchDirs`, which currently falls back to `["."]` when no targets are set.
