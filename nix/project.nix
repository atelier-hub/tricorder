{ inputs, pkgs }:
let
  # GHC version to use
  compiler-nix-name = "ghc966";
in
pkgs.haskell-nix.cabalProject' {
  src = ../.;
  inherit compiler-nix-name;

  # Enable materialization for deterministic builds and better CI caching
  materialized = ./materialized;
  checkMaterialization = true;

  # Enable CHaP (Cardano Haskell Packages) repository
  inputMap = {
    "https://chap.intersectmbo.org/" = inputs.CHaP;
  };

  # Add tmp-postgres from flake input
  cabalProjectLocal = ''
    source-repository-package
      type: git
      location: https://github.com/jfischoff/tmp-postgres
      tag: ${inputs.tmp-postgres.rev}
      --sha256: 0l1gdx5s8ximgawd3yzfy47pv5pgwqmjqp8hx5rbrq68vr04wkbl
  '';

  # Package-specific configuration
  modules = [
    {
      packages = {
        # Disable tests for tmp-postgres
        tmp-postgres.doCheck = false;

        # Configure hoard package
        hoard = {
          # Treat warnings as errors in Nix builds (CI), but not in local dev
          ghcOptions = [ "-Werror" ];

          # Configure test suite component
          components.tests.hoard-test = {
            # Add build-time tools needed for tests
            build-tools = [
              pkgs.postgresql
              pkgs.sqitchPg
            ];

            # Set HOME for initdb in tests
            preCheck = ''
              export HOME="$TMPDIR"
            '';
          };
        };
      };
    }
  ];
}
