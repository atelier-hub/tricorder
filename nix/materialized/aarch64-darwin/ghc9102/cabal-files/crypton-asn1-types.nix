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
      identifier = { name = "crypton-asn1-types"; version = "0.4.1"; };
      license = "BSD-3-Clause";
      copyright = "Vincent Hanquez <vincent@snarc.org>";
      maintainer = "Mike Pilgrem <public@pilgrem.com>,\nKazu Yamamoto <kazu@iij.ad.jp>";
      author = "Vincent Hanquez <vincent@snarc.org>";
      homepage = "http://github.com/mpilgrem/crypton-asn1";
      url = "";
      synopsis = "ASN.1 types";
      description = "A library providing types representing the Abstract Syntax Notation One\n(ASN.1) standard.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."base16" or (errorHandler.buildDepError "base16"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          (hsPkgs."time-hourglass" or (errorHandler.buildDepError "time-hourglass"))
        ];
        buildable = true;
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/crypton-asn1-types-0.4.1.tar.gz";
      sha256 = "61efc63877a0d3ddb992a793839d9427c1597e095a6e1f63c04e05fd3e4e302d";
    });
  }) // {
    package-description-override = "cabal-version: 1.18\r\n\n-- This file has been generated from package.yaml by hpack version 0.38.1.\n--\n-- see: https://github.com/sol/hpack\n\nname:           crypton-asn1-types\nversion:        0.4.1\nsynopsis:       ASN.1 types\ndescription:    A library providing types representing the Abstract Syntax Notation One\n                (ASN.1) standard.\ncategory:       Data\nstability:      experimental\nhomepage:       http://github.com/mpilgrem/crypton-asn1\nbug-reports:    https://github.com/mpilgrem/crypton-asn1/issues\nauthor:         Vincent Hanquez <vincent@snarc.org>\nmaintainer:     Mike Pilgrem <public@pilgrem.com>,\n                Kazu Yamamoto <kazu@iij.ad.jp>\ncopyright:      Vincent Hanquez <vincent@snarc.org>\nlicense:        BSD3\nlicense-file:   LICENSE\nbuild-type:     Simple\nextra-doc-files:\n    CHANGELOG.md\n    README.md\n\nsource-repository head\n  type: git\n  location: https://github.com/mpilgrem/crypton-asn1\n\nlibrary\n  exposed-modules:\n      Data.ASN1.BitArray\n      Data.ASN1.OID\n      Data.ASN1.Pretty\n      Data.ASN1.Types\n      Data.ASN1.Types.Lowlevel\n      Data.ASN1.Types.String\n      Data.ASN1.Stream\n  hs-source-dirs:\n      src\n  other-extensions:\n      CPP\n  ghc-options: -Wall\n  build-depends:\n      base >=3 && <5\n    , base16\n    , bytestring\n    , time-hourglass <0.4\n  default-language: Haskell98\n";
  }