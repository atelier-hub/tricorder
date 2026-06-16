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
      nixfmt
      postgresql
      pre-commit
    ]);
in
project.shellFor {
  name = "tricorder-shell-${compiler-nix-name}";

  # tricorder is the only first-party package; the atelier libraries come from
  # the pinned atelier source-repository-package and build as dependencies.
  packages = ps: [
    ps.tricorder
  ];

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
