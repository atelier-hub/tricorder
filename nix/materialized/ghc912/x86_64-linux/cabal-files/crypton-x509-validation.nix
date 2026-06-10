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
      identifier = { name = "crypton-x509-validation"; version = "1.9.0"; };
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
      url = "http://hackage.haskell.org/package/crypton-x509-validation-1.9.0.tar.gz";
      sha256 = "1396e005e4abaa4b2db7610210d357839152fdc532dd7f254d913f0fc2d34fd8";
    });
  }) // {
    package-description-override = "cabal-version:      >=1.10\nname:               crypton-x509-validation\nversion:            1.9.0\nlicense:            BSD3\nlicense-file:       LICENSE\ncopyright:          Vincent Hanquez <vincent@snarc.org>\nmaintainer:         Kazu Yamamoto <kazu@iij.ad.jp>\nauthor:             Vincent Hanquez <vincent@snarc.org>\nstability:          experimental\nhomepage:           https://github.com/kazu-yamamoto/crypton-certificate\nsynopsis:           X.509 Certificate and CRL validation\ndescription:        X.509 Certificate and CRL validation. please see README\ncategory:           Data\nbuild-type:         Simple\nextra-source-files: ChangeLog.md\n\nsource-repository head\n    type:     git\n    location: https://github.com/kazu-yamamoto/crypton-certificate\n    subdir:   x509-validation\n\nlibrary\n    exposed-modules:  Data.X509.Validation\n    other-modules:\n        Data.X509.Validation.Signature\n        Data.X509.Validation.Fingerprint\n        Data.X509.Validation.Cache\n        Data.X509.Validation.Types\n\n    default-language: Haskell2010\n    ghc-options:      -Wall\n    build-depends:\n        base >=3 && <5,\n        bytestring,\n        containers,\n        crypton >=1.1 && < 1.2,\n        crypton-asn1-types >=0.4.1 && <0.5,\n        crypton-asn1-encoding >=0.10.0 && <0.11,\n        crypton-pem >=0.2.4 && <0.4,\n        crypton-x509 >=1.9.0 && <1.10,\n        crypton-x509-store >=1.9.0 && <1.10,\n        data-default,\n        iproute >=1.2.2,\n        mtl,\n        ram,\n        time-hourglass\n\ntest-suite test-x509-validation\n    type:             exitcode-stdio-1.0\n    main-is:          Tests.hs\n    hs-source-dirs:   Tests\n    other-modules:    Certificate\n    default-language: Haskell2010\n    ghc-options:      -Wall\n    build-depends:\n        base >=3 && <5,\n        bytestring,\n        crypton,\n        crypton-asn1-encoding,\n        crypton-asn1-types,\n        crypton-x509,\n        crypton-x509-store,\n        crypton-x509-validation,\n        data-default,\n        ram,\n        tasty,\n        tasty-hunit,\n        time-hourglass\n";
  }