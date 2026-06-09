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
      specVersion = "1.12";
      identifier = { name = "hs-opentelemetry-api"; version = "0.3.1.0"; };
      license = "BSD-3-Clause";
      copyright = "2024 Ian Duncan, Mercury Technologies";
      maintainer = "ian@iankduncan.com";
      author = "Ian Duncan, Jade Lovelace";
      homepage = "https://github.com/iand675/hs-opentelemetry#readme";
      url = "";
      synopsis = "OpenTelemetry API for use by libraries for direct instrumentation or wrapper packages.";
      description = "Please see the README on GitHub at <https://github.com/iand675/hs-opentelemetry/tree/main/api#readme>";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."async" or (errorHandler.buildDepError "async"))
          (hsPkgs."attoparsec" or (errorHandler.buildDepError "attoparsec"))
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."binary" or (errorHandler.buildDepError "binary"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          (hsPkgs."charset" or (errorHandler.buildDepError "charset"))
          (hsPkgs."clock" or (errorHandler.buildDepError "clock"))
          (hsPkgs."hashable" or (errorHandler.buildDepError "hashable"))
          (hsPkgs."http-types" or (errorHandler.buildDepError "http-types"))
          (hsPkgs."memory" or (errorHandler.buildDepError "memory"))
          (hsPkgs."mtl" or (errorHandler.buildDepError "mtl"))
          (hsPkgs."regex-tdfa" or (errorHandler.buildDepError "regex-tdfa"))
          (hsPkgs."safe-exceptions" or (errorHandler.buildDepError "safe-exceptions"))
          (hsPkgs."template-haskell" or (errorHandler.buildDepError "template-haskell"))
          (hsPkgs."text" or (errorHandler.buildDepError "text"))
          (hsPkgs."thread-utils-context" or (errorHandler.buildDepError "thread-utils-context"))
          (hsPkgs."transformers" or (errorHandler.buildDepError "transformers"))
          (hsPkgs."unliftio-core" or (errorHandler.buildDepError "unliftio-core"))
          (hsPkgs."unordered-containers" or (errorHandler.buildDepError "unordered-containers"))
          (hsPkgs."vault" or (errorHandler.buildDepError "vault"))
          (hsPkgs."vector" or (errorHandler.buildDepError "vector"))
          (hsPkgs."vector-builder" or (errorHandler.buildDepError "vector-builder"))
        ];
        buildable = true;
      };
      tests = {
        "hs-opentelemetry-api-test" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."hs-opentelemetry-api" or (errorHandler.buildDepError "hs-opentelemetry-api"))
            (hsPkgs."hspec" or (errorHandler.buildDepError "hspec"))
            (hsPkgs."mtl" or (errorHandler.buildDepError "mtl"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
            (hsPkgs."unliftio-core" or (errorHandler.buildDepError "unliftio-core"))
            (hsPkgs."unordered-containers" or (errorHandler.buildDepError "unordered-containers"))
            (hsPkgs."vector" or (errorHandler.buildDepError "vector"))
            (hsPkgs."vector-builder" or (errorHandler.buildDepError "vector-builder"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/hs-opentelemetry-api-0.3.1.0.tar.gz";
      sha256 = "4819b3dba1f853592e76f6e5ce2b086603ee03ee8ddba5ac262fef42d26fc924";
    });
  }) // {
    package-description-override = "cabal-version: 1.12\n\n-- This file has been generated from package.yaml by hpack version 0.37.0.\n--\n-- see: https://github.com/sol/hpack\n\nname:               hs-opentelemetry-api\nversion:            0.3.1.0\nsynopsis:           OpenTelemetry API for use by libraries for direct instrumentation or wrapper packages.\ndescription:        Please see the README on GitHub at <https://github.com/iand675/hs-opentelemetry/tree/main/api#readme>\ncategory:           OpenTelemetry, Telemetry, Monitoring, Observability, Metrics\nhomepage:           https://github.com/iand675/hs-opentelemetry#readme\nbug-reports:        https://github.com/iand675/hs-opentelemetry/issues\nauthor:             Ian Duncan, Jade Lovelace\nmaintainer:         ian@iankduncan.com\ncopyright:          2024 Ian Duncan, Mercury Technologies\nlicense:            BSD3\nlicense-file:       LICENSE\nbuild-type:         Simple\nextra-source-files:\n    README.md\n    ChangeLog.md\n\nsource-repository head\n  type: git\n  location: https://github.com/iand675/hs-opentelemetry\n\nlibrary\n  exposed-modules:\n      OpenTelemetry.Attributes\n      OpenTelemetry.Attributes.Attribute\n      OpenTelemetry.Attributes.Key\n      OpenTelemetry.Attributes.Map\n      OpenTelemetry.Baggage\n      OpenTelemetry.Common\n      OpenTelemetry.Context\n      OpenTelemetry.Context.ThreadLocal\n      OpenTelemetry.Contrib.CarryOns\n      OpenTelemetry.Contrib.SpanTraversals\n      OpenTelemetry.Environment\n      OpenTelemetry.Exporter\n      OpenTelemetry.Exporter.LogRecord\n      OpenTelemetry.Exporter.Span\n      OpenTelemetry.Internal.Common.Types\n      OpenTelemetry.Internal.Logs.Core\n      OpenTelemetry.Internal.Logs.Types\n      OpenTelemetry.Internal.Trace.Id\n      OpenTelemetry.LogAttributes\n      OpenTelemetry.Logs.Core\n      OpenTelemetry.Processor\n      OpenTelemetry.Processor.LogRecord\n      OpenTelemetry.Processor.Span\n      OpenTelemetry.Propagator\n      OpenTelemetry.Resource\n      OpenTelemetry.Resource.Cloud\n      OpenTelemetry.Resource.Container\n      OpenTelemetry.Resource.DeploymentEnvironment\n      OpenTelemetry.Resource.Device\n      OpenTelemetry.Resource.FaaS\n      OpenTelemetry.Resource.Host\n      OpenTelemetry.Resource.Kubernetes\n      OpenTelemetry.Resource.OperatingSystem\n      OpenTelemetry.Resource.Process\n      OpenTelemetry.Resource.Service\n      OpenTelemetry.Resource.Telemetry\n      OpenTelemetry.Resource.Webengine\n      OpenTelemetry.SemanticsConfig\n      OpenTelemetry.Trace.Core\n      OpenTelemetry.Trace.Id\n      OpenTelemetry.Trace.Id.Generator\n      OpenTelemetry.Trace.Id.Generator.Dummy\n      OpenTelemetry.Trace.Monad\n      OpenTelemetry.Trace.Sampler\n      OpenTelemetry.Trace.TraceState\n      OpenTelemetry.Util\n  other-modules:\n      OpenTelemetry.Context.Types\n      OpenTelemetry.Internal.Trace.Types\n      Paths_hs_opentelemetry_api\n  hs-source-dirs:\n      src\n  default-extensions:\n      OverloadedStrings\n      RecordWildCards\n  ghc-options: -Wall\n  build-depends:\n      async\n    , attoparsec\n    , base >=4.7 && <5\n    , binary\n    , bytestring\n    , charset\n    , clock\n    , hashable\n    , http-types\n    , memory\n    , mtl\n    , regex-tdfa\n    , safe-exceptions\n    , template-haskell\n    , text\n    , thread-utils-context ==0.3.*\n    , transformers\n    , unliftio-core\n    , unordered-containers\n    , vault\n    , vector\n    , vector-builder\n  default-language: Haskell2010\n\ntest-suite hs-opentelemetry-api-test\n  type: exitcode-stdio-1.0\n  main-is: Spec.hs\n  other-modules:\n      OpenTelemetry.AttributesSpec\n      OpenTelemetry.BaggageSpec\n      OpenTelemetry.InstrumentationLibrarySpec\n      OpenTelemetry.Logs.CoreSpec\n      OpenTelemetry.ResourceSpec\n      OpenTelemetry.SemanticsConfigSpec\n      OpenTelemetry.Trace.SamplerSpec\n      OpenTelemetry.Trace.TraceFlagsSpec\n      OpenTelemetry.Trace.TracerSpec\n      Paths_hs_opentelemetry_api\n  hs-source-dirs:\n      test\n  default-extensions:\n      OverloadedStrings\n      RecordWildCards\n  ghc-options: -threaded -rtsopts -with-rtsopts=-N\n  build-depends:\n      base >=4.7 && <5\n    , hs-opentelemetry-api\n    , hspec\n    , mtl\n    , text\n    , unliftio-core\n    , unordered-containers\n    , vector\n    , vector-builder\n  default-language: Haskell2010\n";
  }