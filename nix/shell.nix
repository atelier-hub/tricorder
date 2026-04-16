{
  pkgs,
  project,
  gitHooks,
  tools,
}:
let
  inherit (project.args) compiler-nix-name;

  # System tools not tied to GHC version
  systemTools =
    builtins.attrValues tools
    ++ (with pkgs; [
      nixfmt-rfc-style
      postgresql
      pre-commit
    ]);
in
project.shellFor {
  name = "tricorder-shell-${compiler-nix-name}";

  # Include local packages
  packages = ps: [ ps.atelier ];

  # Enable Hoogle documentation
  withHoogle = true;

  buildInputs = systemTools;

  tools = {
    cabal = "latest";
    haskell-language-server = "latest";
    ghcid = "latest";
    tasty-discover = "latest";
    weeder = "latest";
  };

  shellHook = ''
    # Git hooks integration
    ${gitHooks.shellHook}
  '';
}
