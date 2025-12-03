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
      identifier = { name = "hpke"; version = "0.0.0"; };
      license = "BSD-3-Clause";
      copyright = "";
      maintainer = "kazu@iij.ad.jp";
      author = "Kazu Yamamoto";
      homepage = "";
      url = "";
      synopsis = "Hybrid Public Key Encryption";
      description = "Hybrid Public Key Encryption defined in RFC9180";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."base16-bytestring" or (errorHandler.buildDepError "base16-bytestring"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          (hsPkgs."crypton" or (errorHandler.buildDepError "crypton"))
          (hsPkgs."memory" or (errorHandler.buildDepError "memory"))
        ];
        buildable = true;
      };
      tests = {
        "spec" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."QuickCheck" or (errorHandler.buildDepError "QuickCheck"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."base16-bytestring" or (errorHandler.buildDepError "base16-bytestring"))
            (hsPkgs."hpke" or (errorHandler.buildDepError "hpke"))
            (hsPkgs."hspec" or (errorHandler.buildDepError "hspec"))
          ];
          build-tools = [
            (hsPkgs.pkgsBuildBuild.hspec-discover.components.exes.hspec-discover or (pkgs.pkgsBuildBuild.hspec-discover or (errorHandler.buildToolDepError "hspec-discover:hspec-discover")))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/hpke-0.0.0.tar.gz";
      sha256 = "7b0b7dfb4f7081beab54c4cb0cb3df3f3c03ce05cb11747f190bab22df19b83c";
    });
  }) // {
    package-description-override = "cabal-version:      >=1.10\nname:               hpke\nversion:            0.0.0\nlicense:            BSD3\nlicense-file:       LICENSE\nmaintainer:         kazu@iij.ad.jp\nauthor:             Kazu Yamamoto\nsynopsis:           Hybrid Public Key Encryption\ndescription:\n    Hybrid Public Key Encryption defined in RFC9180\n\ncategory:           Cryptography\nbuild-type:         Simple\nextra-source-files: ChangeLog.md\n\nlibrary\n    exposed-modules:  Crypto.HPKE\n                      Crypto.HPKE.Internal\n    other-modules:    Crypto.HPKE.AEAD\n                      Crypto.HPKE.Context\n                      Crypto.HPKE.ID\n                      Crypto.HPKE.KDF\n                      Crypto.HPKE.KEM\n                      Crypto.HPKE.KeyPair\n                      Crypto.HPKE.KeySchedule\n                      Crypto.HPKE.PublicKey\n                      Crypto.HPKE.Setup\n                      Crypto.HPKE.Types\n    default-language: Haskell2010\n    ghc-options:      -Wall\n    build-depends:\n        base >=4.7 && <5,\n        base16-bytestring,\n        bytestring,\n        crypton >= 1.0.2,\n        memory\n\n    default-extensions: Strict StrictData\n\ntest-suite spec\n    type:               exitcode-stdio-1.0\n    main-is:            Spec.hs\n    build-tool-depends: hspec-discover:hspec-discover\n    hs-source-dirs:     test\n    other-modules:      A1Spec\n                        A2Spec\n                        A3Spec\n                        A4Spec\n                        A5Spec\n                        A6Spec\n                        Test\n\n    default-language:   Haskell2010\n    default-extensions: Strict StrictData\n    ghc-options:        -Wall -threaded -rtsopts\n    build-depends:\n        base >=4.9 && <5,\n        QuickCheck,\n        bytestring,\n        base16-bytestring,\n        hpke,\n        hspec\n";
  }