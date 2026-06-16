{
  inputs,
  pkgs,
  compiler-nix-name,
  self,
}:
let
  nix-hpack = pkgs.callPackage ./package/nix-hpack.nix { };
  # Include the `package.yaml` file for the `haskell-plan-to-nix` step of the
  # build process. When `haskell-plan-to-nix` uses `package.yaml` instead of
  # the raw `.cabal` files, it omits the module paths from the materialized
  # files. By keeping module paths out of our materialized files, we don't have
  # to update materialization for every module we add or remove, only for
  # dependencies.
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

  # Resolve the atelier source-repository-package against the flake input, so the
  # revision tracks flake.lock and no manual --sha256 is required.
  inputMap = {
    "https://github.com/atelier-hub/atelier" = inputs.atelier;
  };

  cabalProjectLocal = ''
    source-repository-package
      type: git
      location: https://github.com/atelier-hub/atelier
      tag: ${inputs.atelier.rev}
      subdir: atelier-prelude atelier-core
  '';

  # Package-specific configuration
  modules = [
    {
      # Build Haddock (including hyperlinked source) for all packages
      doHaddock = true;

      packages = {
        # Treat warnings as errors in Nix builds (CI), but not in local dev.
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
