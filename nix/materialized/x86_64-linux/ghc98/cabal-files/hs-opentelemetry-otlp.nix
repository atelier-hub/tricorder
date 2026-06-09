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
      identifier = { name = "hs-opentelemetry-otlp"; version = "0.2.0.0"; };
      license = "BSD-3-Clause";
      copyright = "2024 Ian Duncan, Mercury Technologies";
      maintainer = "ian@iankduncan.com";
      author = "Ian Duncan, Jade Lovelace";
      homepage = "https://github.com/iand675/hs-opentelemetry#readme";
      url = "";
      synopsis = "OpenTelemetry protocol buffer modules generated for the OTLP protocol by the proto-lens package";
      description = "Please see the README on GitHub at <https://github.com/iand675/hs-opentelemetry#readme>";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."proto-lens-runtime" or (errorHandler.buildDepError "proto-lens-runtime"))
        ];
        buildable = true;
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/hs-opentelemetry-otlp-0.2.0.0.tar.gz";
      sha256 = "1d8ec1ed5e77c3a7865c7a82fd683e8bb64f32d68f50dee67139970cf0b1c979";
    });
  }) // {
    package-description-override = "cabal-version: 1.12\n\n-- This file has been generated from package.yaml by hpack version 0.37.0.\n--\n-- see: https://github.com/sol/hpack\n\nname:           hs-opentelemetry-otlp\nversion:        0.2.0.0\nsynopsis:       OpenTelemetry protocol buffer modules generated for the OTLP protocol by the proto-lens package\ndescription:    Please see the README on GitHub at <https://github.com/iand675/hs-opentelemetry#readme>\ncategory:       OpenTelemetry\nhomepage:       https://github.com/iand675/hs-opentelemetry#readme\nbug-reports:    https://github.com/iand675/hs-opentelemetry/issues\nauthor:         Ian Duncan, Jade Lovelace\nmaintainer:     ian@iankduncan.com\ncopyright:      2024 Ian Duncan, Mercury Technologies\nlicense:        BSD3\nlicense-file:   LICENSE\nbuild-type:     Simple\nextra-source-files:\n    README.md\n    ChangeLog.md\n    proto/opentelemetry/proto/collector/logs/v1/logs_service.proto\n    proto/opentelemetry/proto/collector/metrics/v1/metrics_service.proto\n    proto/opentelemetry/proto/collector/profiles/v1development/profiles_service.proto\n    proto/opentelemetry/proto/collector/trace/v1/trace_service.proto\n    proto/opentelemetry/proto/common/v1/common.proto\n    proto/opentelemetry/proto/logs/v1/logs.proto\n    proto/opentelemetry/proto/metrics/v1/metrics.proto\n    proto/opentelemetry/proto/profiles/v1development/profiles.proto\n    proto/opentelemetry/proto/resource/v1/resource.proto\n    proto/opentelemetry/proto/trace/v1/trace.proto\n\nsource-repository head\n  type: git\n  location: https://github.com/iand675/hs-opentelemetry\n\nlibrary\n  exposed-modules:\n      Proto.Opentelemetry.Proto.Collector.Logs.V1.LogsService\n      Proto.Opentelemetry.Proto.Collector.Logs.V1.LogsService_Fields\n      Proto.Opentelemetry.Proto.Collector.Metrics.V1.MetricsService\n      Proto.Opentelemetry.Proto.Collector.Metrics.V1.MetricsService_Fields\n      Proto.Opentelemetry.Proto.Collector.Profiles.V1development.ProfilesService\n      Proto.Opentelemetry.Proto.Collector.Profiles.V1development.ProfilesService_Fields\n      Proto.Opentelemetry.Proto.Collector.Trace.V1.TraceService\n      Proto.Opentelemetry.Proto.Collector.Trace.V1.TraceService_Fields\n      Proto.Opentelemetry.Proto.Common.V1.Common\n      Proto.Opentelemetry.Proto.Common.V1.Common_Fields\n      Proto.Opentelemetry.Proto.Logs.V1.Logs\n      Proto.Opentelemetry.Proto.Logs.V1.Logs_Fields\n      Proto.Opentelemetry.Proto.Metrics.V1.Metrics\n      Proto.Opentelemetry.Proto.Metrics.V1.Metrics_Fields\n      Proto.Opentelemetry.Proto.Profiles.V1development.Profiles\n      Proto.Opentelemetry.Proto.Profiles.V1development.Profiles_Fields\n      Proto.Opentelemetry.Proto.Resource.V1.Resource\n      Proto.Opentelemetry.Proto.Resource.V1.Resource_Fields\n      Proto.Opentelemetry.Proto.Trace.V1.Trace\n      Proto.Opentelemetry.Proto.Trace.V1.Trace_Fields\n  other-modules:\n      Paths_hs_opentelemetry_otlp\n  hs-source-dirs:\n      src\n  build-depends:\n      base >=4.7 && <5\n    , proto-lens-runtime\n  default-language: Haskell2010\n";
  }