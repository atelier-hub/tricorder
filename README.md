# Atelier

A Haskell library providing foundational infrastructure for effect-based applications.

## Libraries

### `atelier`

Core effects and utilities built on [Effectful](https://github.com/haskell-effectful/effectful):

| Module | Purpose |
|---|---|
| `Atelier.Component` | Structured component lifecycle (`setup → listeners → start`) |
| `Atelier.Config` | Configuration with environment variable overrides |
| `Atelier.Effects.Log` | Structured logging with hierarchical namespaces |
| `Atelier.Effects.Conc` | Thread management via Ki (structured concurrency) |
| `Atelier.Effects.DB` | Relational database access via Rel8/Hasql |
| `Atelier.Effects.Cache` | Caching with singleflight deduplication |
| `Atelier.Effects.Publishing` | Event publishing |
| `Atelier.Effects.Monitoring.*` | OpenTelemetry tracing and Prometheus metrics |

### `atelier-prelude`

Custom prelude based on [relude](https://github.com/kowainik/relude), enforcing Effectful conventions.

### `atelier-testing`

Test utilities for database-backed tests using [tmp-postgres](https://github.com/jfischoff/tmp-postgres).

### `ghcib`

A GHCi-based incremental build daemon. Watches source files, triggers reloads, and exposes build state over a Unix socket. See `ghcib/` for details.

## Using with Nix

> [!TIP]
> Configure the binary cache to avoid building GHC from scratch:
> ```nix
> nix.settings = {
>   extra-substituters = [ "https://atelier.cachix.org" ];
>   extra-trusted-public-keys = [ "atelier.cachix.org-1:rEyd/Z4TiXZbBVuU/lDnKZ/7WtnFTwJ17OKHGcahVUo=" ];
> };
> ```

### Try it out

```bash
nix run --accept-flake-config github:atelier-hub/atelier#ghcib
```

`--accept-flake-config` tells Nix to use the binary caches declared in this flake. Without it, Nix will build the entire Haskell toolchain from source.

### Dev shell

To make `ghcib` available in a project's dev shell without installing it system-wide:

```nix
inputs.ghcib.url = "github:atelier-hub/atelier";

devShells.default = pkgs.mkShell {
  packages = [ inputs.ghcib.packages.${system}.ghcib ];
};
```

### Installing

Add the flake input and apply the overlay:

```nix
inputs.ghcib.url = "github:cgeorgii/atelier";

nixpkgs.overlays = [ inputs.ghcib.overlays.default ];
```

### Home Manager

```nix
imports = [ inputs.ghcib.homeManagerModules.default ];
programs.ghcib.enable = true;
```

### NixOS (without Home Manager)

```nix
imports = [ inputs.ghcib.nixosModules.default ];
programs.ghcib.enable = true;
```

## Development

Enter the dev shell:

```bash
nix develop
```

Build and run tests:

```bash
cabal build all
cabal test all
```

Run the ghcib daemon:

```bash
cabal run ghcib-exe -- start
```
