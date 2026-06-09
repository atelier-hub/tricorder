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
      identifier = { name = "hspec-hedgehog"; version = "0.3.0.0"; };
      license = "BSD-3-Clause";
      copyright = "2020 Matt Parsons";
      maintainer = "parsonsmatt@gmail.com";
      author = "Matt Parsons";
      homepage = "https://github.com/hspec/hspec-hedgehog#readme";
      url = "";
      synopsis = "Integrate Hedgehog and Hspec!";
      description = "Please see the README on GitHub at <https://github.com/hspec/hspec-hedgehog#readme>";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."QuickCheck" or (errorHandler.buildDepError "QuickCheck"))
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."hedgehog" or (errorHandler.buildDepError "hedgehog"))
          (hsPkgs."hspec" or (errorHandler.buildDepError "hspec"))
          (hsPkgs."hspec-core" or (errorHandler.buildDepError "hspec-core"))
          (hsPkgs."splitmix" or (errorHandler.buildDepError "splitmix"))
        ];
        buildable = true;
      };
      tests = {
        "spec" = {
          depends = [
            (hsPkgs."HUnit" or (errorHandler.buildDepError "HUnit"))
            (hsPkgs."QuickCheck" or (errorHandler.buildDepError "QuickCheck"))
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."hedgehog" or (errorHandler.buildDepError "hedgehog"))
            (hsPkgs."hspec" or (errorHandler.buildDepError "hspec"))
            (hsPkgs."hspec-core" or (errorHandler.buildDepError "hspec-core"))
            (hsPkgs."hspec-hedgehog" or (errorHandler.buildDepError "hspec-hedgehog"))
          ];
          build-tools = [
            (hsPkgs.pkgsBuildBuild.hspec-discover.components.exes.hspec-discover or (pkgs.pkgsBuildBuild.hspec-discover or (errorHandler.buildToolDepError "hspec-discover:hspec-discover")))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/hspec-hedgehog-0.3.0.0.tar.gz";
      sha256 = "fe430fa658fe3aad3608f6ace7e75a29b2cdaa26bdd2edce40b0e1ddb90ca7df";
    });
  }) // {
    package-description-override = "cabal-version: 1.12\n\n-- This file has been generated from package.yaml by hpack version 0.36.0.\n--\n-- see: https://github.com/sol/hpack\n\nname:           hspec-hedgehog\nversion:        0.3.0.0\ndescription:    Please see the README on GitHub at <https://github.com/hspec/hspec-hedgehog#readme>\nsynopsis:       Integrate Hedgehog and Hspec!\ncategory:       Testing\nhomepage:       https://github.com/hspec/hspec-hedgehog#readme\nbug-reports:    https://github.com/hspec/hspec-hedgehog/issues\nauthor:         Matt Parsons\nmaintainer:     parsonsmatt@gmail.com\ncopyright:      2020 Matt Parsons\nlicense:        BSD3\nlicense-file:   LICENSE\nbuild-type:     Simple\nextra-source-files:\n    README.md\n    ChangeLog.md\n\nsource-repository head\n  type: git\n  location: https://github.com/hspec/hspec-hedgehog\n\nlibrary\n  exposed-modules:\n      Test.Hspec.Hedgehog\n  hs-source-dirs:\n      src\n  build-depends:\n      QuickCheck >=2.9.2 && <3\n    , base >=4.7 && <5\n    , hedgehog >=1.5\n    , hspec >=2.11.0 && <3\n    , hspec-core >=2.11.0 && <3\n    , splitmix >=0.0.1 && <1\n  default-language: Haskell2010\n\ntest-suite spec\n  type: exitcode-stdio-1.0\n  main-is: Spec.hs\n  other-modules:\n      ExampleSpec\n      Test.Hspec.HedgehogSpec\n  hs-source-dirs:\n      test\n  build-tool-depends:\n      hspec-discover:hspec-discover\n  build-depends:\n      HUnit\n    , QuickCheck\n    , base >=4.7 && <5\n    , hedgehog >=1.5\n    , hspec >=2.11.0 && <3\n    , hspec-core >=2.11.0 && <3\n    , hspec-hedgehog\n  default-language: Haskell2010\n";
  }