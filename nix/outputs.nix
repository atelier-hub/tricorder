{
  inputs,
  system,
  self,
  # GHC version to use across all tools and the project
  compiler-nix-name,
}:
let
  project = import ./project.nix {
    inherit
      compiler-nix-name
      inputs
      self
      ;
  };
  shell = import ./shell.nix { inherit pkgs checks; };
  pkgs = import ./pkgs.nix {
    inherit
      system
      inputs
      project
      shell
      ;
  };
  inherit (pkgs) lib;
  flake = pkgs.tricorderProject.flake { };
  checks = import ./checks.nix {
    inherit
      system
      pkgs
      inputs
      compiler-nix-name
      self
      ;
  };
  template = import ./template.nix { inherit inputs pkgs compiler-nix-name; };
  docs = import ./docs.nix { inherit flake; };
  sdists = import ./sdists.nix { inherit pkgs; };
  apps = import ./apps.nix { inherit pkgs compiler-nix-name flake; };
in
builtins.foldl' lib.recursiveUpdate { } [
  flake
  docs
  sdists
  checks
  template
  apps
  {
    legacyPackages = pkgs;
    packages = {
      default = self.packages.${system}.tricorder;
      tricorder = flake.packages."tricorder:exe:tricorder";
      tricorder-mcp = flake.packages."tricorder-mcp:exe:tricorder-mcp";
      inherit (pkgs) nix-hpack;
      sdists = pkgs.symlinkJoin {
        name = "sdists";
        paths = builtins.attrValues sdists.packages;
      };
    };

    overlays = [
      (final: _: {
        tricorder = self.packages.${final.stdenv.hostPlatform.system}.tricorder;
      })
    ];
  }
]
