{
  inputs,
  pkgs,
  compiler-nix-name,
  self,
}:
let
  nix-hpack = pkgs.callPackage ./package/nix-hpack.nix { };
  src = pkgs.runCommand "src" { } ''
    mkdir -p src
    cp -r ${./..}/* src
    chmod -R +w src
    ls -la src
    (cd src && ${nix-hpack}/bin/nix-hpack --keep)
    mv src $out
  '';
in
pkgs.haskell-nix.cabalProject' {
  inherit src compiler-nix-name;

  # Enable materialization for deterministic builds and better CI caching
  materialized = ./materialized/${pkgs.stdenv.hostPlatform.system}/${compiler-nix-name};
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

        # Treat warnings as errors in Nix builds (CI), but not in local dev.
        # Applied to every first-party package.
        atelier-prelude.ghcOptions = [ "-Werror" ];
        atelier-core.ghcOptions = [ "-Werror" ];
        atelier-db.ghcOptions = [ "-Werror" ];
        atelier-testing.ghcOptions = [ "-Werror" ];

        # Configure tricorder package
        tricorder = {
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
