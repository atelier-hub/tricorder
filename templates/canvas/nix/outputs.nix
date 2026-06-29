{
  inputs,
  system,
  self,
  # GHC version to use across all tools and the project
  compiler-nix-name,
}:
let
  pkgs = import ./pkgs.nix { inherit inputs system; };

  project = import ./project.nix {
    inherit
      inputs
      pkgs
      compiler-nix-name
      self
      ;
  };

  projectFlake = project.flake { };

  # Tools used by git-hooks and the dev shell.
  tools = {
    inherit (pkgs) fourmolu hlint hpack;
    nixfmt = pkgs.nixfmt-rfc-style;
  };

  inherit (pkgs) lib;

  # The cabal executable is named `canvas`, so it can be consumed directly.
  canvas = projectFlake.packages."canvas:exe:canvas";

  postgres = import ./postgres.nix { inherit pkgs; };

  # Regenerate canvas.cabal from canvas/package.yaml using hpack (a plain Haskell
  # tool — no nix needed; this hook just runs it for you in the dev shell).
  hpackHook = pkgs.writeShellScript "hpack-hook" ''
    cd "$(git rev-parse --show-toplevel)/canvas" && ${tools.hpack}/bin/hpack
  '';

  gitHooks = inputs.git-hooks.lib.${system}.run {
    src = ../.;
    hooks = {
      fourmolu = {
        enable = true;
        package = tools.fourmolu;
      };
      hlint = {
        enable = true;
        package = tools.hlint;
      };
      nixfmt = {
        enable = true;
        package = tools.nixfmt;
      };
      hpack = {
        enable = true;
        entry = "${hpackHook}";
        files = "((^|/)package\\.yaml$)|(\\.l?hs(-boot)?$)";
        pass_filenames = false;
      };
    };
  };

  checks = projectFlake.checks // {
    git-hooks = gitHooks;
    canvas = canvas;
  };
in
{
  packages = projectFlake.packages // {
    default = canvas;
    canvas = canvas;
  };

  devShells.default = import ./shell.nix {
    inherit
      pkgs
      project
      gitHooks
      tools
      ;
  };

  apps = postgres // {
    canvas = {
      type = "app";
      program = "${canvas}/bin/canvas";
    };

    weeder = {
      type = "app";
      program = "${pkgs.writeShellScript "weeder-app" ''
        echo "Building project with HIE files..."
        ${pkgs.cabal-install}/bin/cabal build --ghc-options=-fwrite-ide-info
        echo "Running weeder to detect unused code..."
        ${pkgs.haskell-nix.tool compiler-nix-name "weeder" "latest"}/bin/weeder
      ''}";
    };
  };

  legacyChecks.${compiler-nix-name} = {
    all = pkgs.symlinkJoin {
      name = "all-checks-${compiler-nix-name}";
      paths = builtins.attrValues checks;
    };
  };

  inherit checks;
}
