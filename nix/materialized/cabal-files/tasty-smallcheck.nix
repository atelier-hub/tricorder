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
      identifier = { name = "tasty-smallcheck"; version = "0.8.2"; };
      license = "MIT";
      copyright = "";
      maintainer = "Roman Cheplyaka <roma@ro-che.info>";
      author = "Roman Cheplyaka <roma@ro-che.info>";
      homepage = "https://github.com/feuerbach/tasty";
      url = "";
      synopsis = "SmallCheck support for the Tasty test framework.";
      description = "SmallCheck support for the Tasty test framework.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."tasty" or (errorHandler.buildDepError "tasty"))
          (hsPkgs."smallcheck" or (errorHandler.buildDepError "smallcheck"))
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."tagged" or (errorHandler.buildDepError "tagged"))
          (hsPkgs."optparse-applicative" or (errorHandler.buildDepError "optparse-applicative"))
        ];
        buildable = true;
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/tasty-smallcheck-0.8.2.tar.gz";
      sha256 = "d5cbd7a2a7100e4afd3aaac01a8fa1b7814fb074d93aeff1b51240b687e54f33";
    });
  }) // {
    package-description-override = "Name:                tasty-smallcheck\r\nVersion:             0.8.2\r\nCabal-Version:       >= 1.10\r\nCategory:            Testing\r\nSynopsis:            SmallCheck support for the Tasty test framework.\r\nDescription:         SmallCheck support for the Tasty test framework.\r\nLicense:             MIT\r\nLicense-File:        LICENSE\r\nAuthor:              Roman Cheplyaka <roma@ro-che.info>\r\nMaintainer:          Roman Cheplyaka <roma@ro-che.info>\r\nHomepage:            https://github.com/feuerbach/tasty\r\nBug-reports:         https://github.com/feuerbach/tasty/issues\r\nBuild-Type:          Simple\r\nextra-source-files:  CHANGELOG.md\r\nx-revision: 1\r\n\r\nSource-repository head\r\n  type:     git\r\n  location: git://github.com/feuerbach/tasty.git\r\n  subdir:   smallcheck\r\n\r\nLibrary\r\n        Exposed-Modules:        Test.Tasty.SmallCheck\r\n\r\n        Build-Depends:          tasty >= 0.8,\r\n                                smallcheck >= 1.0,\r\n                                base >= 4.8 && < 5,\r\n                                tagged,\r\n                                optparse-applicative\r\n        ghc-options: -Wall -fno-warn-orphans\r\n        default-language: Haskell2010\r\n        default-extensions: CPP\r\n";
  }