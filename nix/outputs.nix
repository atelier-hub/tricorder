{
  inputs,
  system,
  self,
}:
let
  # GHC version to use across all tools and the project
  compiler-nix-name = "ghc9102";

  # Initialize package set with haskell.nix
  pkgs = import ./pkgs.nix { inherit inputs system; };

  # Configure haskell.nix project
  project = import ./project.nix {
    inherit
      inputs
      pkgs
      compiler-nix-name
      self
      ;
  };

  # Get the project flake for packages
  projectFlake = project.flake { };

  # Tools and binaries used by git-hooks and in the dev shell
  tools = {
    inherit nix-hpack;
    inherit (pkgs)
      fourmolu
      hlint
      hpack
      nixfmt-rfc-style
      ;
  };
  hpack-dir = pkgs.callPackage "${inputs.git-hooks}/nix/hpack-dir" { inherit (tools) hpack; };

  inherit (pkgs) lib;

  # Observability stack (Prometheus, Grafana, Tempo, Loki, Node Exporter)
  observability = import ./observability {
    inherit pkgs lib;
    config = "config/tricorder.yaml";
  };

  # Custom hook to check materialization is up to date
  checkMaterialization = pkgs.writeShellScript "check-materialization" ''
    # Only check if nix/project.nix or cabal files changed
    if git diff --cached --name-only | grep -qE '(nix/project\.nix|.*\.cabal|cabal\.project|flake\.lock)'; then
      echo "Checking if haskell.nix materialization is up to date..."

      # Try to evaluate the project - this will fail if materialization is stale
      if ! nix eval --no-warn-dirty .#checks.${system}.git-hooks --apply 'x: "ok"' 2>/dev/null >/dev/null; then
        echo "⚠️  WARNING: haskell.nix materialization may be out of date!"
        echo "If you changed dependencies or flake inputs, please run:"
        echo "  nix build --no-link 2>&1 | grep -o '/[/[:alnum:]]\+-generateMaterialized [/_[:alnum:]]\+$' | sh"
        echo ""
        echo "Press Enter to continue anyway, or Ctrl-C to abort and regenerate."
        read -r
      fi
    fi
  '';

  # The cabal executable is named `tricorder`, so it can be consumed directly.
  tricorder = projectFlake.packages."tricorder:exe:tricorder";

  # Git hooks check (defined once, used in both checks and shell)
  gitHooks = inputs.git-hooks.lib.${system}.run {
    src = ../.;
    hooks = lib.pipe tools [
      (x: x // { hpack = hpack-dir; })
      (lib.mapAttrs (
        name: package: {
          inherit package;
          enable = true;
        }
      ))
      # Add custom materialization check and exclude materialized files from nixfmt
      (
        x:
        x
        // {
          check-materialization = {
            enable = true;
            entry = "${checkMaterialization}";
            pass_filenames = false;
          };
          nixfmt-rfc-style = {
            enable = true;
            package = tools.nixfmt-rfc-style;
            excludes = [ "nix/materialized/.*" ];
          };
          nix-hpack = {
            enable = true;
            files = "(^|/)package\\.nix$";
            before = [ "check-materialization" ];
            entry = "${nix-hpack}/bin/nix-hpack";
            pass_filenames = false;
          };
        }
      )
    ];
  };
  nix-hpack = pkgs.callPackage ./package/nix-hpack.nix { inherit (tools) hpack; };
in
{
  # Expose packages built by haskell.nix
  packages = projectFlake.packages // {
    default = tricorder;
    tricorder = tricorder;
    inherit nix-hpack;
  };

  # Development shell
  devShells.default = import ./shell.nix {
    pkgs = pkgs.extend (_: _: { inherit nix-hpack; });
    inherit
      project
      gitHooks
      tools
      ;
  };

  # Custom apps
  apps = observability.apps // {
    tricorder = {
      type = "app";
      program = "${tricorder}/bin/tricorder";
    };

    # Weeder: detects unused code
    weeder = {
      type = "app";
      program = "${pkgs.writeShellScript "weeder-app" ''
        echo "Building project with HIE files..."
        ${pkgs.cabal-install}/bin/cabal build --ghc-options=-fwrite-ide-info
        echo "Running weeder to detect unused code..."
        ${pkgs.haskell-nix.tool compiler-nix-name "weeder" "latest"}/bin/weeder
      ''}";
    };

    # HLint auto-fix
    hlint-fix = {
      type = "app";
      program = "${pkgs.writeShellScript "hlint-fix-app" ''
        echo "Running hlint --refactor on all Haskell files..."
        export PATH="${pkgs.haskell-nix.tool compiler-nix-name "apply-refact" "latest"}/bin:$PATH"
        find atelier-prelude atelier-core atelier-db atelier-testing tricorder -name "*.hs" -exec ${
          pkgs.haskell-nix.tool compiler-nix-name "hlint" "latest"
        }/bin/hlint --refactor --refactor-options="-i" {} \;
        echo "Hlint refactoring complete!"
      ''}";
    };
  };

  # Checks
  checks = projectFlake.checks // {
    git-hooks = gitHooks;
    # Ensure the executable builds in CI
    tricorder = tricorder;
    # Ensure the overlay correctly exposes pkgs.tricorder
    overlay =
      pkgs.runCommand "check-overlay"
        {
          tricorder = (pkgs.extend self.overlays.default).tricorder;
        }
        ''
          test -x $tricorder/bin/tricorder
          touch $out
        '';
  };
}
