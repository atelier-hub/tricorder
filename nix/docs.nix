{ flake }:
let
  common = import ./package/common.nix;
  mkDocs =
    package:
    let
      pkg =
        flake.packages."${package}:lib:${package}" or flake.packages."${package}:lib:${package}-internal";
    in
    pkg.passthru.haddock.doc;
  packages = builtins.listToAttrs (
    map (name: {
      name = "${name}-docs";
      value = mkDocs name;
    }) common.packageNames
  );
in
{
  inherit packages;
}
