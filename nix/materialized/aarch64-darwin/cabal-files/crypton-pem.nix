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
      specVersion = "1.18";
      identifier = { name = "crypton-pem"; version = "0.3.0"; };
      license = "BSD-3-Clause";
      copyright = "Vincent Hanquez <vincent@snarc.org>";
      maintainer = "Mike Pilgrem <public@pilgrem.com>,\nKazu Yamamoto <kazu@iij.ad.jp>";
      author = "Vincent Hanquez <vincent@snarc.org>";
      homepage = "http://github.com/mpilgrem/crypton-pem";
      url = "";
      synopsis = "Privacy Enhanced Mail (PEM) file format reader and writer.";
      description = "A library to read and write files in the Privacy Enhanced Mail (PEM) format.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."base64" or (errorHandler.buildDepError "base64"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          (hsPkgs."deepseq" or (errorHandler.buildDepError "deepseq"))
          (hsPkgs."text" or (errorHandler.buildDepError "text"))
        ];
        buildable = true;
      };
      tests = {
        "test-pem" = {
          depends = [
            (hsPkgs."HUnit" or (errorHandler.buildDepError "HUnit"))
            (hsPkgs."QuickCheck" or (errorHandler.buildDepError "QuickCheck"))
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."crypton-pem" or (errorHandler.buildDepError "crypton-pem"))
            (hsPkgs."test-framework" or (errorHandler.buildDepError "test-framework"))
            (hsPkgs."test-framework-hunit" or (errorHandler.buildDepError "test-framework-hunit"))
            (hsPkgs."test-framework-quickcheck2" or (errorHandler.buildDepError "test-framework-quickcheck2"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/crypton-pem-0.3.0.tar.gz";
      sha256 = "1fadab8cba74c6acd74873f06415b4a2a7c84b16b43425217a7beb0ec5830540";
    });
  }) // {
    package-description-override = "cabal-version: 1.18\r\n\r\n-- This file has been generated from package.yaml by hpack version 0.38.1.\r\n--\r\n-- see: https://github.com/sol/hpack\r\n\r\nname:           crypton-pem\r\nversion:        0.3.0\r\nsynopsis:       Privacy Enhanced Mail (PEM) file format reader and writer.\r\ndescription:    A library to read and write files in the Privacy Enhanced Mail (PEM) format.\r\ncategory:       Data\r\nstability:      experimental\r\nhomepage:       http://github.com/mpilgrem/crypton-pem\r\nbug-reports:    https://github.com/mpilgrem/crypton-pem/issues\r\nauthor:         Vincent Hanquez <vincent@snarc.org>\r\nmaintainer:     Mike Pilgrem <public@pilgrem.com>,\r\n                Kazu Yamamoto <kazu@iij.ad.jp>\r\ncopyright:      Vincent Hanquez <vincent@snarc.org>\r\nlicense:        BSD3\r\nlicense-file:   LICENSE\r\nbuild-type:     Simple\r\nextra-doc-files:\r\n    CHANGELOG.md\r\n    README.md\r\n\r\nsource-repository head\r\n  type: git\r\n  location: https://github.com/mpilgrem/crypton-pem\r\n\r\nlibrary\r\n  exposed-modules:\r\n      Data.PEM\r\n  other-modules:\r\n      Data.PEM.Parser\r\n      Data.PEM.Types\r\n      Data.PEM.Writer\r\n  hs-source-dirs:\r\n      src\r\n  ghc-options: -Wall\r\n  build-depends:\r\n      base >=3 && <5\r\n    , base64 >=0.4.2.2\r\n    , bytestring\r\n    , deepseq\r\n    , text\r\n  default-language: Haskell2010\r\n\r\ntest-suite test-pem\r\n  type: exitcode-stdio-1.0\r\n  main-is: Main.hs\r\n  hs-source-dirs:\r\n      test\r\n  ghc-options: -Wall\r\n  build-depends:\r\n      HUnit\r\n    , QuickCheck >=2.4.0.1\r\n    , base\r\n    , bytestring\r\n    , crypton-pem\r\n    , test-framework >=0.3.3\r\n    , test-framework-hunit\r\n    , test-framework-quickcheck2\r\n  default-language: Haskell2010\r\n";
  }