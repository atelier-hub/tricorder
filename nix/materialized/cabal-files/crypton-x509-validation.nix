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
      identifier = { name = "crypton-x509-validation"; version = "1.6.14"; };
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
          (hsPkgs."memory" or (errorHandler.buildDepError "memory"))
          (hsPkgs."mtl" or (errorHandler.buildDepError "mtl"))
          (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
          (hsPkgs."hourglass" or (errorHandler.buildDepError "hourglass"))
          (hsPkgs."data-default" or (errorHandler.buildDepError "data-default"))
          (hsPkgs."pem" or (errorHandler.buildDepError "pem"))
          (hsPkgs."asn1-types" or (errorHandler.buildDepError "asn1-types"))
          (hsPkgs."asn1-encoding" or (errorHandler.buildDepError "asn1-encoding"))
          (hsPkgs."crypton-x509" or (errorHandler.buildDepError "crypton-x509"))
          (hsPkgs."crypton-x509-store" or (errorHandler.buildDepError "crypton-x509-store"))
          (hsPkgs."crypton" or (errorHandler.buildDepError "crypton"))
          (hsPkgs."iproute" or (errorHandler.buildDepError "iproute"))
        ];
        buildable = true;
      };
      tests = {
        "test-x509-validation" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."memory" or (errorHandler.buildDepError "memory"))
            (hsPkgs."data-default" or (errorHandler.buildDepError "data-default"))
            (hsPkgs."tasty" or (errorHandler.buildDepError "tasty"))
            (hsPkgs."tasty-hunit" or (errorHandler.buildDepError "tasty-hunit"))
            (hsPkgs."hourglass" or (errorHandler.buildDepError "hourglass"))
            (hsPkgs."asn1-types" or (errorHandler.buildDepError "asn1-types"))
            (hsPkgs."asn1-encoding" or (errorHandler.buildDepError "asn1-encoding"))
            (hsPkgs."crypton-x509" or (errorHandler.buildDepError "crypton-x509"))
            (hsPkgs."crypton-x509-store" or (errorHandler.buildDepError "crypton-x509-store"))
            (hsPkgs."crypton-x509-validation" or (errorHandler.buildDepError "crypton-x509-validation"))
            (hsPkgs."crypton" or (errorHandler.buildDepError "crypton"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/crypton-x509-validation-1.6.14.tar.gz";
      sha256 = "ed0e394127db59d66a0a8e4bde28fa0b8cc67cc9a810793b54a58e96df4c601d";
    });
  }) // {
    package-description-override = "Name:                crypton-x509-validation\nversion:             1.6.14\nDescription:         X.509 Certificate and CRL validation. please see README\nLicense:             BSD3\nLicense-file:        LICENSE\nCopyright:           Vincent Hanquez <vincent@snarc.org>\nAuthor:              Vincent Hanquez <vincent@snarc.org>\nMaintainer:          Kazu Yamamoto <kazu@iij.ad.jp>\nSynopsis:            X.509 Certificate and CRL validation\nBuild-Type:          Simple\nCategory:            Data\nstability:           experimental\nHomepage:            https://github.com/kazu-yamamoto/crypton-certificate\nCabal-Version:       >= 1.10\n\nLibrary\n  Default-Language:  Haskell2010\n  Build-Depends:     base >= 3 && < 5\n                   , bytestring\n                   , memory\n                   , mtl\n                   , containers\n                   , hourglass\n                   , data-default\n                   , pem >= 0.1\n                   , asn1-types >= 0.3 && < 0.4\n                   , asn1-encoding >= 0.9 && < 0.10\n                   , crypton-x509 >= 1.7.5\n                   , crypton-x509-store >= 1.6\n                   , crypton >= 0.24\n                   , iproute >= 1.2.2\n  Exposed-modules:   Data.X509.Validation\n  Other-modules:     Data.X509.Validation.Signature\n                     Data.X509.Validation.Fingerprint\n                     Data.X509.Validation.Cache\n                     Data.X509.Validation.Types\n  ghc-options:       -Wall\n\nTest-Suite test-x509-validation\n  Default-Language:  Haskell2010\n  type:              exitcode-stdio-1.0\n  hs-source-dirs:    Tests\n  Main-is:           Tests.hs\n  Other-modules:     Certificate\n  Build-Depends:     base >= 3 && < 5\n                   , bytestring\n                   , memory\n                   , data-default\n                   , tasty\n                   , tasty-hunit\n                   , hourglass\n                   , asn1-types\n                   , asn1-encoding\n                   , crypton-x509 >= 1.7.1\n                   , crypton-x509-store\n                   , crypton-x509-validation\n                   , crypton\n  ghc-options:       -Wall\n\nsource-repository head\n  type:     git\n  location: https://github.com/kazu-yamamoto/crypton-certificate\n  subdir:   x509-validation\n";
  }