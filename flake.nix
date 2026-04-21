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
    inputs.flake-utils.lib.eachSystem [ "x86_64-linux" ] (
      system:
      import ./nix/outputs.nix {
        inherit inputs system self;
      }
    )
    // {
      overlays.default = final: _: {
        tricorder = self.packages.${final.stdenv.system}.default;
      };

      homeManagerModules.default = import ./nix/home-module.nix;
      nixosModules.default = import ./nix/nixos-module.nix;
    };
}
