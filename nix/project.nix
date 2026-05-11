{
  inputs,
  pkgs,
  compiler-nix-name,
  self,
}:
pkgs.haskell-nix.cabalProject' {
  src = ../.;
  inherit compiler-nix-name;

  # Enable materialization for deterministic builds and better CI caching
  materialized = ./materialized;
  checkMaterialization = true;

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
      # Build Haddock (including hyperlinked source) for all packages
      doHaddock = true;

      packages = {
        # Disable tests for tmp-postgres
        tmp-postgres.doCheck = false;

        # Configure tricorder package
        tricorder = {
          # Treat warnings as errors in Nix builds (CI), but not in local dev
          ghcOptions = [ "-Werror" ];
          # Embed the flake's git revision so the released binary carries the
          # correct hash. Falls back to "unknown" on dirty trees (no shortRev).
          preBuild = ''
            export TRICORDER_VERSION="${self.shortRev or "unknown"}"
          '';
        };
      };
    }
  ];
}
