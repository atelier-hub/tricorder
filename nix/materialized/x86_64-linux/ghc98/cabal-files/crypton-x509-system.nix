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
      identifier = { name = "crypton-x509-system"; version = "1.9.0"; };
      license = "BSD-3-Clause";
      copyright = "Vincent Hanquez <vincent@snarc.org>";
      maintainer = "Kazu Yamamoto <kazu@iij.ad.jp>";
      author = "Vincent Hanquez <vincent@snarc.org>";
      homepage = "https://github.com/kazu-yamamoto/crypton-certificate";
      url = "";
      synopsis = "Handle per-operating-system X.509 accessors and storage";
      description = "System X.509 handling for accessing operating system dependents store and other storage methods";
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
          (hsPkgs."process" or (errorHandler.buildDepError "process"))
          (hsPkgs."crypton-pem" or (errorHandler.buildDepError "crypton-pem"))
          (hsPkgs."crypton-x509" or (errorHandler.buildDepError "crypton-x509"))
          (hsPkgs."crypton-x509-store" or (errorHandler.buildDepError "crypton-x509-store"))
        ] ++ pkgs.lib.optionals (system.isWindows) [
          (hsPkgs."Win32" or (errorHandler.buildDepError "Win32"))
          (hsPkgs."crypton-asn1-encoding" or (errorHandler.buildDepError "crypton-asn1-encoding"))
        ];
        libs = pkgs.lib.optional (system.isWindows) (pkgs."Crypt32" or (errorHandler.sysDepError "Crypt32"));
        buildable = true;
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/crypton-x509-system-1.9.0.tar.gz";
      sha256 = "89ee819b78963a5c925fdaad80e2e64be6c0fedf4f24fc2b95eddb649b86cefe";
    });
  }) // {
    package-description-override = "cabal-version:      >=1.10\nname:               crypton-x509-system\nversion:            1.9.0\nlicense:            BSD3\nlicense-file:       LICENSE\ncopyright:          Vincent Hanquez <vincent@snarc.org>\nmaintainer:         Kazu Yamamoto <kazu@iij.ad.jp>\nauthor:             Vincent Hanquez <vincent@snarc.org>\nstability:          experimental\nhomepage:           https://github.com/kazu-yamamoto/crypton-certificate\nsynopsis:           Handle per-operating-system X.509 accessors and storage\ndescription:\n    System X.509 handling for accessing operating system dependents store and other storage methods\n\ncategory:           Data\nbuild-type:         Simple\nextra-source-files: ChangeLog.md\n\nsource-repository head\n    type:     git\n    location: https://github.com/kazu-yamamoto/crypton-certificate\n    subdir:   x509-system\n\nlibrary\n    exposed-modules:\n        System.X509\n        System.X509.Common\n        System.X509.Unix\n        System.X509.MacOS\n\n    default-language: Haskell2010\n    ghc-options:      -Wall\n    build-depends:\n        base >=3 && <5,\n        bytestring,\n        mtl,\n        containers,\n        directory,\n        filepath,\n        process,\n        crypton-pem >=0.2.4 && <0.4,\n        crypton-x509 >=1.9.0 && <1.10,\n        crypton-x509-store >=1.9.0 && <1.10\n\n    if os(windows)\n        exposed-modules: System.X509.Win32\n        cpp-options:     -DWINDOWS\n        extra-libraries: Crypt32\n        build-depends:\n            Win32,\n            crypton-asn1-encoding\n\n    if os(osx)\n        cpp-options: -DMACOSX\n";
  }