# canvas

A generic web-server starter built on the [atelier](https://hackage.haskell.org/package/atelier-core) toolkit:
[Effectful](https://hackage.haskell.org/package/effectful) effects, a WAI/Warp HTTP server, and
rel8/hasql Postgres access — packaged with [haskell.nix](https://input-output-hk.github.io/haskell.nix/).

> The name `canvas` is a placeholder. To rename, grep-and-replace `canvas`/`Canvas`
> across the repo (package name, module prefix, schema name, `config/*.yaml`, `sqitch.conf`).

## Layout

```
canvas/              -- the cabal package (library + executable + test)
  package.yaml       -- hpack source for canvas.cabal
  src/Canvas/        -- library
  app/Main.hs        -- the `canvas` web-server executable
  test/              -- tasty test suite (tasty-discover)
config/              -- per-environment YAML config (dev, ci)
db/                  -- sqitch migrations (deploy / revert / verify)
nix/                 -- haskell.nix project, dev shell, dev-postgres app
```

`canvas.cabal` is generated from `canvas/package.yaml` via
[`hpack`](https://github.com/sol/hpack). Edit `package.yaml`, not the `.cabal`.

## Develop

```bash
# Enter the dev shell (cabal, HLS, ghcid, postgres client, sqitch, …)
nix develop          # or `direnv allow` to load it automatically

# Run development tool (incrementally build + test on a loop)
tricorder ui
```

## Database

```bash
# Start a local dev Postgres (TCP localhost, data under ./data/postgres)
nix run .#postgres

# In another shell, apply migrations
sqitch deploy dev
```

## Run

```bash
# Uses config/dev.yaml by default; override with --config path
cabal run canvas
cabal run canvas -- --config config/dev.yaml
# or the built binary:
nix run .#canvas
```

Endpoints: `GET /` (liveness), `GET /health`, `GET /metrics` (Prometheus),
`GET /items` (JSON list from the database).
