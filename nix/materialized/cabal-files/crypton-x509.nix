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
      identifier = { name = "crypton-x509"; version = "1.7.7"; };
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
          (hsPkgs."memory" or (errorHandler.buildDepError "memory"))
          (hsPkgs."transformers" or (errorHandler.buildDepError "transformers"))
          (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
          (hsPkgs."hourglass" or (errorHandler.buildDepError "hourglass"))
          (hsPkgs."pem" or (errorHandler.buildDepError "pem"))
          (hsPkgs."asn1-types" or (errorHandler.buildDepError "asn1-types"))
          (hsPkgs."asn1-encoding" or (errorHandler.buildDepError "asn1-encoding"))
          (hsPkgs."asn1-parse" or (errorHandler.buildDepError "asn1-parse"))
          (hsPkgs."crypton" or (errorHandler.buildDepError "crypton"))
        ];
        buildable = true;
      };
      tests = {
        "test-x509" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."mtl" or (errorHandler.buildDepError "mtl"))
            (hsPkgs."tasty" or (errorHandler.buildDepError "tasty"))
            (hsPkgs."tasty-quickcheck" or (errorHandler.buildDepError "tasty-quickcheck"))
            (hsPkgs."hourglass" or (errorHandler.buildDepError "hourglass"))
            (hsPkgs."asn1-types" or (errorHandler.buildDepError "asn1-types"))
            (hsPkgs."crypton-x509" or (errorHandler.buildDepError "crypton-x509"))
            (hsPkgs."crypton" or (errorHandler.buildDepError "crypton"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/crypton-x509-1.7.7.tar.gz";
      sha256 = "efece48c8c4adfee209979c2967037d90e6ba1b7b4e7bb1081d1d4cd93daf382";
    });
  }) // {
    package-description-override = "Name:                crypton-x509\nversion:             1.7.7\nDescription:         X509 reader and writer. please see README\nLicense:             BSD3\nLicense-file:        LICENSE\nCopyright:           Vincent Hanquez <vincent@snarc.org>\nAuthor:              Vincent Hanquez <vincent@snarc.org>\nMaintainer:          Kazu Yamamoto <kazu@iij.ad.jp>\nSynopsis:            X509 reader and writer\nBuild-Type:          Simple\nCategory:            Data\nstability:           experimental\nHomepage:            https://github.com/kazu-yamamoto/crypton-certificate\nCabal-Version:       >= 1.10\n\nLibrary\n  Default-Language:  Haskell2010\n  Build-Depends:     base >= 4.7 && < 5\n                   , bytestring\n                   , memory\n                   , transformers >= 0.4\n                   , containers\n                   , hourglass\n                   , pem >= 0.1\n                   , asn1-types >= 0.3.1 && < 0.4\n                   , asn1-encoding >= 0.9 && < 0.10\n                   , asn1-parse >= 0.9.3 && < 0.10\n                   , crypton >= 0.24\n  Exposed-modules:   Data.X509\n                     Data.X509.EC\n  Other-modules:     Data.X509.Internal\n                     Data.X509.CertificateChain\n                     Data.X509.AlgorithmIdentifier\n                     Data.X509.DistinguishedName\n                     Data.X509.Cert\n                     Data.X509.PublicKey\n                     Data.X509.PrivateKey\n                     Data.X509.Ext\n                     Data.X509.ExtensionRaw\n                     Data.X509.CRL\n                     Data.X509.OID\n                     Data.X509.Signed\n  ghc-options:       -Wall\n\nTest-Suite test-x509\n  Default-Language:  Haskell2010\n  type:              exitcode-stdio-1.0\n  hs-source-dirs:    Tests\n  Main-is:           Tests.hs\n  Build-Depends:     base >= 3 && < 5\n                   , bytestring\n                   , mtl\n                   , tasty\n                   , tasty-quickcheck\n                   , hourglass\n                   , asn1-types\n                   , crypton-x509\n                   , crypton\n  ghc-options:       -Wall -fno-warn-orphans -fno-warn-missing-signatures\n\nsource-repository head\n  type:     git\n  location: https://github.com/kazu-yamamoto/crypton-certificate\n  subdir:   x509\n";
  }