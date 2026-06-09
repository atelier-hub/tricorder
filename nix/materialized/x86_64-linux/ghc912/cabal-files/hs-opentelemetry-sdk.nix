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
      specVersion = "1.22";
      identifier = { name = "hs-opentelemetry-sdk"; version = "0.1.0.1"; };
      license = "BSD-3-Clause";
      copyright = "2024 Ian Duncan, Mercury Technologies";
      maintainer = "ian@iankduncan.com";
      author = "Ian Duncan, Jade Lovelace";
      homepage = "https://github.com/iand675/hs-opentelemetry#readme";
      url = "";
      synopsis = "OpenTelemetry SDK for use in applications.";
      description = "Please see the README on GitHub at <https://github.com/iand675/hs-opentelemetry/tree/main/sdk#readme>";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."async" or (errorHandler.buildDepError "async"))
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          (hsPkgs."hs-opentelemetry-api" or (errorHandler.buildDepError "hs-opentelemetry-api"))
          (hsPkgs."hs-opentelemetry-exporter-otlp" or (errorHandler.buildDepError "hs-opentelemetry-exporter-otlp"))
          (hsPkgs."hs-opentelemetry-propagator-b3" or (errorHandler.buildDepError "hs-opentelemetry-propagator-b3"))
          (hsPkgs."hs-opentelemetry-propagator-datadog" or (errorHandler.buildDepError "hs-opentelemetry-propagator-datadog"))
          (hsPkgs."hs-opentelemetry-propagator-w3c" or (errorHandler.buildDepError "hs-opentelemetry-propagator-w3c"))
          (hsPkgs."http-types" or (errorHandler.buildDepError "http-types"))
          (hsPkgs."network-bsd" or (errorHandler.buildDepError "network-bsd"))
          (hsPkgs."random" or (errorHandler.buildDepError "random"))
          (hsPkgs."stm" or (errorHandler.buildDepError "stm"))
          (hsPkgs."text" or (errorHandler.buildDepError "text"))
          (hsPkgs."unagi-chan" or (errorHandler.buildDepError "unagi-chan"))
          (hsPkgs."unix-compat" or (errorHandler.buildDepError "unix-compat"))
          (hsPkgs."unordered-containers" or (errorHandler.buildDepError "unordered-containers"))
          (hsPkgs."vector" or (errorHandler.buildDepError "vector"))
          (hsPkgs."vector-builder" or (errorHandler.buildDepError "vector-builder"))
        ] ++ pkgs.lib.optional (!system.isWindows) (hsPkgs."unix" or (errorHandler.buildDepError "unix"));
        buildable = true;
      };
      tests = {
        "hs-opentelemetry-sdk-test" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."clock" or (errorHandler.buildDepError "clock"))
            (hsPkgs."hs-opentelemetry-api" or (errorHandler.buildDepError "hs-opentelemetry-api"))
            (hsPkgs."hs-opentelemetry-sdk" or (errorHandler.buildDepError "hs-opentelemetry-sdk"))
            (hsPkgs."hspec" or (errorHandler.buildDepError "hspec"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
            (hsPkgs."unordered-containers" or (errorHandler.buildDepError "unordered-containers"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/hs-opentelemetry-sdk-0.1.0.1.tar.gz";
      sha256 = "65760f47e3b115efbd279b2383c839dc457d120ec86e0e9cb20357601f91b471";
    });
  }) // {
    package-description-override = "cabal-version: 1.22\n\n-- This file has been generated from package.yaml by hpack version 0.37.0.\n--\n-- see: https://github.com/sol/hpack\n\nname:               hs-opentelemetry-sdk\nversion:            0.1.0.1\nsynopsis:           OpenTelemetry SDK for use in applications.\ndescription:        Please see the README on GitHub at <https://github.com/iand675/hs-opentelemetry/tree/main/sdk#readme>\ncategory:           OpenTelemetry, Telemetry, Monitoring, Observability, Metrics\nhomepage:           https://github.com/iand675/hs-opentelemetry#readme\nbug-reports:        https://github.com/iand675/hs-opentelemetry/issues\nauthor:             Ian Duncan, Jade Lovelace\nmaintainer:         ian@iankduncan.com\ncopyright:          2024 Ian Duncan, Mercury Technologies\nlicense:            BSD3\nlicense-file:       LICENSE\nbuild-type:         Simple\nextra-source-files:\n    README.md\n    ChangeLog.md\nextra-doc-files:\n    docs/img/traces_spans.png\n\nsource-repository head\n  type: git\n  location: https://github.com/iand675/hs-opentelemetry\n\nlibrary\n  exposed-modules:\n      OpenTelemetry.Processor.Batch\n      OpenTelemetry.Processor.Batch.LogRecord\n      OpenTelemetry.Processor.Batch.Span\n      OpenTelemetry.Processor.Simple\n      OpenTelemetry.Processor.Simple.LogRecord\n      OpenTelemetry.Processor.Simple.Span\n      OpenTelemetry.Resource.Host.Detector\n      OpenTelemetry.Resource.OperatingSystem.Detector\n      OpenTelemetry.Resource.Process.Detector\n      OpenTelemetry.Resource.Service.Detector\n      OpenTelemetry.Resource.Telemetry.Detector\n      OpenTelemetry.Trace\n      OpenTelemetry.Trace.Id.Generator.Default\n  other-modules:\n      Paths_hs_opentelemetry_sdk\n  reexported-modules:\n      OpenTelemetry.Attributes\n    , OpenTelemetry.Baggage\n    , OpenTelemetry.Context\n    , OpenTelemetry.Context.ThreadLocal\n    , OpenTelemetry.Exporter.Span\n    , OpenTelemetry.Exporter.LogRecord\n    , OpenTelemetry.Exporter\n    , OpenTelemetry.Processor.Span\n    , OpenTelemetry.Processor.LogRecord\n    , OpenTelemetry.Processor\n    , OpenTelemetry.Propagator\n    , OpenTelemetry.Resource\n    , OpenTelemetry.Resource.Cloud\n    , OpenTelemetry.Resource.Container\n    , OpenTelemetry.Resource.DeploymentEnvironment\n    , OpenTelemetry.Resource.Device\n    , OpenTelemetry.Resource.FaaS\n    , OpenTelemetry.Resource.Host\n    , OpenTelemetry.Resource.Kubernetes\n    , OpenTelemetry.Resource.OperatingSystem\n    , OpenTelemetry.Resource.Process\n    , OpenTelemetry.Resource.Service\n    , OpenTelemetry.Resource.Telemetry\n    , OpenTelemetry.Resource.Webengine\n    , OpenTelemetry.Trace.Id\n    , OpenTelemetry.Trace.Monad\n    , OpenTelemetry.Trace.Sampler\n    , OpenTelemetry.Trace.TraceState\n    , OpenTelemetry.Util\n  hs-source-dirs:\n      src\n  ghc-options: -Wall\n  build-depends:\n      async\n    , base >=4.7 && <5\n    , bytestring\n    , hs-opentelemetry-api ==0.3.*\n    , hs-opentelemetry-exporter-otlp ==0.1.*\n    , hs-opentelemetry-propagator-b3 >=0.0.1 && <0.1\n    , hs-opentelemetry-propagator-datadog >=0.0.0 && <0.1\n    , hs-opentelemetry-propagator-w3c >=0.1.0 && <0.2\n    , http-types\n    , network-bsd\n    , random >=1.2.0\n    , stm\n    , text\n    , unagi-chan\n    , unix-compat >=0.7.1\n    , unordered-containers\n    , vector\n    , vector-builder\n  default-language: Haskell2010\n  if os(windows)\n    other-modules:\n        OpenTelemetry.Platform\n    hs-source-dirs:\n        src/platform/windows\n  else\n    other-modules:\n        OpenTelemetry.Platform\n    hs-source-dirs:\n        src/platform/unix\n    build-depends:\n        unix\n\ntest-suite hs-opentelemetry-sdk-test\n  type: exitcode-stdio-1.0\n  main-is: Spec.hs\n  other-modules:\n      OpenTelemetry.BaggageSpec\n      OpenTelemetry.ContextSpec\n      OpenTelemetry.ResourceSpec\n      OpenTelemetry.TraceSpec\n      Paths_hs_opentelemetry_sdk\n  hs-source-dirs:\n      test\n  ghc-options: -threaded -rtsopts -with-rtsopts=-N\n  build-depends:\n      base >=4.7 && <5\n    , clock\n    , hs-opentelemetry-api\n    , hs-opentelemetry-sdk\n    , hspec\n    , text\n    , unordered-containers\n  default-language: Haskell2010\n";
  }