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
      specVersion = "1.12";
      identifier = { name = "hspec"; version = "2.11.17"; };
      license = "MIT";
      copyright = "(c) 2011-2026 Simon Hengel,\n(c) 2011-2012 Trystan Spangler,\n(c) 2011 Greg Weber";
      maintainer = "Simon Hengel <sol@typeful.net>";
      author = "Simon Hengel <sol@typeful.net>";
      homepage = "https://hspec.github.io/";
      url = "";
      synopsis = "A Testing Framework for Haskell";
      description = "Hspec is a testing framework for Haskell.  Some of Hspec's distinctive\nfeatures are:\n\n* a friendly DSL for defining tests\n\n* integration with QuickCheck, SmallCheck, and HUnit\n\n* parallel test execution\n\n* automatic discovery of test files\n\nThe Hspec Manual is at <https://hspec.github.io/>.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."QuickCheck" or (errorHandler.buildDepError "QuickCheck"))
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."hspec-core" or (errorHandler.buildDepError "hspec-core"))
          (hsPkgs."hspec-discover" or (errorHandler.buildDepError "hspec-discover"))
          (hsPkgs."hspec-expectations" or (errorHandler.buildDepError "hspec-expectations"))
        ];
        buildable = true;
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/hspec-2.11.17.tar.gz";
      sha256 = "39e4c8c3bb2be08a4c61747ddff0365c6a07efc6185b3a80a7b88fbb6bec9756";
    });
  }) // {
    package-description-override = "cabal-version: 1.12\n\n-- This file has been generated from package.yaml by hpack version 0.39.1.\n--\n-- see: https://github.com/sol/hpack\n\nname:             hspec\nversion:          2.11.17\nlicense:          MIT\nlicense-file:     LICENSE\ncopyright:        (c) 2011-2026 Simon Hengel,\n                  (c) 2011-2012 Trystan Spangler,\n                  (c) 2011 Greg Weber\nmaintainer:       Simon Hengel <sol@typeful.net>\nbuild-type:       Simple\ncategory:         Testing\nstability:        experimental\nbug-reports:      https://github.com/hspec/hspec/issues\nauthor:           Simon Hengel <sol@typeful.net>\nhomepage:         https://hspec.github.io/\nsynopsis:         A Testing Framework for Haskell\ndescription:      Hspec is a testing framework for Haskell.  Some of Hspec's distinctive\n                  features are:\n                  .\n                  * a friendly DSL for defining tests\n                  .\n                  * integration with QuickCheck, SmallCheck, and HUnit\n                  .\n                  * parallel test execution\n                  .\n                  * automatic discovery of test files\n                  .\n                  The Hspec Manual is at <https://hspec.github.io/>.\nextra-source-files:\n    version.yaml\n    CHANGES.markdown\n\nsource-repository head\n  type: git\n  location: https://github.com/hspec/hspec\n\nlibrary\n  ghc-options: -Wall\n  hs-source-dirs:\n      src\n  build-depends:\n      QuickCheck >=2.12\n    , base ==4.*\n    , hspec-core ==2.11.17\n    , hspec-discover ==2.11.17\n    , hspec-expectations ==0.8.4.*\n  exposed-modules:\n      Test.Hspec\n      Test.Hspec.Discover\n      Test.Hspec.Formatters\n      Test.Hspec.QuickCheck\n      Test.Hspec.Runner\n  other-modules:\n      Paths_hspec\n  default-language: Haskell2010\n  if impl(ghc)\n    cpp-options: -DENABLE_SPEC_HOOK_ARGS\n";
  }