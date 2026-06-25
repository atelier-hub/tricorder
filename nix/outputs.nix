{
  inputs,
  system,
  self,
  # GHC version to use across all tools and the project
  compiler-nix-name,
}:
let
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
      nixfmt
      ;
  };
  hpack-dir = pkgs.callPackage "${inputs.git-hooks}/nix/hpack-dir" { inherit (tools) hpack; };

  inherit (pkgs) lib;

  # Observability stack (Prometheus, Grafana, Tempo, Loki, Node Exporter)
  observability = import ./observability {
    inherit pkgs lib;
    config = "config/tricorder.yaml";
  };

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
      (
        x:
        x
        // {
          nixfmt = {
            enable = true;
            package = tools.nixfmt;
          };
          # The upstream hpack-dir hook regenerates *.cabal from package.yaml
          # files, but this project has none on disk — nix-hpack generates them
          # transiently from package.nix and deletes them. It therefore always
          # no-ops and reports "Passed", giving false confidence. Disable it in
          # favour of nix-hpack below.
          hpack = {
            package = hpack-dir;
            enable = false;
          };
          nix-hpack = {
            enable = true;
            # Run whenever anything that feeds .cabal generation changes:
            #   - *.hs / *.lhs / *.hs-boot : hpack auto-discovers modules from the
            #     source tree, so adding/removing one changes the generated .cabal
            #   - *.cabal                  : catches hand-edits — nix-hpack rewrites
            #     the file from package.nix, so the commit fails if a checked-in
            #     .cabal drifted from its source
            #   - package.nix              : the per-package hpack source
            #   - nix/package/*.nix        : shared constraints / common options
            # pre-commit only runs a hook when a *staged* file matches `files`, so
            # the old package.nix-only pattern let direct .cabal edits (and module
            # additions) through locally; CI runs every hook unconditionally and
            # caught them. This widens the local trigger to match CI.
            files = "(\\.l?hs(-boot)?$)|(\\.cabal$)|((^|/)package\\.nix$)|((^|/)nix/package/.*\\.nix$)";
            entry = "${nix-hpack}/bin/nix-hpack";
            pass_filenames = false;
          };
          # Validate tagref cross-references (no dangling refs / duplicate tags).
          tagref = {
            enable = true;
            entry = "${pkgs.tagref}/bin/tagref check";
            pass_filenames = false;
          };
        }
      )
    ];
  };
  nix-hpack = pkgs.callPackage ./package/nix-hpack.nix { inherit (tools) hpack; };

  checks = projectFlake.checks // {
    git-hooks = gitHooks;
    # Ensure the executable builds in CI
    tricorder = tricorder;
    # Ensure the overlay correctly exposes pkgs.tricorder
    overlay =
      pkgs.runCommand "check-overlay"
        {
          tricorder =
            (pkgs.extend (
              (import ./overlays.nix {
                ${pkgs.stdenv.system}.default = tricorder;
              }).default
            )).tricorder;
        }
        ''
          ls -la
          test -x $tricorder/bin/tricorder
          # Ensuring $out is a directory makes this check compatible with
          # symlinkJoin.
          mkdir -p $out
          touch $out/ok
        '';
  };
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

  legacyChecks.${compiler-nix-name} = {
    all = pkgs.symlinkJoin {
      name = "all-checks-${compiler-nix-name}";
      paths = builtins.attrValues checks;
    };
  };

  inherit checks;
}
