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
      identifier = { name = "hspec-expectations"; version = "0.8.4"; };
      license = "MIT";
      copyright = "(c) 2011-2023 Simon Hengel";
      maintainer = "Simon Hengel <sol@typeful.net>";
      author = "Simon Hengel <sol@typeful.net>";
      homepage = "https://github.com/hspec/hspec-expectations#readme";
      url = "";
      synopsis = "Catchy combinators for HUnit";
      description = "Catchy combinators for HUnit: <https://github.com/hspec/hspec-expectations#readme>";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."HUnit" or (errorHandler.buildDepError "HUnit"))
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."call-stack" or (errorHandler.buildDepError "call-stack"))
        ];
        buildable = true;
      };
      tests = {
        "spec" = {
          depends = [
            (hsPkgs."HUnit" or (errorHandler.buildDepError "HUnit"))
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."call-stack" or (errorHandler.buildDepError "call-stack"))
            (hsPkgs."nanospec" or (errorHandler.buildDepError "nanospec"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/hspec-expectations-0.8.4.tar.gz";
      sha256 = "7b8dde7e230ecfda90c95fd80478b244a45e68602fb3dd4a76f4710619be21ff";
    });
  }) // {
    package-description-override = "cabal-version: 1.12\n\n-- This file has been generated from package.yaml by hpack version 0.35.2.\n--\n-- see: https://github.com/sol/hpack\n\nname:             hspec-expectations\nversion:          0.8.4\nx-revision:       2\nsynopsis:         Catchy combinators for HUnit\ndescription:      Catchy combinators for HUnit: <https://github.com/hspec/hspec-expectations#readme>\nbug-reports:      https://github.com/hspec/hspec-expectations/issues\nlicense:          MIT\nlicense-file:     LICENSE\ncopyright:        (c) 2011-2023 Simon Hengel\nauthor:           Simon Hengel <sol@typeful.net>\nmaintainer:       Simon Hengel <sol@typeful.net>\nbuild-type:       Simple\ncategory:         Testing\nhomepage:         https://github.com/hspec/hspec-expectations#readme\n\nsource-repository head\n  type: git\n  location: https://github.com/hspec/hspec-expectations\n\nlibrary\n  hs-source-dirs:\n      src\n  ghc-options: -Wall\n  build-depends:\n      HUnit >=1.5.0.0\n    , base ==4.*\n    , call-stack\n  exposed-modules:\n      Test.Hspec.Expectations\n      Test.Hspec.Expectations.Contrib\n  other-modules:\n      Test.Hspec.Expectations.Matcher\n      Paths_hspec_expectations\n  default-language: Haskell2010\n\ntest-suite spec\n  type: exitcode-stdio-1.0\n  main-is: Spec.hs\n  hs-source-dirs:\n      test\n      src\n  ghc-options: -Wall\n  build-depends:\n      HUnit >=1.5.0.0\n    , base >=4.8\n    , call-stack\n    , nanospec\n  other-modules:\n      Helper\n      Test.Hspec.Expectations.ContribSpec\n      Test.Hspec.Expectations.MatcherSpec\n      Test.Hspec.ExpectationsSpec\n      Test.Hspec.Expectations\n      Test.Hspec.Expectations.Contrib\n      Test.Hspec.Expectations.Matcher\n      Paths_hspec_expectations\n  default-language: Haskell2010\n";
  }