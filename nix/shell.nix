{ pkgs, checks }: {
  tools = {
    cabal = { };
    ghcid = { };
    haskell-language-server = { };
    hlint = { };
    tasty-discover = { };
    weeder = { };
  };
  buildInputs = [
    pkgs.nix-hpack
  ]
  ++ builtins.attrValues {
    inherit (pkgs)
      nixfmt
      pre-commit
      tagref
      ;
  };
  shellHook = ''
    ${checks.checks.git-hooks.shellHook}
  '';
}
