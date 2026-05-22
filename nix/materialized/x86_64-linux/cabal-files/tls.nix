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
      identifier = { name = "tls"; version = "2.3.0"; };
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
          (hsPkgs."base16-bytestring" or (errorHandler.buildDepError "base16-bytestring"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          (hsPkgs."cereal" or (errorHandler.buildDepError "cereal"))
          (hsPkgs."crypton" or (errorHandler.buildDepError "crypton"))
          (hsPkgs."crypton-asn1-encoding" or (errorHandler.buildDepError "crypton-asn1-encoding"))
          (hsPkgs."crypton-asn1-types" or (errorHandler.buildDepError "crypton-asn1-types"))
          (hsPkgs."crypton-x509" or (errorHandler.buildDepError "crypton-x509"))
          (hsPkgs."crypton-x509-store" or (errorHandler.buildDepError "crypton-x509-store"))
          (hsPkgs."crypton-x509-validation" or (errorHandler.buildDepError "crypton-x509-validation"))
          (hsPkgs."data-default" or (errorHandler.buildDepError "data-default"))
          (hsPkgs."ech-config" or (errorHandler.buildDepError "ech-config"))
          (hsPkgs."hpke" or (errorHandler.buildDepError "hpke"))
          (hsPkgs."mtl" or (errorHandler.buildDepError "mtl"))
          (hsPkgs."network" or (errorHandler.buildDepError "network"))
          (hsPkgs."ram" or (errorHandler.buildDepError "ram"))
          (hsPkgs."random" or (errorHandler.buildDepError "random"))
          (hsPkgs."serialise" or (errorHandler.buildDepError "serialise"))
          (hsPkgs."transformers" or (errorHandler.buildDepError "transformers"))
          (hsPkgs."unix-time" or (errorHandler.buildDepError "unix-time"))
          (hsPkgs."zlib" or (errorHandler.buildDepError "zlib"))
        ];
        buildable = true;
      };
      exes = {
        "tls-server" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."base16-bytestring" or (errorHandler.buildDepError "base16-bytestring"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
            (hsPkgs."crypton" or (errorHandler.buildDepError "crypton"))
            (hsPkgs."crypton-x509-store" or (errorHandler.buildDepError "crypton-x509-store"))
            (hsPkgs."crypton-x509-system" or (errorHandler.buildDepError "crypton-x509-system"))
            (hsPkgs."ech-config" or (errorHandler.buildDepError "ech-config"))
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
            (hsPkgs."ech-config" or (errorHandler.buildDepError "ech-config"))
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
            (hsPkgs."async" or (errorHandler.buildDepError "async"))
            (hsPkgs."base64-bytestring" or (errorHandler.buildDepError "base64-bytestring"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."crypton" or (errorHandler.buildDepError "crypton"))
            (hsPkgs."crypton-asn1-types" or (errorHandler.buildDepError "crypton-asn1-types"))
            (hsPkgs."crypton-x509" or (errorHandler.buildDepError "crypton-x509"))
            (hsPkgs."crypton-x509-validation" or (errorHandler.buildDepError "crypton-x509-validation"))
            (hsPkgs."ech-config" or (errorHandler.buildDepError "ech-config"))
            (hsPkgs."hspec" or (errorHandler.buildDepError "hspec"))
            (hsPkgs."serialise" or (errorHandler.buildDepError "serialise"))
            (hsPkgs."time-hourglass" or (errorHandler.buildDepError "time-hourglass"))
            (hsPkgs."tls" or (errorHandler.buildDepError "tls"))
          ];
          build-tools = [
            (hsPkgs.pkgsBuildBuild.hspec-discover.components.exes.hspec-discover or (pkgs.pkgsBuildBuild.hspec-discover or (errorHandler.buildToolDepError "hspec-discover:hspec-discover")))
          ];
          buildable = true;
        };
      };
      benchmarks = {
        "tls-bench" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."QuickCheck" or (errorHandler.buildDepError "QuickCheck"))
            (hsPkgs."async" or (errorHandler.buildDepError "async"))
            (hsPkgs."base64-bytestring" or (errorHandler.buildDepError "base64-bytestring"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
            (hsPkgs."crypton" or (errorHandler.buildDepError "crypton"))
            (hsPkgs."crypton-asn1-types" or (errorHandler.buildDepError "crypton-asn1-types"))
            (hsPkgs."crypton-x509" or (errorHandler.buildDepError "crypton-x509"))
            (hsPkgs."crypton-x509-store" or (errorHandler.buildDepError "crypton-x509-store"))
            (hsPkgs."crypton-x509-validation" or (errorHandler.buildDepError "crypton-x509-validation"))
            (hsPkgs."data-default" or (errorHandler.buildDepError "data-default"))
            (hsPkgs."ech-config" or (errorHandler.buildDepError "ech-config"))
            (hsPkgs."hspec" or (errorHandler.buildDepError "hspec"))
            (hsPkgs."network" or (errorHandler.buildDepError "network"))
            (hsPkgs."network-run" or (errorHandler.buildDepError "network-run"))
            (hsPkgs."serialise" or (errorHandler.buildDepError "serialise"))
            (hsPkgs."tasty-bench" or (errorHandler.buildDepError "tasty-bench"))
            (hsPkgs."time-hourglass" or (errorHandler.buildDepError "time-hourglass"))
            (hsPkgs."tls" or (errorHandler.buildDepError "tls"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/tls-2.3.0.tar.gz";
      sha256 = "a33fd4bccad21f918025fbb1afc4e5e66ac5632285bd15012dac062f82fc56fe";
    });
  }) // {
    package-description-override = "cabal-version:      >=1.10\nname:               tls\nversion:            2.3.0\nlicense:            BSD3\nlicense-file:       LICENSE\ncopyright:          Vincent Hanquez <vincent@snarc.org>\nmaintainer:         Kazu Yamamoto <kazu@iij.ad.jp>\nauthor:             Vincent Hanquez <vincent@snarc.org>\nhomepage:           https://github.com/haskell-tls/hs-tls\nsynopsis:           TLS protocol native implementation\ndescription:\n    Native Haskell TLS 1.2/1.3 protocol implementation for servers and clients.\n\ncategory:           Network\nbuild-type:         Simple\nextra-source-files:\n    test/*.hs\n    CHANGELOG.md\n\nsource-repository head\n    type:     git\n    location: https://github.com/haskell-tls/hs-tls\n    subdir:   tls\n\nflag devel\n    description: Development commands\n    default:     False\n\nlibrary\n    exposed-modules:\n        Network.TLS\n        Network.TLS.Cipher\n        Network.TLS.Compression\n        Network.TLS.Internal\n        Network.TLS.Extra\n        Network.TLS.Extra.Cipher\n        Network.TLS.Extra.FFDHE\n        Network.TLS.QUIC\n\n    other-modules:\n        Network.TLS.Struct\n        Network.TLS.Struct13\n        Network.TLS.Core\n        Network.TLS.Context\n        Network.TLS.Context.Internal\n        Network.TLS.Credentials\n        Network.TLS.Backend\n        Network.TLS.Crypto\n        Network.TLS.Crypto.DH\n        Network.TLS.Crypto.IES\n        Network.TLS.Crypto.Types\n        Network.TLS.ErrT\n        Network.TLS.Error\n        Network.TLS.Extension\n        Network.TLS.Handshake\n        Network.TLS.Handshake.Certificate\n        Network.TLS.Handshake.Client\n        Network.TLS.Handshake.Client.ClientHello\n        Network.TLS.Handshake.Client.Common\n        Network.TLS.Handshake.Client.ServerHello\n        Network.TLS.Handshake.Client.TLS12\n        Network.TLS.Handshake.Client.TLS13\n        Network.TLS.Handshake.Common\n        Network.TLS.Handshake.Common13\n        Network.TLS.Handshake.Control\n        Network.TLS.Handshake.Key\n        Network.TLS.Handshake.Random\n        Network.TLS.Handshake.Server\n        Network.TLS.Handshake.Server.ClientHello\n        Network.TLS.Handshake.Server.ClientHello12\n        Network.TLS.Handshake.Server.ClientHello13\n        Network.TLS.Handshake.Server.Common\n        Network.TLS.Handshake.Server.ServerHello12\n        Network.TLS.Handshake.Server.ServerHello13\n        Network.TLS.Handshake.Server.TLS12\n        Network.TLS.Handshake.Server.TLS13\n        Network.TLS.Handshake.Signature\n        Network.TLS.Handshake.State\n        Network.TLS.Handshake.State13\n        Network.TLS.Handshake.TranscriptHash\n        Network.TLS.HashAndSignature\n        Network.TLS.Hooks\n        Network.TLS.IO\n        Network.TLS.IO.Decode\n        Network.TLS.IO.Encode\n        Network.TLS.Imports\n        Network.TLS.KeySchedule\n        Network.TLS.MAC\n        Network.TLS.Measurement\n        Network.TLS.Packet\n        Network.TLS.Packet13\n        Network.TLS.Parameters\n        Network.TLS.PostHandshake\n        Network.TLS.RNG\n        Network.TLS.Record\n        Network.TLS.Record.Decrypt\n        Network.TLS.Record.Encrypt\n        Network.TLS.Record.Layer\n        Network.TLS.Record.Recv\n        Network.TLS.Record.Send\n        Network.TLS.Record.State\n        Network.TLS.Record.Types\n        Network.TLS.Session\n        Network.TLS.State\n        Network.TLS.Types\n        Network.TLS.Types.Cipher\n        Network.TLS.Types.Secret\n        Network.TLS.Types.Session\n        Network.TLS.Types.Version\n        Network.TLS.Util\n        Network.TLS.Util.ASN1\n        Network.TLS.Util.Serialization\n        Network.TLS.Wire\n        Network.TLS.X509\n\n    default-language:   Haskell2010\n    default-extensions: Strict StrictData\n    ghc-options:        -Wall\n    build-depends:\n        base >=4.9 && <5,\n        base16-bytestring,\n        bytestring >=0.10 && <0.13,\n        cereal >=0.5.3 && <0.6,\n        crypton >=1.1.0 && <1.2,\n        crypton-asn1-encoding >= 0.10.0 && < 0.11,\n        crypton-asn1-types >= 0.4.1 && < 0.5,\n        crypton-x509 >=1.9 && <1.10,\n        crypton-x509-store >=1.9 && <1.10,\n        crypton-x509-validation >=1.9 && <1.10,\n        data-default,\n        ech-config,\n        hpke >=0.1.0 && <0.2,\n        mtl >=2.2 && <2.4,\n        network >=3.1,\n        ram,\n        random >=1.2 && <1.4,\n        serialise >=0.2 && <0.3,\n        transformers >=0.5 && <0.7,\n        unix-time >=0.4.11 && <0.5,\n        zlib >=0.7 && <0.8\n\nexecutable tls-server\n    main-is:            tls-server.hs\n    hs-source-dirs:     util\n    other-modules:\n        Common\n        Server\n        Imports\n\n    default-language:   Haskell2010\n    default-extensions: Strict StrictData\n    ghc-options:        -Wall -threaded -rtsopts\n    build-depends:\n        base >=4.9 && <5,\n        base16-bytestring,\n        bytestring,\n        containers,\n        crypton,\n        crypton-x509-store,\n        crypton-x509-system,\n        ech-config,\n        network,\n        network-run,\n        tls\n\n    if flag(devel)\n\n    else\n        buildable: False\n\nexecutable tls-client\n    main-is:            tls-client.hs\n    hs-source-dirs:     util\n    other-modules:\n        Client\n        Common\n        Imports\n\n    default-language:   Haskell2010\n    default-extensions: Strict StrictData\n    ghc-options:        -Wall -threaded -rtsopts\n    build-depends:\n        base >=4.9 && <5,\n        base16-bytestring,\n        bytestring,\n        crypton,\n        crypton-x509-store,\n        crypton-x509-system,\n        ech-config,\n        network,\n        network-run >=0.5,\n        tls\n\n    if flag(devel)\n\n    else\n        buildable: False\n\ntest-suite spec\n    type:               exitcode-stdio-1.0\n    main-is:            Spec.hs\n    build-tool-depends: hspec-discover:hspec-discover\n    hs-source-dirs:     test\n    other-modules:\n        API\n        Arbitrary\n        Certificate\n        CiphersSpec\n        ECHSpec\n        EncodeSpec\n        HandshakeSpec\n        PipeChan\n        PubKey\n        Run\n        Session\n        ThreadSpec\n\n    default-language:   Haskell2010\n    default-extensions: Strict StrictData\n    ghc-options:        -Wall -threaded -rtsopts\n    build-depends:\n        base >=4.9 && <5,\n        QuickCheck,\n        async,\n        base64-bytestring,\n        bytestring,\n        crypton,\n        crypton-asn1-types,\n        crypton-x509,\n        crypton-x509-validation,\n        ech-config,\n        hspec,\n        serialise,\n        time-hourglass,\n        tls\n\nbenchmark tls-bench\n    type:             exitcode-stdio-1.0\n    main-is:          Benchmarks.hs\n    hs-source-dirs:   Benchmarks test\n    other-modules:\n        API\n        Arbitrary\n        Certificate\n        CiphersSpec\n        ECHSpec\n        EncodeSpec\n        HandshakeSpec\n        PipeChan\n        PubKey\n        Run\n        Session\n        ThreadSpec\n\n    default-language: Haskell2010\n    ghc-options:      -Wall\n    build-depends:\n        base >=4.9 && <5,\n        QuickCheck,\n        async,\n        base64-bytestring,\n        bytestring,\n        containers,\n        crypton,\n        crypton-asn1-types,\n        crypton-x509,\n        crypton-x509-store,\n        crypton-x509-validation,\n        data-default,\n        ech-config,\n        hspec,\n        network,\n        network-run,\n        serialise,\n        tasty-bench,\n        time-hourglass,\n        tls\n";
  }