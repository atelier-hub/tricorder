# Tricorder

`tricorder` aims to empower users developing programs with Haskell and LLM coding agents. It does so by providing operations to surface the right information required at a given stage: documentation, build status, diagnostics, etc.

Like similar tools (`ghcid`, `ghciwatch`), it builds the code continuously on every change, presents diagnostics, and runs the tests afterwards. However, `tricorder` offers other advantages:

- **Designed for humans** - A `tricorder watch` interactive TUI mode that presents stats in real time for developers.
- **Designed for agents** - A `SKILL` is provided to inform agentic usage via the `tricorder` CLI.
- **Background builds** - Building in the background using a daemon allows different clients to query the build state simultaneously without triggering multiple rebuilds. For instance, we ship the `tricorder watch` TUI and the `tricorder status` CLI command that communicate witha single daemon via a socket.
- **Sane defaults** - Running `tricorder start` should Just Work™ for most cabal-based Haskell projects.
  - Daemon restarts automatically when cabal files change
  - If customization is needed it can be provided at different levels via a `.tricorder.yaml` or CLI args.
    - Optional config includes which cabal packages to watch, which exact command to use to enter a GHCi session, etc.
- **Project context** - Tools like `tricorder source Some.Module` will attempt to find and provide the source code for a given dependency from disk, which allows exploring library APIs more easily.
- **Machine-readable output** - Using `tricorder status --json` we can get build information in a format appropriate for programmatic usage.

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
nix run --accept-flake-config github:cgeorgii/tricorder#tricorder
```

`--accept-flake-config` tells Nix to use the binary caches declared in this flake. Without it, Nix will build the entire Haskell toolchain from source.

### Dev shell

To make `tricorder` available in a project's dev shell without installing it system-wide:

```nix
inputs.tricorder.url = "github:cgeorgii/tricorder";

devShells.default = pkgs.mkShell {
  packages = [ inputs.tricorder.packages.${system}.tricorder ];
};
```

### Installing

Add the flake input and apply the overlay:

```nix
inputs.tricorder.url = "github:cgeorgii/tricorder";

nixpkgs.overlays = [ inputs.tricorder.overlays.default ];
```

### Home Manager

```nix
imports = [ inputs.tricorder.homeManagerModules.default ];
programs.tricorder.enable = true;
```

### NixOS (without Home Manager)

```nix
imports = [ inputs.tricorder.nixosModules.default ];
programs.tricorder.enable = true;
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

Run the tricorder daemon:

```bash
cabal run tricorder-exe -- start
```

## Libraries

This repository also contains [Atelier](atelier/README.md), a Haskell library providing foundational infrastructure for effect-based applications (to be extracted into its own repository).
