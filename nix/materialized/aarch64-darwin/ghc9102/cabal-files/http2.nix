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
    flags = { devel = false; h2spec = false; };
    package = {
      specVersion = "1.10";
      identifier = { name = "http2"; version = "5.4.0"; };
      license = "BSD-3-Clause";
      copyright = "";
      maintainer = "Kazu Yamamoto <kazu@iij.ad.jp>";
      author = "Kazu Yamamoto <kazu@iij.ad.jp>";
      homepage = "https://github.com/kazu-yamamoto/http2";
      url = "";
      synopsis = "HTTP/2 library";
      description = "HTTP/2 library including frames, priority queues, HPACK, client and server.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."array" or (errorHandler.buildDepError "array"))
          (hsPkgs."async" or (errorHandler.buildDepError "async"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          (hsPkgs."case-insensitive" or (errorHandler.buildDepError "case-insensitive"))
          (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
          (hsPkgs."http-semantics" or (errorHandler.buildDepError "http-semantics"))
          (hsPkgs."http-types" or (errorHandler.buildDepError "http-types"))
          (hsPkgs."iproute" or (errorHandler.buildDepError "iproute"))
          (hsPkgs."network" or (errorHandler.buildDepError "network"))
          (hsPkgs."network-byte-order" or (errorHandler.buildDepError "network-byte-order"))
          (hsPkgs."network-control" or (errorHandler.buildDepError "network-control"))
          (hsPkgs."stm" or (errorHandler.buildDepError "stm"))
          (hsPkgs."time-manager" or (errorHandler.buildDepError "time-manager"))
          (hsPkgs."unix-time" or (errorHandler.buildDepError "unix-time"))
          (hsPkgs."utf8-string" or (errorHandler.buildDepError "utf8-string"))
        ];
        buildable = true;
      };
      exes = {
        "h2c-client" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."async" or (errorHandler.buildDepError "async"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."http-types" or (errorHandler.buildDepError "http-types"))
            (hsPkgs."http2" or (errorHandler.buildDepError "http2"))
            (hsPkgs."network" or (errorHandler.buildDepError "network"))
            (hsPkgs."network-run" or (errorHandler.buildDepError "network-run"))
            (hsPkgs."unix-time" or (errorHandler.buildDepError "unix-time"))
          ];
          buildable = if flags.devel then true else false;
        };
        "h2c-server" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."crypton" or (errorHandler.buildDepError "crypton"))
            (hsPkgs."http2" or (errorHandler.buildDepError "http2"))
            (hsPkgs."http-types" or (errorHandler.buildDepError "http-types"))
            (hsPkgs."network-run" or (errorHandler.buildDepError "network-run"))
          ];
          buildable = if flags.devel then true else false;
        };
        "hpack-encode" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."aeson" or (errorHandler.buildDepError "aeson"))
            (hsPkgs."aeson-pretty" or (errorHandler.buildDepError "aeson-pretty"))
            (hsPkgs."array" or (errorHandler.buildDepError "array"))
            (hsPkgs."base16-bytestring" or (errorHandler.buildDepError "base16-bytestring"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
            (hsPkgs."http2" or (errorHandler.buildDepError "http2"))
            (hsPkgs."network-byte-order" or (errorHandler.buildDepError "network-byte-order"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
            (hsPkgs."unordered-containers" or (errorHandler.buildDepError "unordered-containers"))
            (hsPkgs."vector" or (errorHandler.buildDepError "vector"))
            (hsPkgs."word8" or (errorHandler.buildDepError "word8"))
          ];
          buildable = if flags.devel then true else false;
        };
        "hpack-debug" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."aeson" or (errorHandler.buildDepError "aeson"))
            (hsPkgs."array" or (errorHandler.buildDepError "array"))
            (hsPkgs."base16-bytestring" or (errorHandler.buildDepError "base16-bytestring"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
            (hsPkgs."http2" or (errorHandler.buildDepError "http2"))
            (hsPkgs."network-byte-order" or (errorHandler.buildDepError "network-byte-order"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
            (hsPkgs."unordered-containers" or (errorHandler.buildDepError "unordered-containers"))
            (hsPkgs."vector" or (errorHandler.buildDepError "vector"))
            (hsPkgs."word8" or (errorHandler.buildDepError "word8"))
          ];
          buildable = if flags.devel then true else false;
        };
        "hpack-stat" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."aeson" or (errorHandler.buildDepError "aeson"))
            (hsPkgs."aeson-pretty" or (errorHandler.buildDepError "aeson-pretty"))
            (hsPkgs."array" or (errorHandler.buildDepError "array"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
            (hsPkgs."directory" or (errorHandler.buildDepError "directory"))
            (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
            (hsPkgs."http2" or (errorHandler.buildDepError "http2"))
            (hsPkgs."network-byte-order" or (errorHandler.buildDepError "network-byte-order"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
            (hsPkgs."unordered-containers" or (errorHandler.buildDepError "unordered-containers"))
            (hsPkgs."vector" or (errorHandler.buildDepError "vector"))
            (hsPkgs."word8" or (errorHandler.buildDepError "word8"))
          ];
          buildable = if flags.devel then true else false;
        };
        "frame-encode" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."aeson" or (errorHandler.buildDepError "aeson"))
            (hsPkgs."aeson-pretty" or (errorHandler.buildDepError "aeson-pretty"))
            (hsPkgs."base16-bytestring" or (errorHandler.buildDepError "base16-bytestring"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."http2" or (errorHandler.buildDepError "http2"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
            (hsPkgs."unordered-containers" or (errorHandler.buildDepError "unordered-containers"))
          ];
          buildable = if flags.devel then true else false;
        };
      };
      tests = {
        "spec" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."async" or (errorHandler.buildDepError "async"))
            (hsPkgs."base16-bytestring" or (errorHandler.buildDepError "base16-bytestring"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."crypton" or (errorHandler.buildDepError "crypton"))
            (hsPkgs."hspec" or (errorHandler.buildDepError "hspec"))
            (hsPkgs."http-semantics" or (errorHandler.buildDepError "http-semantics"))
            (hsPkgs."http-types" or (errorHandler.buildDepError "http-types"))
            (hsPkgs."http2" or (errorHandler.buildDepError "http2"))
            (hsPkgs."network" or (errorHandler.buildDepError "network"))
            (hsPkgs."network-run" or (errorHandler.buildDepError "network-run"))
            (hsPkgs."random" or (errorHandler.buildDepError "random"))
            (hsPkgs."typed-process" or (errorHandler.buildDepError "typed-process"))
          ];
          build-tools = [
            (hsPkgs.pkgsBuildBuild.hspec-discover.components.exes.hspec-discover or (pkgs.pkgsBuildBuild.hspec-discover or (errorHandler.buildToolDepError "hspec-discover:hspec-discover")))
          ];
          buildable = true;
        };
        "spec2" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."hspec" or (errorHandler.buildDepError "hspec"))
            (hsPkgs."http-types" or (errorHandler.buildDepError "http-types"))
            (hsPkgs."http2" or (errorHandler.buildDepError "http2"))
            (hsPkgs."network-run" or (errorHandler.buildDepError "network-run"))
            (hsPkgs."typed-process" or (errorHandler.buildDepError "typed-process"))
          ];
          build-tools = [
            (hsPkgs.pkgsBuildBuild.hspec-discover.components.exes.hspec-discover or (pkgs.pkgsBuildBuild.hspec-discover or (errorHandler.buildToolDepError "hspec-discover:hspec-discover")))
          ];
          buildable = if flags.h2spec then true else false;
        };
        "hpack" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."aeson" or (errorHandler.buildDepError "aeson"))
            (hsPkgs."base16-bytestring" or (errorHandler.buildDepError "base16-bytestring"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."directory" or (errorHandler.buildDepError "directory"))
            (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
            (hsPkgs."hspec" or (errorHandler.buildDepError "hspec"))
            (hsPkgs."http2" or (errorHandler.buildDepError "http2"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
            (hsPkgs."unordered-containers" or (errorHandler.buildDepError "unordered-containers"))
            (hsPkgs."vector" or (errorHandler.buildDepError "vector"))
          ];
          build-tools = [
            (hsPkgs.pkgsBuildBuild.hspec-discover.components.exes.hspec-discover or (pkgs.pkgsBuildBuild.hspec-discover or (errorHandler.buildToolDepError "hspec-discover:hspec-discover")))
          ];
          buildable = true;
        };
        "frame" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."Glob" or (errorHandler.buildDepError "Glob"))
            (hsPkgs."aeson" or (errorHandler.buildDepError "aeson"))
            (hsPkgs."aeson-pretty" or (errorHandler.buildDepError "aeson-pretty"))
            (hsPkgs."base16-bytestring" or (errorHandler.buildDepError "base16-bytestring"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."directory" or (errorHandler.buildDepError "directory"))
            (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
            (hsPkgs."hspec" or (errorHandler.buildDepError "hspec"))
            (hsPkgs."http2" or (errorHandler.buildDepError "http2"))
            (hsPkgs."network-byte-order" or (errorHandler.buildDepError "network-byte-order"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
            (hsPkgs."unordered-containers" or (errorHandler.buildDepError "unordered-containers"))
          ];
          build-tools = [
            (hsPkgs.pkgsBuildBuild.hspec-discover.components.exes.hspec-discover or (pkgs.pkgsBuildBuild.hspec-discover or (errorHandler.buildToolDepError "hspec-discover:hspec-discover")))
          ];
          buildable = true;
        };
      };
      benchmarks = {
        "header-compression" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."array" or (errorHandler.buildDepError "array"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."case-insensitive" or (errorHandler.buildDepError "case-insensitive"))
            (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
            (hsPkgs."criterion" or (errorHandler.buildDepError "criterion"))
            (hsPkgs."http2" or (errorHandler.buildDepError "http2"))
            (hsPkgs."network-byte-order" or (errorHandler.buildDepError "network-byte-order"))
            (hsPkgs."stm" or (errorHandler.buildDepError "stm"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/http2-5.4.0.tar.gz";
      sha256 = "b83df78feefd2dde21edcc7a415d674ada5249808c220d9339cd35c09c421227";
    });
  }) // {
    package-description-override = "cabal-version:      >=1.10\r\nname:               http2\r\nversion:            5.4.0\r\nx-revision: 1\r\nlicense:            BSD3\r\nlicense-file:       LICENSE\r\nmaintainer:         Kazu Yamamoto <kazu@iij.ad.jp>\r\nauthor:             Kazu Yamamoto <kazu@iij.ad.jp>\r\nhomepage:           https://github.com/kazu-yamamoto/http2\r\nsynopsis:           HTTP/2 library\r\ndescription:\r\n    HTTP/2 library including frames, priority queues, HPACK, client and server.\r\n\r\ncategory:           Network\r\nbuild-type:         Simple\r\nextra-source-files:\r\n    ChangeLog.md\r\n    test/inputFile\r\n    test-hpack/hpack-test-case/go-hpack/*.json\r\n    test-hpack/hpack-test-case/haskell-http2-linear/*.json\r\n    test-hpack/hpack-test-case/haskell-http2-linear-huffman/*.json\r\n    test-hpack/hpack-test-case/haskell-http2-naive/*.json\r\n    test-hpack/hpack-test-case/haskell-http2-naive-huffman/*.json\r\n    test-hpack/hpack-test-case/haskell-http2-static/*.json\r\n    test-hpack/hpack-test-case/haskell-http2-static-huffman/*.json\r\n    test-hpack/hpack-test-case/nghttp2/*.json\r\n    test-hpack/hpack-test-case/nghttp2-16384-4096/*.json\r\n    test-hpack/hpack-test-case/nghttp2-change-table-size/*.json\r\n    test-hpack/hpack-test-case/node-http2-hpack/*.json\r\n    test-frame/http2-frame-test-case/continuation/*.json\r\n    test-frame/http2-frame-test-case/data/*.json\r\n    test-frame/http2-frame-test-case/error/*.json\r\n    test-frame/http2-frame-test-case/goaway/*.json\r\n    test-frame/http2-frame-test-case/headers/*.json\r\n    test-frame/http2-frame-test-case/ping/*.json\r\n    test-frame/http2-frame-test-case/priority/*.json\r\n    test-frame/http2-frame-test-case/push_promise/*.json\r\n    test-frame/http2-frame-test-case/rst_stream/*.json\r\n    test-frame/http2-frame-test-case/settings/*.json\r\n    test-frame/http2-frame-test-case/window_update/*.json\r\n    bench-hpack/headers.hs\r\n\r\nsource-repository head\r\n    type:     git\r\n    location: https://github.com/kazu-yamamoto/http2\r\n\r\nflag devel\r\n    description: Development commands\r\n    default:     False\r\n\r\nflag h2spec\r\n    description: Development commands\r\n    default:     False\r\n\r\nlibrary\r\n    exposed-modules:\r\n        Network.HPACK\r\n        Network.HPACK.Internal\r\n        Network.HPACK.Table\r\n        Network.HPACK.Token\r\n        Network.HTTP2.Client\r\n        Network.HTTP2.Client.Internal\r\n        Network.HTTP2.Frame\r\n        Network.HTTP2.Server\r\n        Network.HTTP2.Server.Internal\r\n\r\n    other-modules:\r\n        Imports\r\n        Network.HPACK.Builder\r\n        Network.HTTP2.Client.Run\r\n        Network.HPACK.HeaderBlock\r\n        Network.HPACK.HeaderBlock.Decode\r\n        Network.HPACK.HeaderBlock.Encode\r\n        Network.HPACK.HeaderBlock.Integer\r\n        Network.HPACK.Huffman\r\n        Network.HPACK.Huffman.Bit\r\n        Network.HPACK.Huffman.ByteString\r\n        Network.HPACK.Huffman.Decode\r\n        Network.HPACK.Huffman.Encode\r\n        Network.HPACK.Huffman.Params\r\n        Network.HPACK.Huffman.Table\r\n        Network.HPACK.Huffman.Tree\r\n        Network.HPACK.Table.Dynamic\r\n        Network.HPACK.Table.Entry\r\n        Network.HPACK.Table.RevIndex\r\n        Network.HPACK.Table.Static\r\n        Network.HPACK.Types\r\n        Network.HTTP2.H2\r\n        Network.HTTP2.H2.Config\r\n        Network.HTTP2.H2.Context\r\n        Network.HTTP2.H2.EncodeFrame\r\n        Network.HTTP2.H2.HPACK\r\n        Network.HTTP2.H2.Queue\r\n        Network.HTTP2.H2.Receiver\r\n        Network.HTTP2.H2.Sender\r\n        Network.HTTP2.H2.Settings\r\n        Network.HTTP2.H2.Stream\r\n        Network.HTTP2.H2.StreamTable\r\n        Network.HTTP2.H2.Sync\r\n        Network.HTTP2.H2.Types\r\n        Network.HTTP2.H2.Window\r\n        Network.HTTP2.Frame.Decode\r\n        Network.HTTP2.Frame.Encode\r\n        Network.HTTP2.Frame.Types\r\n        Network.HTTP2.Server.Run\r\n        Network.HTTP2.Server.Worker\r\n\r\n    default-language:   Haskell2010\r\n    default-extensions: Strict StrictData\r\n    ghc-options:        -Wall\r\n    build-depends:\r\n        base >=4.9 && <5,\r\n        array >=0.5 && <0.6,\r\n        async >=2.2 && <2.3,\r\n        bytestring >=0.10,\r\n        case-insensitive >=1.2 && <1.3,\r\n        containers >=0.6,\r\n        http-semantics >= 0.4 && <0.5,\r\n        http-types >=0.12 && <0.13,\r\n        iproute >= 1.7 && < 1.8,\r\n        network >=3.1,\r\n        network-byte-order >=0.1.7 && <0.2,\r\n        network-control >=0.1 && <0.2,\r\n        stm >=2.5 && <2.6,\r\n        time-manager >=0.2.3 && <0.4,\r\n        unix-time >=0.4.11 && <0.6,\r\n        utf8-string >=1.0 && <1.1\r\n\r\nexecutable h2c-client\r\n    main-is:            h2c-client.hs\r\n    hs-source-dirs:     util\r\n    default-language:   Haskell2010\r\n    other-modules:      Client Monitor\r\n    default-extensions: Strict StrictData\r\n    ghc-options:        -Wall -threaded -rtsopts\r\n    build-depends:\r\n        base >=4.9 && <5,\r\n        async,\r\n        bytestring,\r\n        http-types,\r\n        http2,\r\n        network,\r\n        network-run >= 0.5 && <0.6,\r\n        unix-time\r\n\r\n    if flag(devel)\r\n\r\n    else\r\n        buildable: False\r\n\r\nexecutable h2c-server\r\n    main-is:            h2c-server.hs\r\n    hs-source-dirs:     util\r\n    other-modules:      Server Monitor\r\n    default-language:   Haskell2010\r\n    default-extensions: Strict StrictData\r\n    ghc-options:        -Wall -threaded\r\n    build-depends:\r\n        base >=4.9 && <5,\r\n        bytestring,\r\n        crypton,\r\n        http2,\r\n        http-types,\r\n        network-run\r\n\r\n    if flag(devel)\r\n\r\n    else\r\n        buildable: False\r\n\r\nexecutable hpack-encode\r\n    main-is:            hpack-encode.hs\r\n    hs-source-dirs:     test-hpack\r\n    other-modules:\r\n        HPACKEncode\r\n        JSON\r\n\r\n    default-language:   Haskell2010\r\n    default-extensions: Strict StrictData\r\n    ghc-options:        -Wall\r\n    build-depends:\r\n        base >=4.9 && <5,\r\n        aeson >=2,\r\n        aeson-pretty,\r\n        array,\r\n        base16-bytestring >=1.0,\r\n        bytestring,\r\n        containers,\r\n        http2,\r\n        network-byte-order,\r\n        text,\r\n        unordered-containers,\r\n        vector,\r\n        word8\r\n\r\n    if flag(devel)\r\n\r\n    else\r\n        buildable: False\r\n\r\nexecutable hpack-debug\r\n    main-is:            hpack-debug.hs\r\n    hs-source-dirs:     test-hpack\r\n    other-modules:\r\n        HPACKDecode\r\n        JSON\r\n\r\n    default-language:   Haskell2010\r\n    default-extensions: Strict StrictData\r\n    ghc-options:        -Wall\r\n    build-depends:\r\n        base >=4.9 && <5,\r\n        aeson >=2,\r\n        array,\r\n        base16-bytestring >=1.0,\r\n        bytestring,\r\n        containers,\r\n        http2,\r\n        network-byte-order,\r\n        text,\r\n        unordered-containers,\r\n        vector,\r\n        word8\r\n\r\n    if flag(devel)\r\n\r\n    else\r\n        buildable: False\r\n\r\nexecutable hpack-stat\r\n    main-is:            hpack-stat.hs\r\n    hs-source-dirs:     test-hpack\r\n    other-modules:      JSON\r\n    default-language:   Haskell2010\r\n    default-extensions: Strict StrictData\r\n    ghc-options:        -Wall\r\n    build-depends:\r\n        base >=4.9 && <5,\r\n        aeson >=2,\r\n        aeson-pretty,\r\n        array,\r\n        bytestring,\r\n        containers,\r\n        directory,\r\n        filepath,\r\n        http2,\r\n        network-byte-order,\r\n        text,\r\n        unordered-containers,\r\n        vector,\r\n        word8\r\n\r\n    if flag(devel)\r\n\r\n    else\r\n        buildable: False\r\n\r\nexecutable frame-encode\r\n    main-is:            frame-encode.hs\r\n    hs-source-dirs:     test-frame\r\n    other-modules:\r\n        Case\r\n        JSON\r\n\r\n    default-language:   Haskell2010\r\n    default-extensions: Strict StrictData\r\n    ghc-options:        -Wall\r\n    build-depends:\r\n        base >=4.9 && <5,\r\n        aeson >=2,\r\n        aeson-pretty,\r\n        base16-bytestring >=1.0,\r\n        bytestring,\r\n        http2,\r\n        text,\r\n        unordered-containers\r\n\r\n    if flag(devel)\r\n\r\n    else\r\n        buildable: False\r\n\r\ntest-suite spec\r\n    type:               exitcode-stdio-1.0\r\n    main-is:            Spec.hs\r\n    build-tool-depends: hspec-discover:hspec-discover\r\n    hs-source-dirs:     test\r\n    other-modules:\r\n        HPACK.DecodeSpec\r\n        HPACK.EncodeSpec\r\n        HPACK.HeaderBlock\r\n        HPACK.HuffmanSpec\r\n        HPACK.IntegerSpec\r\n        HTTP2.ClientSpec\r\n        HTTP2.FrameSpec\r\n        HTTP2.ServerSpec\r\n\r\n    default-language:   Haskell2010\r\n    default-extensions: Strict StrictData\r\n    ghc-options:        -Wall -threaded\r\n    build-depends:\r\n        base >=4.9 && <5,\r\n        async,\r\n        base16-bytestring >=1.0,\r\n        bytestring,\r\n        crypton,\r\n        hspec >=1.3,\r\n        http-semantics,\r\n        http-types,\r\n        http2,\r\n        network,\r\n        network-run >= 0.5 && <0.6,\r\n        random,\r\n        typed-process\r\n\r\ntest-suite spec2\r\n    type:               exitcode-stdio-1.0\r\n    main-is:            Spec.hs\r\n    build-tool-depends: hspec-discover:hspec-discover\r\n    hs-source-dirs:     test2\r\n    other-modules:      ServerSpec\r\n    default-language:   Haskell2010\r\n    default-extensions: Strict StrictData\r\n    ghc-options:        -Wall -threaded\r\n    build-depends:\r\n        base >=4.9 && <5,\r\n        bytestring,\r\n        hspec >=1.3,\r\n        http-types,\r\n        http2,\r\n        network-run >= 0.5 && <0.6,\r\n        typed-process\r\n\r\n    if flag(h2spec)\r\n\r\n    else\r\n        buildable: False\r\n\r\ntest-suite hpack\r\n    type:               exitcode-stdio-1.0\r\n    main-is:            Spec.hs\r\n    build-tool-depends: hspec-discover:hspec-discover\r\n    hs-source-dirs:     test-hpack\r\n    other-modules:\r\n        HPACKDecode\r\n        HPACKSpec\r\n        JSON\r\n\r\n    default-language:   Haskell2010\r\n    default-extensions: Strict StrictData\r\n    ghc-options:        -Wall\r\n    build-depends:\r\n        base >=4.9 && <5,\r\n        aeson >=2,\r\n        base16-bytestring >=1.0,\r\n        bytestring,\r\n        directory,\r\n        filepath,\r\n        hspec >=1.3,\r\n        http2,\r\n        text,\r\n        unordered-containers,\r\n        vector\r\n\r\ntest-suite frame\r\n    type:               exitcode-stdio-1.0\r\n    main-is:            Spec.hs\r\n    build-tool-depends: hspec-discover:hspec-discover\r\n    hs-source-dirs:     test-frame\r\n    other-modules:\r\n        Case\r\n        FrameSpec\r\n        JSON\r\n\r\n    default-language:   Haskell2010\r\n    default-extensions: Strict StrictData\r\n    ghc-options:        -Wall\r\n    build-depends:\r\n        base >=4.9 && <5,\r\n        Glob >=0.9,\r\n        aeson >=2,\r\n        aeson-pretty,\r\n        base16-bytestring >=1.0,\r\n        bytestring,\r\n        directory,\r\n        filepath,\r\n        hspec >=1.3,\r\n        http2,\r\n        network-byte-order,\r\n        text,\r\n        unordered-containers\r\n\r\nbenchmark header-compression\r\n    type:               exitcode-stdio-1.0\r\n    main-is:            Main.hs\r\n    hs-source-dirs:     bench-hpack\r\n    default-language:   Haskell2010\r\n    default-extensions: Strict StrictData\r\n    ghc-options:        -Wall\r\n    build-depends:\r\n        base,\r\n        array,\r\n        bytestring,\r\n        case-insensitive,\r\n        containers,\r\n        criterion,\r\n        http2,\r\n        network-byte-order,\r\n        stm\r\n";
  }