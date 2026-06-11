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
      identifier = { name = "crypton-asn1-parse"; version = "0.10.0"; };
      license = "BSD-3-Clause";
      copyright = "Vincent Hanquez <vincent@snarc.org>";
      maintainer = "Mike Pilgrem <public@pilgrem.com>,\nKazu Yamamoto <kazu@iij.ad.jp>";
      author = "Vincent Hanquez <vincent@snarc.org>";
      homepage = "https://github.com/mpilgrem/crypton-asn1";
      url = "";
      synopsis = "A monadic parser combinator for a ASN.1 stream.";
      description = "A library providing a monadic parser combinator for use with a stream of\nAbstract Syntax Notation One (ASN.1) standard values.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          (hsPkgs."crypton-asn1-types" or (errorHandler.buildDepError "crypton-asn1-types"))
        ];
        buildable = true;
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/crypton-asn1-parse-0.10.0.tar.gz";
      sha256 = "35c0f278d8fcb720b4ad89c2a7f256f7fb098b9f71a0aeb493a4c3c0fe7728d9";
    });
  }) // {
    package-description-override = "cabal-version: 1.22\r\n\r\n-- This file has been generated from package.yaml by hpack version 0.38.1.\r\n--\r\n-- see: https://github.com/sol/hpack\r\n\r\nname:           crypton-asn1-parse\r\nversion:        0.10.0\r\nsynopsis:       A monadic parser combinator for a ASN.1 stream.\r\ndescription:    A library providing a monadic parser combinator for use with a stream of\r\n                Abstract Syntax Notation One (ASN.1) standard values.\r\ncategory:       Data\r\nstability:      experimental\r\nhomepage:       https://github.com/mpilgrem/crypton-asn1\r\nbug-reports:    https://github.com/mpilgrem/crypton-asn1/issues\r\nauthor:         Vincent Hanquez <vincent@snarc.org>\r\nmaintainer:     Mike Pilgrem <public@pilgrem.com>,\r\n                Kazu Yamamoto <kazu@iij.ad.jp>\r\ncopyright:      Vincent Hanquez <vincent@snarc.org>\r\nlicense:        BSD3\r\nlicense-file:   LICENSE\r\nbuild-type:     Simple\r\nextra-doc-files:\r\n    CHANGELOG.md\r\n    README.md\r\n\r\nsource-repository head\r\n  type: git\r\n  location: https://github.com/mpilgrem/crypton-asn1\r\n  subdir: parse\r\n\r\nlibrary\r\n  exposed-modules:\r\n      Data.ASN1.Parse\r\n  reexported-modules:\r\n      Data.ASN1.Types\r\n  hs-source-dirs:\r\n      src\r\n  other-extensions:\r\n      LambdaCase\r\n  ghc-options: -Wall\r\n  build-depends:\r\n      base >=4.13 && <5\r\n    , bytestring\r\n    , crypton-asn1-types ==0.4.*\r\n  default-language: Haskell98\r\n";
  }