{
  description = "Cardano Hoarding Node";

  nixConfig = {
    extra-substituters = [
      "https://cache.iog.io"
      "https://cardano-hoarding-node.cachix.org"
    ];
    extra-trusted-public-keys = [
      "hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ="
      "cardano-hoarding-node.cachix.org-1:uHPjxqLDX30tBcYwNZ2orHdFUuADwG3RnBcRL55sa+o="
    ];
    allow-import-from-derivation = true;
  };

  inputs = {
    nixpkgs.follows = "haskell-nix/nixpkgs";

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

    CHaP = {
      url = "github:IntersectMBO/cardano-haskell-packages?ref=repo";
      flake = false;
    };

    iohk-nix = {
      url = "github:input-output-hk/iohk-nix";
      inputs.nixpkgs.follows = "nixpkgs";
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
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs:
    inputs.flake-utils.lib.eachSystem [ "x86_64-linux" ] (
      system:
      import ./nix/outputs.nix {
        inherit inputs system;
      }
    );
}
