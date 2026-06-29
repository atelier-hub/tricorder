{
  pkgs,
  project,
  gitHooks,
  tools,
}:
let
  inherit (project.args) compiler-nix-name;

  systemTools =
    builtins.attrValues tools
    ++ (with pkgs; [
      nixfmt-rfc-style
      postgresql
      pre-commit
      sqitchPg
    ]);
in
project.shellFor {
  name = "canvas-shell-${compiler-nix-name}";

  packages = ps: [
    ps.canvas
  ];

  withHoogle = true;

  buildInputs = systemTools;

  tools = {
    cabal = "latest";
    haskell-language-server = "latest";
    ghcid = "latest";
    weeder = "latest";
    tricorder = "latest";
  };

  shellHook = ''
    ${gitHooks.shellHook}
  '';
}
