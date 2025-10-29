{
  inputs,
  pkgs,
  project,
  system,
  gitHooks,
}:
let
  inherit (project.args) compiler-nix-name;

  # System tools not tied to GHC version
  systemTools = with pkgs; [
    hpack
    nixfmt-rfc-style
    postgresql
    pre-commit
    sqitchPg
    sops # secret encryption/decryption
    age # encryption tool for sops
  ];
in
project.shellFor {
  name = "hoard-shell-${compiler-nix-name}";

  # Include your local packages
  packages = ps: [ ps.hoard ];

  # Enable Hoogle documentation
  withHoogle = true;

  # All tools for the shell
  tools = {
    cabal = "latest";
    fourmolu = "latest";
    ghcid = "latest";
    haskell-language-server = "latest";
    hlint = "latest";
    tasty-discover = "latest";
    weeder = "latest";
  };

  buildInputs = systemTools;

  shellHook = ''
    # Git hooks integration
    ${gitHooks.shellHook}

    # PostgreSQL configuration
    export PGHOST="$PWD/postgres-data"
    echo "PostgreSQL socket directory: $PGHOST"
  '';
}
