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
    flags = { devel = false; };
    package = {
      specVersion = "1.10";
      identifier = { name = "ech-config"; version = "0.0.1"; };
      license = "BSD-3-Clause";
      copyright = "";
      maintainer = "kazu@iij.ad.jp";
      author = "Kazu Yamamoto";
      homepage = "";
      url = "";
      synopsis = "Config for TLS Encrypted Client Hello";
      description = "Config types for TLS Encrypted Client Hello to glue DNS and TLS";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."base16-bytestring" or (errorHandler.buildDepError "base16-bytestring"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
          (hsPkgs."network-byte-order" or (errorHandler.buildDepError "network-byte-order"))
        ];
        buildable = true;
      };
      exes = {
        "ech-gen" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."base64-bytestring" or (errorHandler.buildDepError "base64-bytestring"))
            (hsPkgs."ech-config" or (errorHandler.buildDepError "ech-config"))
            (hsPkgs."hpke" or (errorHandler.buildDepError "hpke"))
          ];
          buildable = if flags.devel then true else false;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/ech-config-0.0.1.tar.gz";
      sha256 = "b236b6d7ea1385c280b76051edc7d8f6db31c9cb7b35df5c06f5a0bd75b4feba";
    });
  }) // {
    package-description-override = "cabal-version:      >=1.10\r\nname:               ech-config\r\nversion:            0.0.1\r\nx-revision: 1\r\nlicense:            BSD3\r\nlicense-file:       LICENSE\r\nmaintainer:         kazu@iij.ad.jp\r\nauthor:             Kazu Yamamoto\r\nsynopsis:           Config for TLS Encrypted Client Hello\r\ndescription:\r\n    Config types for TLS Encrypted Client Hello to glue DNS and TLS\r\n\r\ncategory:           Network\r\nbuild-type:         Simple\r\nextra-source-files: ChangeLog.md\r\n\r\nflag devel\r\n    description: Development commands\r\n    default:     False\r\n\r\nlibrary\r\n    exposed-modules:    Network.TLS.ECH.Config\r\n    default-language:   Haskell2010\r\n    default-extensions: Strict StrictData\r\n    ghc-options:        -Wall\r\n    build-depends:\r\n        base >=4.7 && <5,\r\n        base16-bytestring,\r\n        bytestring,\r\n        filepath,\r\n        network-byte-order >= 0.1.7\r\n\r\nexecutable ech-gen\r\n    main-is:            ech-gen.hs\r\n    hs-source-dirs:     util\r\n    default-language:   Haskell2010\r\n    default-extensions: Strict StrictData\r\n    ghc-options:        -Wall -threaded -rtsopts\r\n    build-depends:\r\n        base >=4.9 && <5,\r\n        bytestring,\r\n        base64-bytestring,\r\n        ech-config,\r\n        hpke\r\n\r\n    if flag(devel)\r\n\r\n    else\r\n        buildable: False\r\n\r\nsource-repository head\r\n    type:     git\r\n    location: https://github.com/haskell-tls/hs-tls\r\n    subdir:   tls\r\n";
  }