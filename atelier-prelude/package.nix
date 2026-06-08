let
  inherit (import ../nix/package/dependencies.nix) depList;
  common = import ../nix/package/common.nix;
in
{
  name = "atelier-prelude";
  version = "0.1.0.0";
  synopsis = "Custom relude-based prelude with Effectful conventions";
  description = "A custom prelude based on relude, adapted for Effectful — part of the atelier toolkit.";
  github = "atelier-hub/tricorder";
  homepage = "https://github.com/atelier-hub/tricorder/tree/main/atelier-prelude";
  category = "Prelude";
  extra-doc-files = [
    "CHANGELOG.md"
    "README.md"
  ];

  inherit (common)
    author
    maintainer
    license
    license-file
    language
    default-extensions
    ;

  ghc-options = [
    "-Weverything"
    "-Wno-unsafe"
    "-Wno-missing-safe-haskell-mode"
    "-Wno-monomorphism-restriction"
    "-Wno-missing-kind-signatures"
    "-Wno-missing-poly-kind-signatures"
    "-Wno-missing-role-annotations"
    "-Wno-missing-local-signatures"
    "-Wno-missing-import-lists"
    "-Wno-implicit-prelude"
    "-Wno-unticked-promoted-constructors"
    "-Wno-unused-packages"
    "-Wno-all-missed-specialisations"
    "-Wno-missed-specialisations"
  ];
  library = {
    source-dirs = "src";
    dependencies = depList [
      "base"
      "effectful-core"
      "relude"
    ];
  };
}
