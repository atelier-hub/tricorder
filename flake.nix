{
  description = "Tricorder";

  nixConfig = {
    extra-substituters = [
      "https://cache.iog.io"
      "https://atelier.cachix.org"
    ];
    extra-trusted-public-keys = [
      "hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ="
      "atelier.cachix.org-1:rEyd/Z4TiXZbBVuU/lDnKZ/7WtnFTwJ17OKHGcahVUo="
    ];
    allow-import-from-derivation = true;
  };

  inputs = {
    nixpkgs.follows = "haskell-nix/nixpkgs";
    nixpkgs-nixos-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    haskell-nix = {
      url = "github:input-output-hk/haskell.nix";
      inputs = {
        hackage.follows = "hackage";
      };
    };

    hackage = {
      url = "github:input-output-hk/hackage.nix";
      flake = false;
    };

    flake-utils.url = "github:numtide/flake-utils";

    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    tmp-postgres = {
      url = "github:jfischoff/tmp-postgres";
      flake = false;
    };
  };

  outputs =
    { self, ... }@inputs:
    let
      defaultGhcVersion = "ghc9102";
      ghcVersions = [
        defaultGhcVersion
        "ghc98"
        "ghc912"
        "ghc914"
      ];
      lib = inputs.nixpkgs.lib;
    in
    inputs.flake-utils.lib.eachSystem [ "x86_64-linux" "aarch64-darwin" ] (
      system:
      let
        ghcSets = lib.genAttrs ghcVersions (
          compiler-nix-name:
          import ./nix/outputs.nix {
            inherit
              inputs
              system
              self
              compiler-nix-name
              ;
          }
        );
      in
      ghcSets.${defaultGhcVersion}
      // {
        legacyChecks = lib.mergeAttrsList (
          map ({ legacyChecks, ... }: legacyChecks) (builtins.attrValues ghcSets)
        );
      }
    )
    // {
      overlays = import ./nix/overlays.nix self.packages;
      homeManagerModules.default = import ./nix/home-module.nix;
      nixosModules.default = import ./nix/nixos-module.nix;
    };
}
