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
      specVersion = "1.22";
      identifier = { name = "crypton-asn1-encoding"; version = "0.10.0"; };
      license = "BSD-3-Clause";
      copyright = "Vincent Hanquez <vincent@snarc.org>";
      maintainer = "Mike Pilgrem <public@pilgrem.com>,\nKazu Yamamoto <kazu@iij.ad.jp>";
      author = "Vincent Hanquez <vincent@snarc.org>";
      homepage = "https://github.com/mpilgrem/crypton-asn1";
      url = "";
      synopsis = "ASN.1 data (raw, BER or DER) readers and writers";
      description = "A library providing readers and writers of data following the Abstract Syntax\nNotation One (ASN.1) standard in raw form or in the high-level forms of Basic\nEncoding Rules (BER) and Distinguished Encoding Rules (DER).";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          (hsPkgs."crypton-asn1-types" or (errorHandler.buildDepError "crypton-asn1-types"))
          (hsPkgs."time-hourglass" or (errorHandler.buildDepError "time-hourglass"))
        ];
        buildable = true;
      };
      tests = {
        "tests-asn1-encoding" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."crypton-asn1-encoding" or (errorHandler.buildDepError "crypton-asn1-encoding"))
            (hsPkgs."crypton-asn1-types" or (errorHandler.buildDepError "crypton-asn1-types"))
            (hsPkgs."tasty" or (errorHandler.buildDepError "tasty"))
            (hsPkgs."tasty-quickcheck" or (errorHandler.buildDepError "tasty-quickcheck"))
            (hsPkgs."time-hourglass" or (errorHandler.buildDepError "time-hourglass"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/crypton-asn1-encoding-0.10.0.tar.gz";
      sha256 = "49813a0ee253f628cb8102dd6857905609b52e490c73c554d7cdf0cbce2926d2";
    });
  }) // {
    package-description-override = "cabal-version: 1.22\r\n\n-- This file has been generated from package.yaml by hpack version 0.38.1.\n--\n-- see: https://github.com/sol/hpack\n\nname:           crypton-asn1-encoding\nversion:        0.10.0\nsynopsis:       ASN.1 data (raw, BER or DER) readers and writers\ndescription:    A library providing readers and writers of data following the Abstract Syntax\n                Notation One (ASN.1) standard in raw form or in the high-level forms of Basic\n                Encoding Rules (BER) and Distinguished Encoding Rules (DER).\ncategory:       Data\nstability:      experimental\nhomepage:       https://github.com/mpilgrem/crypton-asn1\nbug-reports:    https://github.com/mpilgrem/crypton-asn1/issues\nauthor:         Vincent Hanquez <vincent@snarc.org>\nmaintainer:     Mike Pilgrem <public@pilgrem.com>,\n                Kazu Yamamoto <kazu@iij.ad.jp>\ncopyright:      Vincent Hanquez <vincent@snarc.org>\nlicense:        BSD3\nlicense-file:   LICENSE\nbuild-type:     Simple\nextra-doc-files:\n    CHANGELOG.md\n    README.md\n\nsource-repository head\n  type: git\n  location: https://github.com/mpilgrem/crypton-asn1\n  subdir: encoding\n\nlibrary\n  exposed-modules:\n      Data.ASN1.Error\n      Data.ASN1.BinaryEncoding\n      Data.ASN1.BinaryEncoding.Raw\n      Data.ASN1.Encoding\n      Data.ASN1.Prim\n  other-modules:\n      Data.ASN1.BinaryEncoding.Parse\n      Data.ASN1.BinaryEncoding.Writer\n      Data.ASN1.Get\n      Data.ASN1.Internal\n      Data.ASN1.Serialize\n  reexported-modules:\n      Data.ASN1.Stream\n    , Data.ASN1.Types\n  hs-source-dirs:\n      src\n  other-extensions:\n      CPP\n      RankNTypes\n      ViewPatterns\n  ghc-options: -Wall\n  build-depends:\n      base >=4.13 && <5\n    , bytestring\n    , crypton-asn1-types ==0.4.*\n    , time-hourglass <0.4\n  default-language: Haskell2010\n\ntest-suite tests-asn1-encoding\n  type: exitcode-stdio-1.0\n  main-is: Tests.hs\n  other-modules:\n      Data.ASN1.BinaryEncoding\n      Data.ASN1.BinaryEncoding.Parse\n      Data.ASN1.BinaryEncoding.Raw\n      Data.ASN1.BinaryEncoding.Writer\n      Data.ASN1.Encoding\n      Data.ASN1.Error\n      Data.ASN1.Get\n      Data.ASN1.Internal\n      Data.ASN1.Prim\n      Data.ASN1.Serialize\n  hs-source-dirs:\n      tests\n      src\n  other-extensions:\n      CPP\n      RankNTypes\n      ViewPatterns\n  ghc-options: -Wall\n  build-depends:\n      base >=4.13 && <5\n    , bytestring\n    , crypton-asn1-encoding\n    , crypton-asn1-types ==0.4.*\n    , tasty\n    , tasty-quickcheck\n    , time-hourglass <0.4\n  default-language: Haskell2010\n";
  }