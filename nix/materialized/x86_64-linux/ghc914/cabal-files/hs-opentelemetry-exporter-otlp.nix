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
      identifier = {
        name = "hs-opentelemetry-exporter-otlp";
        version = "0.1.1.0";
      };
      license = "BSD-3-Clause";
      copyright = "2021 Ian Duncan";
      maintainer = "ian@iankduncan.com";
      author = "Ian Duncan";
      homepage = "https://github.com/iand675/hs-opentelemetry#readme";
      url = "";
      synopsis = "OpenTelemetry exporter supporting the standard OTLP protocol";
      description = "Please see the README on GitHub at <https://github.com/iand675/hs-opentelemetry/tree/main/exporters/otlp#readme>";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          (hsPkgs."case-insensitive" or (errorHandler.buildDepError "case-insensitive"))
          (hsPkgs."hs-opentelemetry-api" or (errorHandler.buildDepError "hs-opentelemetry-api"))
          (hsPkgs."hs-opentelemetry-otlp" or (errorHandler.buildDepError "hs-opentelemetry-otlp"))
          (hsPkgs."hs-opentelemetry-propagator-w3c" or (errorHandler.buildDepError "hs-opentelemetry-propagator-w3c"))
          (hsPkgs."http-client" or (errorHandler.buildDepError "http-client"))
          (hsPkgs."http-conduit" or (errorHandler.buildDepError "http-conduit"))
          (hsPkgs."http-types" or (errorHandler.buildDepError "http-types"))
          (hsPkgs."microlens" or (errorHandler.buildDepError "microlens"))
          (hsPkgs."proto-lens" or (errorHandler.buildDepError "proto-lens"))
          (hsPkgs."text" or (errorHandler.buildDepError "text"))
          (hsPkgs."unordered-containers" or (errorHandler.buildDepError "unordered-containers"))
          (hsPkgs."vector" or (errorHandler.buildDepError "vector"))
          (hsPkgs."zlib" or (errorHandler.buildDepError "zlib"))
        ];
        buildable = true;
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/hs-opentelemetry-exporter-otlp-0.1.1.0.tar.gz";
      sha256 = "c545dd32c0ffc4e5a6b759788af0cd4797c33cbafeb04817cc1cc90a1f4ef194";
    });
  }) // {
    package-description-override = "cabal-version: 1.12\n\n-- This file has been generated from package.yaml by hpack version 0.37.0.\n--\n-- see: https://github.com/sol/hpack\n\nname:           hs-opentelemetry-exporter-otlp\nversion:        0.1.1.0\nsynopsis:       OpenTelemetry exporter supporting the standard OTLP protocol\ndescription:    Please see the README on GitHub at <https://github.com/iand675/hs-opentelemetry/tree/main/exporters/otlp#readme>\ncategory:       OpenTelemetry, Telemetry, Monitoring, Observability, Metrics\nhomepage:       https://github.com/iand675/hs-opentelemetry#readme\nbug-reports:    https://github.com/iand675/hs-opentelemetry/issues\nauthor:         Ian Duncan\nmaintainer:     ian@iankduncan.com\ncopyright:      2021 Ian Duncan\nlicense:        BSD3\nlicense-file:   LICENSE\nbuild-type:     Simple\nextra-source-files:\n    README.md\n    ChangeLog.md\n\nsource-repository head\n  type: git\n  location: https://github.com/iand675/hs-opentelemetry\n\nlibrary\n  exposed-modules:\n      OpenTelemetry.Exporter.OTLP\n      OpenTelemetry.Exporter.OTLP.LogRecord\n      OpenTelemetry.Exporter.OTLP.Span\n  other-modules:\n      Paths_hs_opentelemetry_exporter_otlp\n  hs-source-dirs:\n      src\n  ghc-options: -Wall\n  build-depends:\n      base >=4.7 && <5\n    , bytestring\n    , case-insensitive\n    , hs-opentelemetry-api ==0.3.*\n    , hs-opentelemetry-otlp ==0.2.*\n    , hs-opentelemetry-propagator-w3c\n    , http-client\n    , http-conduit\n    , http-types\n    , microlens\n    , proto-lens >=0.7.1.0\n    , text\n    , unordered-containers\n    , vector\n    , zlib\n  default-language: Haskell2010\n";
  }