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
    flags = {};
    package = {
      specVersion = "2.2";
      identifier = { name = "tasty-hspec"; version = "1.2.0.4"; };
      license = "BSD-3-Clause";
      copyright = "";
      maintainer = "Mitchell Dalvi Rosen <mitchellwrosen@gmail.com>";
      author = "Mitchell Dalvi Rosen";
      homepage = "https://github.com/mitchellwrosen/tasty-hspec";
      url = "";
      synopsis = "Hspec support for the Tasty test framework.";
      description = "This package provides a Tasty provider for Hspec test suites.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."hspec" or (errorHandler.buildDepError "hspec"))
          (hsPkgs."hspec-api" or (errorHandler.buildDepError "hspec-api"))
          (hsPkgs."hspec-core" or (errorHandler.buildDepError "hspec-core"))
          (hsPkgs."QuickCheck" or (errorHandler.buildDepError "QuickCheck"))
          (hsPkgs."tasty" or (errorHandler.buildDepError "tasty"))
          (hsPkgs."tasty-smallcheck" or (errorHandler.buildDepError "tasty-smallcheck"))
          (hsPkgs."tasty-quickcheck" or (errorHandler.buildDepError "tasty-quickcheck"))
        ];
        buildable = true;
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/tasty-hspec-1.2.0.4.tar.gz";
      sha256 = "d1a273cbe653c23422c14e99672f7cd64e07f85bb019f95fef095db8e5b461c2";
    });
  }) // {
    package-description-override = "cabal-version: 2.2\n\nauthor: Mitchell Dalvi Rosen\nbuild-type: Simple\ncategory: Testing\ndescription: This package provides a Tasty provider for Hspec test suites.\nhomepage: https://github.com/mitchellwrosen/tasty-hspec\nlicense-file: LICENSE\nlicense: BSD-3-Clause\nmaintainer: Mitchell Dalvi Rosen <mitchellwrosen@gmail.com>\nname: tasty-hspec\nsynopsis: Hspec support for the Tasty test framework.\ntested-with: GHC == 9.6.5, GHC == 9.8.2, GHC == 9.10.1, GHC == 9.12.1\nversion: 1.2.0.4\nx-revision: 8\n\nextra-doc-files:\n  .gitignore\n  CHANGELOG.md\n  README.md\n\nextra-source-files:\n  examples/example.hs\n\nsource-repository head\n  type:     git\n  location: https://github.com/mitchellwrosen/tasty-hspec.git\n\nlibrary\n  build-depends:\n    base ^>= 4.11 || ^>= 4.12 || ^>= 4.13 || ^>= 4.14 || ^>= 4.15 || ^>= 4.16 || ^>= 4.17 || ^>= 4.18 || ^>= 4.19 || ^>= 4.20 || ^>= 4.21,\n    hspec ^>= 2.11.0,\n    hspec-api ^>= 2.11.0,\n    hspec-core ^>= 2.11.0,\n    QuickCheck ^>= 2.7 || ^>= 2.8 || ^>= 2.9 || ^>= 2.10 || ^>= 2.11 || ^>= 2.12 || ^>= 2.13 || ^>= 2.14 || ^>= 2.15 || ^>= 2.16 || ^>= 2.17,\n    tasty ^>= 1.3 || ^>= 1.4 || ^>= 1.5,\n    tasty-smallcheck >= 0.1 && < 0.9,\n    tasty-quickcheck ^>= 0.9.1 || ^>= 0.10 || ^>= 0.11,\n  default-extensions:\n    LambdaCase\n    ScopedTypeVariables\n  default-language: Haskell2010\n  exposed-modules: Test.Tasty.Hspec\n  ghc-options: -Wall\n  if impl(ghc >= 8.0)\n    ghc-options: -Wcompat\n  hs-source-dirs: src\n";
  }