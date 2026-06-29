{
  inputs,
  pkgs,
  compiler-nix-name,
  self,
}:
pkgs.haskell-nix.cabalProject' {
  src = ../.;
  inherit compiler-nix-name;

  # tmp-postgres is not on Hackage; pull it from the flake input for tests.
  cabalProjectLocal = ''
    source-repository-package
      type: git
      location: https://github.com/jfischoff/tmp-postgres
      tag: ${inputs.tmp-postgres.rev}
      --sha256: 0l1gdx5s8ximgawd3yzfy47pv5pgwqmjqp8hx5rbrq68vr04wkbl
  '';

  modules = [
    {
      doHaddock = true;

      packages = {
        tmp-postgres.doCheck = false;

        # Treat warnings as errors in Nix/CI builds once the code settles. Left
        # off for the initial scaffold so minor warnings don't fail the build.
        # canvas.ghcOptions = [ "-Werror" ];
      };
    }
  ];
}
