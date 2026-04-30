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
    flags = { build-example = false; };
    package = {
      specVersion = "1.10";
      identifier = { name = "wai-extra"; version = "3.1.18"; };
      license = "MIT";
      copyright = "";
      maintainer = "michael@snoyman.com";
      author = "Michael Snoyman";
      homepage = "http://github.com/yesodweb/wai";
      url = "";
      synopsis = "Provides some basic WAI handlers and middleware.";
      description = "Provides basic WAI handler and middleware functionality:\n\n* WAI Testing Framework\n\nHspec testing facilities and helpers for WAI.\n\n* Event Source/Event Stream\n\nSend server events to the client. Compatible with the JavaScript\nEventSource API.\n\n* Accept Override\n\nOverride the Accept header in a request. Special handling for the\n_accept query parameter (which is used throughout WAI override the\nAccept header).\n\n* Add Headers\n\nWAI Middleware for adding arbitrary headers to an HTTP request.\n\n* Clean Path\n\nClean a request path to a canonical form.\n\n* Combine Headers\n\nCombine duplicate headers into one.\n\n* GZip Compression\n\nNegotiate HTTP payload gzip compression.\n\n* Health check endpoint\n\nAdd an empty health check endpoint.\n\n* HTTP Basic Authentication\n\nWAI Basic Authentication Middleware which uses Authorization header.\n\n* JSONP\n\n\\\"JSON with Padding\\\" middleware. Automatic wrapping of JSON\nresponses to convert into JSONP.\n\n* Method Override / Post\n\nAllows overriding of the HTTP request method via the _method query string\nparameter.\n\n* Request Logging\n\nRequest logging middleware for development and production environments\n\n* Request Rewrite\n\nRewrite request path info based on a custom conversion rules.\n\n* Select\n\nDynamically choose between Middlewares.\n\n* Stream Files\n\nConvert ResponseFile type responses into ResponseStream type.\n\n* Virtual Host\n\nRedirect incoming requests to a new host based on custom rules.\n\n\nAPI docs and the README are available at <http://www.stackage.org/package/wai-extra>.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."aeson" or (errorHandler.buildDepError "aeson"))
          (hsPkgs."ansi-terminal" or (errorHandler.buildDepError "ansi-terminal"))
          (hsPkgs."base64-bytestring" or (errorHandler.buildDepError "base64-bytestring"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          (hsPkgs."call-stack" or (errorHandler.buildDepError "call-stack"))
          (hsPkgs."case-insensitive" or (errorHandler.buildDepError "case-insensitive"))
          (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
          (hsPkgs."cookie" or (errorHandler.buildDepError "cookie"))
          (hsPkgs."data-default" or (errorHandler.buildDepError "data-default"))
          (hsPkgs."directory" or (errorHandler.buildDepError "directory"))
          (hsPkgs."fast-logger" or (errorHandler.buildDepError "fast-logger"))
          (hsPkgs."http-types" or (errorHandler.buildDepError "http-types"))
          (hsPkgs."HUnit" or (errorHandler.buildDepError "HUnit"))
          (hsPkgs."iproute" or (errorHandler.buildDepError "iproute"))
          (hsPkgs."network" or (errorHandler.buildDepError "network"))
          (hsPkgs."resourcet" or (errorHandler.buildDepError "resourcet"))
          (hsPkgs."streaming-commons" or (errorHandler.buildDepError "streaming-commons"))
          (hsPkgs."text" or (errorHandler.buildDepError "text"))
          (hsPkgs."time" or (errorHandler.buildDepError "time"))
          (hsPkgs."transformers" or (errorHandler.buildDepError "transformers"))
          (hsPkgs."vault" or (errorHandler.buildDepError "vault"))
          (hsPkgs."wai" or (errorHandler.buildDepError "wai"))
          (hsPkgs."wai-logger" or (errorHandler.buildDepError "wai-logger"))
          (hsPkgs."warp" or (errorHandler.buildDepError "warp"))
          (hsPkgs."word8" or (errorHandler.buildDepError "word8"))
        ] ++ pkgs.lib.optional (!system.isWindows) (hsPkgs."unix" or (errorHandler.buildDepError "unix"));
        buildable = true;
      };
      exes = {
        "example" = {
          depends = pkgs.lib.optionals (flags.build-example) [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."http-types" or (errorHandler.buildDepError "http-types"))
            (hsPkgs."time" or (errorHandler.buildDepError "time"))
            (hsPkgs."wai" or (errorHandler.buildDepError "wai"))
            (hsPkgs."wai-extra" or (errorHandler.buildDepError "wai-extra"))
            (hsPkgs."warp" or (errorHandler.buildDepError "warp"))
          ];
          buildable = if flags.build-example then true else false;
        };
      };
      tests = {
        "spec" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."aeson" or (errorHandler.buildDepError "aeson"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."cookie" or (errorHandler.buildDepError "cookie"))
            (hsPkgs."case-insensitive" or (errorHandler.buildDepError "case-insensitive"))
            (hsPkgs."directory" or (errorHandler.buildDepError "directory"))
            (hsPkgs."fast-logger" or (errorHandler.buildDepError "fast-logger"))
            (hsPkgs."hspec" or (errorHandler.buildDepError "hspec"))
            (hsPkgs."http-types" or (errorHandler.buildDepError "http-types"))
            (hsPkgs."HUnit" or (errorHandler.buildDepError "HUnit"))
            (hsPkgs."iproute" or (errorHandler.buildDepError "iproute"))
            (hsPkgs."resourcet" or (errorHandler.buildDepError "resourcet"))
            (hsPkgs."temporary" or (errorHandler.buildDepError "temporary"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
            (hsPkgs."time" or (errorHandler.buildDepError "time"))
            (hsPkgs."wai-extra" or (errorHandler.buildDepError "wai-extra"))
            (hsPkgs."wai" or (errorHandler.buildDepError "wai"))
            (hsPkgs."warp" or (errorHandler.buildDepError "warp"))
            (hsPkgs."word8" or (errorHandler.buildDepError "word8"))
            (hsPkgs."zlib" or (errorHandler.buildDepError "zlib"))
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
      url = "http://hackage.haskell.org/package/wai-extra-3.1.18.tar.gz";
      sha256 = "ee63740b8dd478b01196f8968603b1bc0ee00aa5502d17edae579abfd0f150f7";
    });
  }) // {
    package-description-override = "Name:                wai-extra\nVersion:             3.1.18\nSynopsis:            Provides some basic WAI handlers and middleware.\ndescription:\n  Provides basic WAI handler and middleware functionality:\n  .\n  * WAI Testing Framework\n  .\n  Hspec testing facilities and helpers for WAI.\n  .\n  * Event Source/Event Stream\n  .\n  Send server events to the client. Compatible with the JavaScript\n  EventSource API.\n  .\n  * Accept Override\n  .\n  Override the Accept header in a request. Special handling for the\n  _accept query parameter (which is used throughout WAI override the\n  Accept header).\n  .\n  * Add Headers\n  .\n  WAI Middleware for adding arbitrary headers to an HTTP request.\n  .\n  * Clean Path\n  .\n  Clean a request path to a canonical form.\n  .\n  * Combine Headers\n  .\n  Combine duplicate headers into one.\n  .\n  * GZip Compression\n  .\n  Negotiate HTTP payload gzip compression.\n  .\n  * Health check endpoint\n  .\n  Add an empty health check endpoint.\n  .\n  * HTTP Basic Authentication\n  .\n  WAI Basic Authentication Middleware which uses Authorization header.\n  .\n  * JSONP\n  .\n  \\\"JSON with Padding\\\" middleware. Automatic wrapping of JSON\n  responses to convert into JSONP.\n  .\n  * Method Override / Post\n  .\n  Allows overriding of the HTTP request method via the _method query string\n  parameter.\n  .\n  * Request Logging\n  .\n  Request logging middleware for development and production environments\n  .\n  * Request Rewrite\n  .\n  Rewrite request path info based on a custom conversion rules.\n  .\n  * Select\n  .\n  Dynamically choose between Middlewares.\n  .\n  * Stream Files\n  .\n  Convert ResponseFile type responses into ResponseStream type.\n  .\n  * Virtual Host\n  .\n  Redirect incoming requests to a new host based on custom rules.\n  .\n  .\n  API docs and the README are available at <http://www.stackage.org/package/wai-extra>.\n\nLicense:             MIT\nLicense-file:        LICENSE\nAuthor:              Michael Snoyman\nMaintainer:          michael@snoyman.com\nHomepage:            http://github.com/yesodweb/wai\nCategory:            Web\nBuild-Type:          Simple\nCabal-Version:       >=1.10\nStability:           Stable\nextra-source-files:\n  test/requests/dalvik-request\n  test/json\n  test/json.gz\n  test/noprecompress\n  test/test.html\n  test/sample.hs\n  ChangeLog.md\n  README.md\n\nflag build-example\n  description:        Build example executable.\n  manual:             True\n  default:            False\n\nLibrary\n  Build-Depends:     base                      >= 4.12 && < 5\n                   , aeson\n                   , ansi-terminal             >= 0.4\n                   , base64-bytestring\n                   , bytestring                >= 0.10.4\n                   , call-stack\n                   , case-insensitive          >= 0.2\n                   , containers\n                   , cookie\n                   , data-default\n                   , directory                 >= 1.2.7.0\n                   , fast-logger               >= 2.4.5\n                   , http-types                >= 0.7\n                   , HUnit\n                   , iproute                   >= 1.7.8\n                   , network                   >= 2.6.1.0\n                   , resourcet                 >= 0.4.6    && < 1.4\n                   , streaming-commons         >= 0.2\n                   , text                      >= 0.7\n                   , time                      >= 1.1.4\n                   , transformers              >= 0.2.2\n                   , vault\n                   , wai                       >= 3.2.4    && < 3.3\n                   , wai-logger                >= 2.3.7\n                   , warp                      >= 3.3.22\n                   , word8\n\n  if os(windows)\n      cpp-options:   -DWINDOWS\n  else\n      build-depends: unix\n\n  default-extensions:        OverloadedStrings\n\n  Exposed-modules:   Network.Wai.EventSource\n                     Network.Wai.EventSource.EventStream\n                     Network.Wai.Handler.CGI\n                     Network.Wai.Handler.SCGI\n                     Network.Wai.Header\n                     Network.Wai.Middleware.AcceptOverride\n                     Network.Wai.Middleware.AddHeaders\n                     Network.Wai.Middleware.Approot\n                     Network.Wai.Middleware.Autohead\n                     Network.Wai.Middleware.CleanPath\n                     Network.Wai.Middleware.CombineHeaders\n                     Network.Wai.Middleware.ForceDomain\n                     Network.Wai.Middleware.ForceSSL\n                     Network.Wai.Middleware.Gzip\n                     Network.Wai.Middleware.HealthCheckEndpoint\n                     Network.Wai.Middleware.HttpAuth\n                     Network.Wai.Middleware.Jsonp\n                     Network.Wai.Middleware.Local\n                     Network.Wai.Middleware.MethodOverride\n                     Network.Wai.Middleware.MethodOverridePost\n                     Network.Wai.Middleware.RealIp\n                     Network.Wai.Middleware.RequestLogger\n                     Network.Wai.Middleware.RequestLogger.JSON\n                     Network.Wai.Middleware.RequestSizeLimit\n                     Network.Wai.Middleware.RequestSizeLimit.Internal\n                     Network.Wai.Middleware.Rewrite\n                     Network.Wai.Middleware.Routed\n                     Network.Wai.Middleware.Select\n                     Network.Wai.Middleware.StreamFile\n                     Network.Wai.Middleware.StripHeaders\n                     Network.Wai.Middleware.Timeout\n                     Network.Wai.Middleware.ValidateHeaders\n                     Network.Wai.Middleware.Vhost\n                     Network.Wai.Parse\n                     Network.Wai.Request\n                     Network.Wai.Test\n                     Network.Wai.Test.Internal\n                     Network.Wai.UrlMap\n  other-modules:     Network.Wai.Middleware.RequestLogger.Internal\n                     Network.Wai.Util\n  default-language:          Haskell2010\n  ghc-options:       -Wall\n\nexecutable example\n  hs-source-dirs:      example\n  main-is:             Main.hs\n  ghc-options:         -threaded -rtsopts -with-rtsopts=-N -Wall\n  if flag(build-example)\n    build-depends:     base\n                     , bytestring\n                     , http-types\n                     , time\n                     , wai\n                     , wai-extra\n                     , warp\n  else\n    buildable: False\n  default-language:    Haskell2010\n\ntest-suite spec\n    type:            exitcode-stdio-1.0\n    hs-source-dirs:  test\n    main-is:         Spec.hs\n    other-modules:   Network.Wai.Middleware.ApprootSpec\n                     Network.Wai.Middleware.CombineHeadersSpec\n                     Network.Wai.Middleware.ForceSSLSpec\n                     Network.Wai.Middleware.RealIpSpec\n                     Network.Wai.Middleware.RequestSizeLimitSpec\n                     Network.Wai.Middleware.RoutedSpec\n                     Network.Wai.Middleware.SelectSpec\n                     Network.Wai.Middleware.StripHeadersSpec\n                     Network.Wai.Middleware.TimeoutSpec\n                     Network.Wai.Middleware.ValidateHeadersSpec\n                     Network.Wai.ParseSpec\n                     Network.Wai.RequestSpec\n                     Network.Wai.TestSpec\n                     WaiExtraSpec\n    build-tool-depends: hspec-discover:hspec-discover\n    build-depends:   base                      >= 4        && < 5\n                   , aeson\n                   , bytestring\n                   , cookie\n                   , case-insensitive\n                   , directory\n                   , fast-logger\n                   , hspec >= 1.3\n                   , http-types\n                   , HUnit\n                   , iproute\n                   , resourcet\n                   , temporary\n                   , text\n                   , time\n                   , wai-extra\n                   , wai\n                   , warp\n                   , word8\n                   , zlib\n    ghc-options:     -Wall\n    default-language:          Haskell2010\n\n    if os(windows)\n        cpp-options:   -DWINDOWS\n\nsource-repository head\n  type:     git\n  location: git://github.com/yesodweb/wai.git\n";
  }