# Canvas flake-template verification builds (see nix/template-checks.nix),
# gated to the template's target GHC.
#
# The template targets the repo's default GHC and pins that version, so only
# build these on that compiler — the other matrix rows would add little. On any
# other compiler this evaluates to an empty attrset.
{
  inputs,
  pkgs,
  compiler-nix-name,
}:
let
  common = import ./package/common.nix;
  templateCompiler = "ghc${builtins.replaceStrings [ "." ] [ "" ] common.default-ghc-version}";
in
pkgs.lib.optionalAttrs (compiler-nix-name == templateCompiler) (
  import ./template-checks.nix { inherit inputs pkgs compiler-nix-name; }
)
