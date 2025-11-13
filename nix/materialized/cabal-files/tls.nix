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
      identifier = { name = "tls"; version = "2.1.6"; };
      license = "BSD-3-Clause";
      copyright = "Vincent Hanquez <vincent@snarc.org>";
      maintainer = "Kazu Yamamoto <kazu@iij.ad.jp>";
      author = "Vincent Hanquez <vincent@snarc.org>";
      homepage = "https://github.com/haskell-tls/hs-tls";
      url = "";
      synopsis = "TLS protocol native implementation";
      description = "Native Haskell TLS 1.2/1.3 protocol implementation for servers and clients.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."asn1-encoding" or (errorHandler.buildDepError "asn1-encoding"))
          (hsPkgs."asn1-types" or (errorHandler.buildDepError "asn1-types"))
          (hsPkgs."base16-bytestring" or (errorHandler.buildDepError "base16-bytestring"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          (hsPkgs."cereal" or (errorHandler.buildDepError "cereal"))
          (hsPkgs."crypton" or (errorHandler.buildDepError "crypton"))
          (hsPkgs."crypton-x509" or (errorHandler.buildDepError "crypton-x509"))
          (hsPkgs."crypton-x509-store" or (errorHandler.buildDepError "crypton-x509-store"))
          (hsPkgs."crypton-x509-validation" or (errorHandler.buildDepError "crypton-x509-validation"))
          (hsPkgs."data-default" or (errorHandler.buildDepError "data-default"))
          (hsPkgs."memory" or (errorHandler.buildDepError "memory"))
          (hsPkgs."mtl" or (errorHandler.buildDepError "mtl"))
          (hsPkgs."network" or (errorHandler.buildDepError "network"))
          (hsPkgs."serialise" or (errorHandler.buildDepError "serialise"))
          (hsPkgs."transformers" or (errorHandler.buildDepError "transformers"))
          (hsPkgs."unix-time" or (errorHandler.buildDepError "unix-time"))
        ];
        buildable = true;
      };
      exes = {
        "tls-server" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."base16-bytestring" or (errorHandler.buildDepError "base16-bytestring"))
            (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
            (hsPkgs."crypton" or (errorHandler.buildDepError "crypton"))
            (hsPkgs."crypton-x509-store" or (errorHandler.buildDepError "crypton-x509-store"))
            (hsPkgs."crypton-x509-system" or (errorHandler.buildDepError "crypton-x509-system"))
            (hsPkgs."network" or (errorHandler.buildDepError "network"))
            (hsPkgs."network-run" or (errorHandler.buildDepError "network-run"))
            (hsPkgs."tls" or (errorHandler.buildDepError "tls"))
          ];
          buildable = if flags.devel then true else false;
        };
        "tls-client" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."base16-bytestring" or (errorHandler.buildDepError "base16-bytestring"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."crypton" or (errorHandler.buildDepError "crypton"))
            (hsPkgs."crypton-x509-store" or (errorHandler.buildDepError "crypton-x509-store"))
            (hsPkgs."crypton-x509-system" or (errorHandler.buildDepError "crypton-x509-system"))
            (hsPkgs."network" or (errorHandler.buildDepError "network"))
            (hsPkgs."network-run" or (errorHandler.buildDepError "network-run"))
            (hsPkgs."tls" or (errorHandler.buildDepError "tls"))
          ];
          buildable = if flags.devel then true else false;
        };
      };
      tests = {
        "spec" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."QuickCheck" or (errorHandler.buildDepError "QuickCheck"))
            (hsPkgs."asn1-types" or (errorHandler.buildDepError "asn1-types"))
            (hsPkgs."async" or (errorHandler.buildDepError "async"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."crypton" or (errorHandler.buildDepError "crypton"))
            (hsPkgs."crypton-x509" or (errorHandler.buildDepError "crypton-x509"))
            (hsPkgs."crypton-x509-validation" or (errorHandler.buildDepError "crypton-x509-validation"))
            (hsPkgs."hourglass" or (errorHandler.buildDepError "hourglass"))
            (hsPkgs."hspec" or (errorHandler.buildDepError "hspec"))
            (hsPkgs."serialise" or (errorHandler.buildDepError "serialise"))
            (hsPkgs."tls" or (errorHandler.buildDepError "tls"))
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
      url = "http://hackage.haskell.org/package/tls-2.1.6.tar.gz";
      sha256 = "a2d9571fb47ea1ca7f3009e09eac46ee0ca80d039bbbb092736d810931e03c38";
    });
  }) // {
    package-description-override = "cabal-version:      >=1.10\nname:               tls\nversion:            2.1.6\nlicense:            BSD3\nlicense-file:       LICENSE\ncopyright:          Vincent Hanquez <vincent@snarc.org>\nmaintainer:         Kazu Yamamoto <kazu@iij.ad.jp>\nauthor:             Vincent Hanquez <vincent@snarc.org>\nhomepage:           https://github.com/haskell-tls/hs-tls\nsynopsis:           TLS protocol native implementation\ndescription:\n    Native Haskell TLS 1.2/1.3 protocol implementation for servers and clients.\n\ncategory:           Network\nbuild-type:         Simple\nextra-source-files:\n    test/*.hs\n    CHANGELOG.md\n\nsource-repository head\n    type:     git\n    location: https://github.com/haskell-tls/hs-tls\n    subdir:   core\n\nflag devel\n    description: Development commands\n    default:     False\n\nlibrary\n    exposed-modules:\n        Network.TLS\n        Network.TLS.Cipher\n        Network.TLS.Compression\n        Network.TLS.Internal\n        Network.TLS.Extra\n        Network.TLS.Extra.Cipher\n        Network.TLS.Extra.FFDHE\n        Network.TLS.QUIC\n\n    other-modules:\n        Network.TLS.Struct\n        Network.TLS.Struct13\n        Network.TLS.Core\n        Network.TLS.Context\n        Network.TLS.Context.Internal\n        Network.TLS.Credentials\n        Network.TLS.Backend\n        Network.TLS.Crypto\n        Network.TLS.Crypto.DH\n        Network.TLS.Crypto.IES\n        Network.TLS.Crypto.Types\n        Network.TLS.ErrT\n        Network.TLS.Error\n        Network.TLS.Extension\n        Network.TLS.Handshake\n        Network.TLS.Handshake.Certificate\n        Network.TLS.Handshake.Client\n        Network.TLS.Handshake.Client.ClientHello\n        Network.TLS.Handshake.Client.Common\n        Network.TLS.Handshake.Client.ServerHello\n        Network.TLS.Handshake.Client.TLS12\n        Network.TLS.Handshake.Client.TLS13\n        Network.TLS.Handshake.Common\n        Network.TLS.Handshake.Common13\n        Network.TLS.Handshake.Control\n        Network.TLS.Handshake.Key\n        Network.TLS.Handshake.Process\n        Network.TLS.Handshake.Random\n        Network.TLS.Handshake.Server\n        Network.TLS.Handshake.Server.ClientHello\n        Network.TLS.Handshake.Server.ClientHello12\n        Network.TLS.Handshake.Server.ClientHello13\n        Network.TLS.Handshake.Server.Common\n        Network.TLS.Handshake.Server.ServerHello12\n        Network.TLS.Handshake.Server.ServerHello13\n        Network.TLS.Handshake.Server.TLS12\n        Network.TLS.Handshake.Server.TLS13\n        Network.TLS.Handshake.Signature\n        Network.TLS.Handshake.State\n        Network.TLS.Handshake.State13\n        Network.TLS.HashAndSignature\n        Network.TLS.Hooks\n        Network.TLS.IO\n        Network.TLS.Imports\n        Network.TLS.KeySchedule\n        Network.TLS.MAC\n        Network.TLS.Measurement\n        Network.TLS.Packet\n        Network.TLS.Packet13\n        Network.TLS.Parameters\n        Network.TLS.PostHandshake\n        Network.TLS.Record\n        Network.TLS.Record.Disengage\n        Network.TLS.Record.Engage\n        Network.TLS.Record.Layer\n        Network.TLS.Record.Reading\n        Network.TLS.Record.Writing\n        Network.TLS.Record.State\n        Network.TLS.Record.Types\n        Network.TLS.RNG\n        Network.TLS.State\n        Network.TLS.Session\n        Network.TLS.Sending\n        Network.TLS.Receiving\n        Network.TLS.Util\n        Network.TLS.Util.ASN1\n        Network.TLS.Types\n        Network.TLS.Types.Cipher\n        Network.TLS.Types.Secret\n        Network.TLS.Types.Session\n        Network.TLS.Types.Version\n        Network.TLS.Util.Serialization\n        Network.TLS.Wire\n        Network.TLS.X509\n\n    default-extensions: Strict StrictData\n    default-language: Haskell2010\n    ghc-options:      -Wall\n    build-depends:\n        base >=4.9 && <5,\n        asn1-encoding >= 0.9 && < 0.10,\n        asn1-types >= 0.3 && < 0.4,\n        base16-bytestring,\n        bytestring >= 0.10 && < 0.13,\n        cereal >= 0.5.3 && < 0.6,\n        crypton >= 0.34,\n        crypton-x509 >= 1.7 && < 1.8,\n        crypton-x509-store >= 1.6 && < 1.7,\n        crypton-x509-validation >= 1.6.13 && < 1.7,\n        data-default,\n        memory >= 0.18 && < 0.19,\n        mtl >= 2.2 && < 2.4,\n        network >= 3.1,\n        serialise >= 0.2 && < 0.3,\n        transformers >= 0.5 && < 0.7,\n        unix-time >= 0.4.11 && < 0.5\n\ntest-suite spec\n    type:               exitcode-stdio-1.0\n    main-is:            Spec.hs\n    build-tool-depends: hspec-discover:hspec-discover\n    hs-source-dirs:     test\n    other-modules:\n        API\n        Arbitrary\n        Certificate\n        CiphersSpec\n        EncodeSpec\n        HandshakeSpec\n        PipeChan\n        PubKey\n        Run\n        Session\n        ThreadSpec\n\n    default-extensions: Strict StrictData\n    default-language:   Haskell2010\n    ghc-options:        -Wall -threaded -rtsopts\n    build-depends:\n        base >=4.9 && <5,\n        QuickCheck,\n        asn1-types,\n        async,\n        bytestring,\n        crypton,\n        crypton-x509,\n        crypton-x509-validation,\n        hourglass,\n        hspec,\n        serialise,\n        tls\n\nexecutable tls-server\n    main-is:            tls-server.hs\n    hs-source-dirs:     util\n    other-modules:\n        Common\n        Server\n        Imports\n\n    default-language:   Haskell2010\n    default-extensions: Strict StrictData\n    ghc-options:        -Wall -threaded -rtsopts\n    build-depends:\n        base >=4.9 && <5,\n        bytestring,\n        base16-bytestring,\n        containers,\n        crypton,\n        crypton-x509-store,\n        crypton-x509-system,\n        network,\n        network-run,\n        tls\n\n    if flag(devel)\n\n    else\n        buildable: False\n\nexecutable tls-client\n    main-is:            tls-client.hs\n    hs-source-dirs:     util\n    other-modules:\n        Client\n        Common\n        Imports\n\n    default-language:   Haskell2010\n    default-extensions: Strict StrictData\n    ghc-options:        -Wall -threaded -rtsopts\n    build-depends:\n        base >=4.9 && <5,\n        base16-bytestring,\n        bytestring,\n        crypton,\n        crypton-x509-store,\n        crypton-x509-system,\n        network,\n        network-run,\n        tls\n\n    if flag(devel)\n\n    else\n        buildable: False\n";
  }