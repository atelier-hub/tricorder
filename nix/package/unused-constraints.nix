let
  common = import ./common.nix;
  inherit (import ./dependencies.nix) constraints;

  # Recursively walk an evaluated package.nix value and collect every
  # dependency name that resolves to a `constraints` entry. `depList` already
  # expands constraint-name strings into `{ name = ...; version = ...; }`
  # records, and hand-written entries (e.g. the `base` mixin override) are
  # already records, so matching on `.name` covers both without having to
  # know which fields hold dependency lists.
  collectNames =
    value:
    if builtins.isAttrs value then
      (
        if
          builtins.hasAttr "name" value
          && builtins.isString value.name
          && builtins.hasAttr value.name constraints
        then
          [ value.name ]
        else
          [ ]
      )
      ++ builtins.concatMap collectNames (builtins.attrValues value)
    else if builtins.isList value then
      builtins.concatMap collectNames value
    else
      [ ];

  usedNames = builtins.concatMap (
    packageName: collectNames (import (../../packages + "/${packageName}/package.nix"))
  ) common.packageNames;

  usedSet = builtins.listToAttrs (
    map (n: {
      name = n;
      value = true;
    }) usedNames
  );

  allConstraintNames = builtins.attrNames constraints;
in
builtins.filter (n: !(builtins.hasAttr n usedSet)) allConstraintNames
