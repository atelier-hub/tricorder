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
      identifier = { name = "crypton-x509-store"; version = "1.6.12"; };
      license = "BSD-3-Clause";
      copyright = "Vincent Hanquez <vincent@snarc.org>";
      maintainer = "Kazu Yamamoto <kazu@iij.ad.jp>";
      author = "Vincent Hanquez <vincent@snarc.org>";
      homepage = "https://github.com/kazu-yamamoto/crypton-certificate";
      url = "";
      synopsis = "X.509 collection accessing and storing methods";
      description = "X.509 collection accessing and storing methods for certificate, crl, exception list";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          (hsPkgs."mtl" or (errorHandler.buildDepError "mtl"))
          (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
          (hsPkgs."directory" or (errorHandler.buildDepError "directory"))
          (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
          (hsPkgs."pem" or (errorHandler.buildDepError "pem"))
          (hsPkgs."asn1-types" or (errorHandler.buildDepError "asn1-types"))
          (hsPkgs."asn1-encoding" or (errorHandler.buildDepError "asn1-encoding"))
          (hsPkgs."crypton" or (errorHandler.buildDepError "crypton"))
          (hsPkgs."crypton-x509" or (errorHandler.buildDepError "crypton-x509"))
        ] ++ pkgs.lib.optional (!system.isWindows) (hsPkgs."unix" or (errorHandler.buildDepError "unix"));
        buildable = true;
      };
      tests = {
        "test-x509-store" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."tasty" or (errorHandler.buildDepError "tasty"))
            (hsPkgs."tasty-hunit" or (errorHandler.buildDepError "tasty-hunit"))
            (hsPkgs."crypton-x509" or (errorHandler.buildDepError "crypton-x509"))
            (hsPkgs."crypton-x509-store" or (errorHandler.buildDepError "crypton-x509-store"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/crypton-x509-store-1.6.12.tar.gz";
      sha256 = "d7a0af5bdf1f1812fa21d1ebd91c2c02458ae82781ab19da052b65ba88e83c91";
    });
  }) // {
    package-description-override = "Name:                crypton-x509-store\r\nversion:             1.6.12\r\nx-revision: 1\r\nDescription:         X.509 collection accessing and storing methods for certificate, crl, exception list\r\nLicense:             BSD3\r\nLicense-file:        LICENSE\r\nCopyright:           Vincent Hanquez <vincent@snarc.org>\r\nAuthor:              Vincent Hanquez <vincent@snarc.org>\r\nMaintainer:          Kazu Yamamoto <kazu@iij.ad.jp>\r\nSynopsis:            X.509 collection accessing and storing methods\r\nBuild-Type:          Simple\r\nCategory:            Data\r\nstability:           experimental\r\nHomepage:            https://github.com/kazu-yamamoto/crypton-certificate\r\nCabal-Version:       >= 1.10\r\n\r\nLibrary\r\n  Default-Language:  Haskell2010\r\n  Build-Depends:     base >= 3 && < 5\r\n                   , bytestring\r\n                   , mtl\r\n                   , containers\r\n                   , directory\r\n                   , filepath\r\n                   , pem >= 0.1 && < 0.3\r\n                   , asn1-types >= 0.3 && < 0.4\r\n                   , asn1-encoding >= 0.9 && < 0.10\r\n                   , crypton\r\n                   , crypton-x509 >= 1.7.2\r\n  if !os(windows)\r\n      Build-Depends: unix >= 2.8\r\n  Exposed-modules:   Data.X509.CertificateStore\r\n                     Data.X509.File\r\n                     Data.X509.Memory\r\n  ghc-options:       -Wall\r\n\r\nTest-Suite test-x509-store\r\n  Default-Language:  Haskell2010\r\n  type:              exitcode-stdio-1.0\r\n  hs-source-dirs:    Tests\r\n  Main-is:           Tests.hs\r\n  Build-Depends:     base >= 3 && < 5\r\n                   , bytestring\r\n                   , tasty\r\n                   , tasty-hunit\r\n                   , crypton-x509\r\n                   , crypton-x509-store\r\n  ghc-options:       -Wall\r\n\r\nsource-repository head\r\n  type:     git\r\n  location: https://github.com/kazu-yamamoto/crypton-certificate\r\n  subdir:   x509-store\r\n";
  }