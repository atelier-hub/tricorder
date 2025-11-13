{ inputs, system }:
let
  # Initialize package set with haskell.nix
  pkgs = import ./pkgs.nix { inherit inputs system; };

  # Configure haskell.nix project
  project = import ./project.nix { inherit inputs pkgs; };

  # Get the project flake for packages
  projectFlake = project.flake { };

  # Tools and binaries used by git-hooks and in the dev shell
  tools = {
    inherit (pkgs)
      fourmolu
      hlint
      hpack
      nixfmt-rfc-style
      ;
  };
  hpack-dir = pkgs.callPackage "${inputs.git-hooks}/nix/hpack-dir" { inherit (tools) hpack; };

  inherit (pkgs) lib;

  # Custom hook to check materialization is up to date
  checkMaterialization = pkgs.writeShellScript "check-materialization" ''
    # Only check if nix/project.nix or cabal files changed
    if git diff --cached --name-only | grep -qE '(nix/project\.nix|.*\.cabal|cabal\.project|flake\.lock)'; then
      echo "Checking if haskell.nix materialization is up to date..."

      # Try to evaluate the project - this will fail if materialization is stale
      if ! nix eval --no-warn-dirty .#checks.${system}.git-hooks --apply 'x: "ok"' 2>/dev/null >/dev/null; then
        echo "⚠️  WARNING: haskell.nix materialization may be out of date!"
        echo "If you changed dependencies or flake inputs, please run:"
        echo "  nix build --no-link 2>&1 | grep generateMaterialized | sh"
        echo ""
        echo "Press Enter to continue anyway, or Ctrl-C to abort and regenerate."
        read -r
      fi
    fi
  '';

  # Git hooks check (defined once, used in both checks and shell)
  gitHooks = inputs.git-hooks.lib.${system}.run {
    src = ../.;
    hooks = lib.pipe tools [
      (x: x // { hpack = hpack-dir; })
      (lib.mapAttrs (
        _: package: {
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
        }
      )
    ];
  };

  # Import custom app modules
  secretsApps = import ./secrets.nix { inherit pkgs; };
in
{
  # Expose packages built by haskell.nix
  packages = projectFlake.packages // {
    default = projectFlake.packages."hoard:exe:hoard-exe";
  };

  # Development shell
  devShells.default = import ./shell.nix {
    inherit
      pkgs
      project
      gitHooks
      tools
      ;
  };

  # Custom apps
  apps = {
    # Weeder: detects unused code
    weeder = {
      type = "app";
      program = "${pkgs.writeShellScript "weeder-app" ''
        echo "Building project with HIE files..."
        ${pkgs.cabal-install}/bin/cabal build --ghc-options=-fwrite-ide-info
        echo "Running weeder to detect unused code..."
        ${pkgs.haskellPackages.weeder}/bin/weeder
      ''}";
    };

    # HLint auto-fix
    hlint-fix = {
      type = "app";
      program = "${pkgs.writeShellScript "hlint-fix-app" ''
        echo "Running hlint --refactor on all Haskell files..."
        find src app test -name "*.hs" -exec ${pkgs.haskellPackages.hlint}/bin/hlint --refactor {} \;
        echo "Hlint refactoring complete!"
      ''}";
    };
  }
  # Merge in secrets management apps
  // secretsApps
  # Import postgres app from separate module
  // (import ./postgres.nix { inherit pkgs; });

  # Checks
  checks = projectFlake.checks // {
    git-hooks = gitHooks;
  };
}
