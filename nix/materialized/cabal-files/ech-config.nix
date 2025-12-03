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
    package-description-override = "cabal-version:      >=1.10\nname:               ech-config\nversion:            0.0.1\nlicense:            BSD3\nlicense-file:       LICENSE\nmaintainer:         kazu@iij.ad.jp\nauthor:             Kazu Yamamoto\nsynopsis:           Config for TLS Encrypted Client Hello\ndescription:\n    Config types for TLS Encrypted Client Hello to glue DNS and TLS\n\ncategory:           Network\nbuild-type:         Simple\nextra-source-files: ChangeLog.md\n\nflag devel\n    description: Development commands\n    default:     False\n\nlibrary\n    exposed-modules:    Network.TLS.ECH.Config\n    default-language:   Haskell2010\n    default-extensions: Strict StrictData\n    ghc-options:        -Wall\n    build-depends:\n        base >=4.7 && <5,\n        base16-bytestring,\n        bytestring,\n        filepath,\n        network-byte-order\n\nexecutable ech-gen\n    main-is:            ech-gen.hs\n    hs-source-dirs:     util\n    default-language:   Haskell2010\n    default-extensions: Strict StrictData\n    ghc-options:        -Wall -threaded -rtsopts\n    build-depends:\n        base >=4.9 && <5,\n        bytestring,\n        base64-bytestring,\n        ech-config,\n        hpke\n\n    if flag(devel)\n\n    else\n        buildable: False\n\nsource-repository head\n    type:     git\n    location: https://github.com/haskell-tls/hs-tls\n    subdir:   tls\n";
  }