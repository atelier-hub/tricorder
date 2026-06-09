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
      identifier = { name = "crypton-x509-store"; version = "1.9.0"; };
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
          (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
          (hsPkgs."crypton" or (errorHandler.buildDepError "crypton"))
          (hsPkgs."crypton-asn1-encoding" or (errorHandler.buildDepError "crypton-asn1-encoding"))
          (hsPkgs."crypton-asn1-types" or (errorHandler.buildDepError "crypton-asn1-types"))
          (hsPkgs."crypton-pem" or (errorHandler.buildDepError "crypton-pem"))
          (hsPkgs."crypton-x509" or (errorHandler.buildDepError "crypton-x509"))
          (hsPkgs."directory" or (errorHandler.buildDepError "directory"))
          (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
          (hsPkgs."mtl" or (errorHandler.buildDepError "mtl"))
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
      url = "http://hackage.haskell.org/package/crypton-x509-store-1.9.0.tar.gz";
      sha256 = "de9193403c11d1fb090083382646be6f6cf68ed984f475d1a0e142f77efb8766";
    });
  }) // {
    package-description-override = "cabal-version:      >=1.10\nname:               crypton-x509-store\nversion:            1.9.0\nlicense:            BSD3\nlicense-file:       LICENSE\ncopyright:          Vincent Hanquez <vincent@snarc.org>\nmaintainer:         Kazu Yamamoto <kazu@iij.ad.jp>\nauthor:             Vincent Hanquez <vincent@snarc.org>\nstability:          experimental\nhomepage:           https://github.com/kazu-yamamoto/crypton-certificate\nsynopsis:           X.509 collection accessing and storing methods\ndescription:\n    X.509 collection accessing and storing methods for certificate, crl, exception list\n\ncategory:           Data\nbuild-type:         Simple\nextra-source-files: ChangeLog.md\n\nsource-repository head\n    type:     git\n    location: https://github.com/kazu-yamamoto/crypton-certificate\n    subdir:   x509-store\n\nlibrary\n    exposed-modules:\n        Data.X509.CertificateStore\n        Data.X509.File\n        Data.X509.Memory\n\n    default-language: Haskell2010\n    ghc-options:      -Wall\n    build-depends:\n        base >=3 && <5,\n        bytestring,\n        containers,\n        crypton >=1.1.0 && < 1.2,\n        crypton-asn1-encoding >=0.10.0 && <0.11,\n        crypton-asn1-types >=0.4.1 && <0.5,\n        crypton-pem >=0.2.4 && <0.4,\n        crypton-x509 >=1.9.0 && <1.10,\n        directory,\n        filepath,\n        mtl\n\n    if !os(windows)\n        build-depends: unix\n\ntest-suite test-x509-store\n    type:             exitcode-stdio-1.0\n    main-is:          Tests.hs\n    hs-source-dirs:   Tests\n    default-language: Haskell2010\n    ghc-options:      -Wall\n    build-depends:\n        base >=3 && <5,\n        bytestring,\n        tasty,\n        tasty-hunit,\n        crypton-x509,\n        crypton-x509-store\n";
  }