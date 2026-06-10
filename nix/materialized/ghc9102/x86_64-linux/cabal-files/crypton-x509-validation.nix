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
      identifier = { name = "crypton-x509-validation"; version = "1.9.1"; };
      license = "BSD-3-Clause";
      copyright = "Vincent Hanquez <vincent@snarc.org>";
      maintainer = "Kazu Yamamoto <kazu@iij.ad.jp>";
      author = "Vincent Hanquez <vincent@snarc.org>";
      homepage = "https://github.com/kazu-yamamoto/crypton-certificate";
      url = "";
      synopsis = "X.509 Certificate and CRL validation";
      description = "X.509 Certificate and CRL validation. please see README";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
          (hsPkgs."crypton" or (errorHandler.buildDepError "crypton"))
          (hsPkgs."crypton-asn1-types" or (errorHandler.buildDepError "crypton-asn1-types"))
          (hsPkgs."crypton-asn1-encoding" or (errorHandler.buildDepError "crypton-asn1-encoding"))
          (hsPkgs."crypton-pem" or (errorHandler.buildDepError "crypton-pem"))
          (hsPkgs."crypton-x509" or (errorHandler.buildDepError "crypton-x509"))
          (hsPkgs."crypton-x509-store" or (errorHandler.buildDepError "crypton-x509-store"))
          (hsPkgs."data-default" or (errorHandler.buildDepError "data-default"))
          (hsPkgs."iproute" or (errorHandler.buildDepError "iproute"))
          (hsPkgs."mtl" or (errorHandler.buildDepError "mtl"))
          (hsPkgs."ram" or (errorHandler.buildDepError "ram"))
          (hsPkgs."time-hourglass" or (errorHandler.buildDepError "time-hourglass"))
        ];
        buildable = true;
      };
      tests = {
        "test-x509-validation" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."crypton" or (errorHandler.buildDepError "crypton"))
            (hsPkgs."crypton-asn1-encoding" or (errorHandler.buildDepError "crypton-asn1-encoding"))
            (hsPkgs."crypton-asn1-types" or (errorHandler.buildDepError "crypton-asn1-types"))
            (hsPkgs."crypton-x509" or (errorHandler.buildDepError "crypton-x509"))
            (hsPkgs."crypton-x509-store" or (errorHandler.buildDepError "crypton-x509-store"))
            (hsPkgs."crypton-x509-validation" or (errorHandler.buildDepError "crypton-x509-validation"))
            (hsPkgs."data-default" or (errorHandler.buildDepError "data-default"))
            (hsPkgs."ram" or (errorHandler.buildDepError "ram"))
            (hsPkgs."tasty" or (errorHandler.buildDepError "tasty"))
            (hsPkgs."tasty-hunit" or (errorHandler.buildDepError "tasty-hunit"))
            (hsPkgs."time-hourglass" or (errorHandler.buildDepError "time-hourglass"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/crypton-x509-validation-1.9.1.tar.gz";
      sha256 = "8fcb83401114c7f694d84c543e8f7f96cea60c543a30a770903741d336eece3d";
    });
  }) // {
    package-description-override = "cabal-version:      >=1.10\r\nname:               crypton-x509-validation\r\nversion:            1.9.1\r\nx-revision: 1\r\nlicense:            BSD3\r\nlicense-file:       LICENSE\r\ncopyright:          Vincent Hanquez <vincent@snarc.org>\r\nmaintainer:         Kazu Yamamoto <kazu@iij.ad.jp>\r\nauthor:             Vincent Hanquez <vincent@snarc.org>\r\nstability:          experimental\r\nhomepage:           https://github.com/kazu-yamamoto/crypton-certificate\r\nsynopsis:           X.509 Certificate and CRL validation\r\ndescription:        X.509 Certificate and CRL validation. please see README\r\ncategory:           Data\r\nbuild-type:         Simple\r\nextra-source-files: ChangeLog.md\r\n\r\nsource-repository head\r\n    type:     git\r\n    location: https://github.com/kazu-yamamoto/crypton-certificate\r\n    subdir:   x509-validation\r\n\r\nlibrary\r\n    exposed-modules:  Data.X509.Validation\r\n    other-modules:\r\n        Data.X509.Validation.Signature\r\n        Data.X509.Validation.Fingerprint\r\n        Data.X509.Validation.Cache\r\n        Data.X509.Validation.Types\r\n\r\n    default-language: Haskell2010\r\n    ghc-options:      -Wall\r\n    build-depends:\r\n        base >=3 && <5,\r\n        bytestring,\r\n        containers,\r\n        crypton >=1.1 && < 1.2,\r\n        crypton-asn1-types >=0.4.1 && <0.5,\r\n        crypton-asn1-encoding >=0.10.0 && <0.11,\r\n        crypton-pem >=0.2.4 && <0.4,\r\n        crypton-x509 >=1.9.1 && <1.10,\r\n        crypton-x509-store >=1.9.0 && <1.10,\r\n        data-default,\r\n        iproute >=1.2.2,\r\n        mtl,\r\n        ram,\r\n        time-hourglass\r\n\r\ntest-suite test-x509-validation\r\n    type:             exitcode-stdio-1.0\r\n    main-is:          Tests.hs\r\n    hs-source-dirs:   Tests\r\n    other-modules:    Certificate\r\n    default-language: Haskell2010\r\n    ghc-options:      -Wall\r\n    build-depends:\r\n        base >=3 && <5,\r\n        bytestring,\r\n        crypton,\r\n        crypton-asn1-encoding,\r\n        crypton-asn1-types,\r\n        crypton-x509,\r\n        crypton-x509-store,\r\n        crypton-x509-validation,\r\n        data-default,\r\n        ram,\r\n        tasty,\r\n        tasty-hunit,\r\n        time-hourglass\r\n";
  }