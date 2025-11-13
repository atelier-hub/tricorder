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
      specVersion = "1.10";
      identifier = { name = "tasty-quickcheck"; version = "0.11.1"; };
      license = "MIT";
      copyright = "";
      maintainer = "Roman Cheplyaka <roma@ro-che.info>";
      author = "Roman Cheplyaka <roma@ro-che.info>";
      homepage = "https://github.com/UnkindPartition/tasty";
      url = "";
      synopsis = "QuickCheck support for the Tasty test framework.";
      description = "QuickCheck support for the Tasty test framework.\n";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."tagged" or (errorHandler.buildDepError "tagged"))
          (hsPkgs."tasty" or (errorHandler.buildDepError "tasty"))
          (hsPkgs."random" or (errorHandler.buildDepError "random"))
          (hsPkgs."QuickCheck" or (errorHandler.buildDepError "QuickCheck"))
          (hsPkgs."optparse-applicative" or (errorHandler.buildDepError "optparse-applicative"))
        ];
        buildable = true;
      };
      tests = {
        "test" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."regex-tdfa" or (errorHandler.buildDepError "regex-tdfa"))
            (hsPkgs."tasty" or (errorHandler.buildDepError "tasty"))
            (hsPkgs."tasty-quickcheck" or (errorHandler.buildDepError "tasty-quickcheck"))
            (hsPkgs."tasty-hunit" or (errorHandler.buildDepError "tasty-hunit"))
            (hsPkgs."QuickCheck" or (errorHandler.buildDepError "QuickCheck"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/tasty-quickcheck-0.11.1.tar.gz";
      sha256 = "e3d4de7455ed342f8874d84686def897b8a316ce198461da18106d8a1f63246a";
    });
  }) // {
    package-description-override = "name:                tasty-quickcheck\r\nversion:             0.11.1\r\nx-revision: 4\r\nsynopsis:            QuickCheck support for the Tasty test framework.\r\ndescription:         QuickCheck support for the Tasty test framework.\r\n                     .\r\nlicense:             MIT\r\nlicense-file:        LICENSE\r\nauthor:              Roman Cheplyaka <roma@ro-che.info>\r\nmaintainer:          Roman Cheplyaka <roma@ro-che.info>\r\nhomepage:            https://github.com/UnkindPartition/tasty\r\nbug-reports:         https://github.com/UnkindPartition/tasty/issues\r\ncategory:            Testing\r\nbuild-type:          Simple\r\nextra-source-files:  CHANGELOG.md\r\ncabal-version:       >=1.10\r\n\r\nSource-repository head\r\n  type:     git\r\n  location: https://github.com/UnkindPartition/tasty.git\r\n  subdir:   quickcheck\r\n\r\nlibrary\r\n  exposed-modules:     Test.Tasty.QuickCheck\r\n  other-extensions:    GeneralizedNewtypeDeriving, DeriveDataTypeable\r\n  build-depends:       base >= 4.9 && < 5,\r\n                       tagged < 0.9,\r\n                       tasty >= 1.5.1 && < 1.6,\r\n                       random < 1.4,\r\n                       QuickCheck >= 2.10 && < 2.18,\r\n                       optparse-applicative < 0.20\r\n\r\n  default-language:    Haskell2010\r\n  default-extensions: CPP\r\n  ghc-options: -Wall\r\n\r\ntest-suite test\r\n  default-language:\r\n    Haskell2010\r\n  default-extensions: CPP\r\n  type:\r\n    exitcode-stdio-1.0\r\n  hs-source-dirs:\r\n    tests\r\n  main-is:\r\n    test.hs\r\n  build-depends:\r\n      base\r\n    , regex-tdfa >= 1.3 && < 1.4\r\n    , tasty\r\n    , tasty-quickcheck\r\n    , tasty-hunit\r\n    , QuickCheck\r\n  ghc-options: -Wall\r\n";
  }