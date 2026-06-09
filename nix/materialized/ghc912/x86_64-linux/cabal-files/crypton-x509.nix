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
      identifier = { name = "crypton-x509"; version = "1.9.0"; };
      license = "BSD-3-Clause";
      copyright = "Vincent Hanquez <vincent@snarc.org>";
      maintainer = "Kazu Yamamoto <kazu@iij.ad.jp>";
      author = "Vincent Hanquez <vincent@snarc.org>";
      homepage = "https://github.com/kazu-yamamoto/crypton-certificate";
      url = "";
      synopsis = "X509 reader and writer";
      description = "X509 reader and writer. please see README";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
          (hsPkgs."crypton" or (errorHandler.buildDepError "crypton"))
          (hsPkgs."crypton-asn1-encoding" or (errorHandler.buildDepError "crypton-asn1-encoding"))
          (hsPkgs."crypton-asn1-parse" or (errorHandler.buildDepError "crypton-asn1-parse"))
          (hsPkgs."crypton-asn1-types" or (errorHandler.buildDepError "crypton-asn1-types"))
          (hsPkgs."crypton-pem" or (errorHandler.buildDepError "crypton-pem"))
          (hsPkgs."ram" or (errorHandler.buildDepError "ram"))
          (hsPkgs."time-hourglass" or (errorHandler.buildDepError "time-hourglass"))
          (hsPkgs."transformers" or (errorHandler.buildDepError "transformers"))
        ];
        buildable = true;
      };
      tests = {
        "test-x509" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."crypton" or (errorHandler.buildDepError "crypton"))
            (hsPkgs."crypton-x509" or (errorHandler.buildDepError "crypton-x509"))
            (hsPkgs."crypton-asn1-types" or (errorHandler.buildDepError "crypton-asn1-types"))
            (hsPkgs."mtl" or (errorHandler.buildDepError "mtl"))
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
      url = "http://hackage.haskell.org/package/crypton-x509-1.9.0.tar.gz";
      sha256 = "155dbad5f91985fa4aa4874b77d302bce563619a65cc30578f3998e9304276cd";
    });
  }) // {
    package-description-override = "cabal-version:      >=1.10\nname:               crypton-x509\nversion:            1.9.0\nlicense:            BSD3\nlicense-file:       LICENSE\ncopyright:          Vincent Hanquez <vincent@snarc.org>\nmaintainer:         Kazu Yamamoto <kazu@iij.ad.jp>\nauthor:             Vincent Hanquez <vincent@snarc.org>\nstability:          experimental\nhomepage:           https://github.com/kazu-yamamoto/crypton-certificate\nsynopsis:           X509 reader and writer\ndescription:        X509 reader and writer. please see README\ncategory:           Data\nbuild-type:         Simple\nextra-source-files: ChangeLog.md\n\nsource-repository head\n    type:     git\n    location: https://github.com/kazu-yamamoto/crypton-certificate\n    subdir:   x509\n\nlibrary\n    exposed-modules:\n        Data.X509\n        Data.X509.EC\n\n    other-modules:\n        Data.X509.Internal\n        Data.X509.CertificateChain\n        Data.X509.AlgorithmIdentifier\n        Data.X509.DistinguishedName\n        Data.X509.Cert\n        Data.X509.PublicKey\n        Data.X509.PrivateKey\n        Data.X509.Ext\n        Data.X509.ExtensionRaw\n        Data.X509.CRL\n        Data.X509.OID\n        Data.X509.Signed\n\n    default-language: Haskell2010\n    ghc-options:      -Wall\n    build-depends:\n        base >=4.7 && <5,\n        bytestring,\n        containers,\n        crypton >=1.1 && <1.2,\n        crypton-asn1-encoding >=0.10.0 && <0.11,\n        crypton-asn1-parse >=0.10.0 && <0.11,\n        crypton-asn1-types >=0.4.1 && <0.5,\n        crypton-pem >=0.2.4 && <0.4,\n        ram,\n        time-hourglass,\n        transformers >=0.4\n\ntest-suite test-x509\n    type:             exitcode-stdio-1.0\n    main-is:          Tests.hs\n    hs-source-dirs:   Tests\n    default-language: Haskell2010\n    ghc-options:      -Wall -fno-warn-orphans -fno-warn-missing-signatures\n    build-depends:\n        base >=3 && <5,\n        bytestring,\n        crypton,\n        crypton-x509,\n        crypton-asn1-types,\n        mtl,\n        tasty,\n        tasty-quickcheck,\n        time-hourglass\n";
  }