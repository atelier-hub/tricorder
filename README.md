# Tricorder

A GHCi-based incremental build daemon. Watches source files, triggers reloads, and exposes build state over a Unix socket. See `tricorder/` for details.

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
