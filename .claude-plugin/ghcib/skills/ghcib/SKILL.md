---
name: ghcib
description: Check GHCi build status using the ghcib daemon. Use when asked to check the build, see compiler errors/warnings, or run ghcib.
user-invocable: true
allowed-tools: Bash(ghcib *)
---

# Using ghcib to Check Build Status

ghcib is a daemon-based GHCi build monitor. It exposes build state over a Unix socket and outputs human-readable text by default, or JSON with `--json` for tool integration.

## Commands

- `ghcib start` — start the daemon (no-op if already running)
- `ghcib stop` — stop the daemon
- `ghcib status` — print current build state as text (auto-starts daemon if not running)
- `ghcib status --wait` — same, but blocks until the current build cycle finishes
- `ghcib status --json` — output full build state as JSON
- `ghcib status --wait --json` — wait then output JSON
- `ghcib status --verbose` / `-v` — print full GHC message body under each diagnostic
- `ghcib source MODULE...` — print Haskell source for one or more installed modules (e.g. `ghcib source Data.Map.Strict`)
- `ghcib watch` — auto-refreshing terminal display (for humans)

## Checking Build Status

Run `ghcib status --wait` after making edits. The `--wait` flag ensures you get the result of the build triggered by your changes, not a stale one.

### Text output (default)

One line per diagnostic, followed by a summary:

```
E src/Foo/Bar.hs:42 `something` not in scope
W src/Foo/Bar.hs:10 redundant import
2 error(s), 1 warning(s) (71 modules, 1.2s)
```

Format: `<E|W> <file>:<line> <title>`

A clean build prints:

```
All good. (71 modules, 17.3s)
```

If test suites are configured, their results follow the build summary:

```
All good. (71 modules, 17.3s)
test:my-test  passed
test:other-test  failed
```

With `--wait`, if a build is in progress `Building...` is printed immediately before blocking.

With `--verbose`, the full GHC message body is printed under each diagnostic:

```
E src/Foo/Bar.hs:42 `something` not in scope
Variable not in scope: something
    suggested fix: ...
1 error(s), 0 warning(s) (71 modules, 1.2s)
```

**Exit code**: 1 when any errors are present or any test suite fails, 0 otherwise (warnings alone → 0).

### JSON output (`--json`)

Use `--json` when you need structured data for further processing:

```json
{
  "buildId": 3,
  "phase": {
    "tag": "Done",
    "contents": {
      "completedAt": "2026-03-30T12:00:00Z",
      "durationMs": 420,
      "moduleCount": 42,
      "diagnostics": [...]
    }
  },
  "daemonInfo": { "targets": [], "watchDirs": [...], "sockPath": "...", "logFile": null }
}
```

Each diagnostic in `diagnostics`:

```json
{
  "severity": "error",
  "file": "src/Foo.hs",
  "line": 42,
  "col": 5,
  "endLine": 42,
  "endCol": 20,
  "title": "Variable not in scope: foo",
  "text": "Variable not in scope: foo\n    ...\n"
}
```

- `title` is the short summary (first line of the GHC message)
- `text` contains the full GHC message body

## Workflow

1. Edit source files
2. Run `ghcib status --wait` — blocks until ghcib finishes recompiling
3. If errors are shown, fix them and repeat
4. `All good.` means the build is clean

## Notes

- The daemon is per-project, scoped by the current working directory
- `ghcib status` auto-starts the daemon if it isn't running
- Use `--json` only when you need to parse the full build state; the default text output is sufficient for most workflows
