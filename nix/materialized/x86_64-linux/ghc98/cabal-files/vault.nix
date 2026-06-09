{ system
  , compiler
  , flags
  , pkgs
  , hsPkgs
  , pkgconfPkgs
  , errorHandler
  , config
  , ... }:
  ({
    flags = { useghc = true; };
    package = {
      specVersion = "3.4";
      identifier = { name = "vault"; version = "0.3.1.6"; };
      license = "BSD-3-Clause";
      copyright = "(c) Heinrich Apfelmus 2011-2026";
      maintainer = "Heinrich Apfelmus <apfelmus at quantentunnel de>";
      author = "Heinrich Apfelmus, Elliott Hird";
      homepage = "https://github.com/HeinrichApfelmus/vault";
      url = "";
      synopsis = "a persistent store for values of arbitrary types";
      description = "A /vault/ is a persistent store for values of arbitrary types.\nIt's like having first-class access to the storage space behind IORefs.\n.\nThe data structure is analogous to a bank vault,\nwhere you can access different bank boxes with different keys;\nhence the name.\n.\nAlso provided is a /locker/ type, representing a store for a single element.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
          (hsPkgs."hashable" or (errorHandler.buildDepError "hashable"))
          (hsPkgs."unordered-containers" or (errorHandler.buildDepError "unordered-containers"))
        ] ++ pkgs.lib.optional (compiler.isMhs && true) (hsPkgs."unordered-containers" or (errorHandler.buildDepError "unordered-containers"));
        buildable = true;
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/vault-0.3.1.6.tar.gz";
      sha256 = "37a4b169bf95120193c03c1039d0cdc21a7c44382281c8c4cff4f861b1d09766";
    });
  }) // {
    package-description-override = "cabal-version:      3.4\nname:               vault\nversion:            0.3.1.6\nsynopsis:           a persistent store for values of arbitrary types\ndescription:\n  A /vault/ is a persistent store for values of arbitrary types.\n  It's like having first-class access to the storage space behind IORefs.\n  .\n  The data structure is analogous to a bank vault,\n  where you can access different bank boxes with different keys;\n  hence the name.\n  .\n  Also provided is a /locker/ type, representing a store for a single element.\n\ncategory:           Data\nlicense:            BSD-3-Clause\nlicense-file:       LICENSE\nauthor:             Heinrich Apfelmus, Elliott Hird\nmaintainer:         Heinrich Apfelmus <apfelmus at quantentunnel de>\nhomepage:           https://github.com/HeinrichApfelmus/vault\ncopyright:          (c) Heinrich Apfelmus 2011-2026\ntested-with:\n  GHC ==8.4.4\n   || ==8.6.5\n   || ==8.8.4\n   || ==8.10.7\n   || ==9.0.2\n   || ==9.2.8\n   || ==9.4.8\n   || ==9.6.7\n   || ==9.8.4\n   || ==9.10.2\n   || ==9.12.2\n\nextra-source-files:\n  src/Data/Vault/IO.h\n  src/Data/Vault/ST/backends/GHC.h\n  src/Data/Vault/ST/backends/IORef.hs\n  src/Data/Vault/ST/ST.h\nextra-doc-files:\n  CHANGELOG.md\n  README.md\n\nsource-repository head\n  type:     git\n  location: https://github.com/HeinrichApfelmus/vault.git\n\nflag UseGHC\n  description: Use GHC-specific packages and extensions.\n  default:     True\n\nlibrary\n  default-language:   Haskell2010\n  default-extensions: CPP\n  build-depends:\n    , base                  >=4.11    && <4.23\n    , containers            >=0.5     && <0.9\n    , hashable              >=1.1.2.5 && <1.6\n    , unordered-containers  >=0.2.3.0 && <0.3\n\n  ghc-options:        -Wall -fno-warn-missing-signatures\n  hs-source-dirs:     src\n  exposed-modules:\n    Data.Unique.Really\n    Data.Vault.Lazy\n    Data.Vault.ST.Lazy\n    Data.Vault.ST.Strict\n    Data.Vault.Strict\n\n  if (impl(ghc) && flag(useghc))\n    cpp-options: -DUseGHC\n\n  if impl(mhs)\n    build-depends:\n      , unordered-containers >= 0.2.21\n";
  }