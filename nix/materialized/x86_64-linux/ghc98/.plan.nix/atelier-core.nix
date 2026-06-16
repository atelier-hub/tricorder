{ system
  , compiler
  , flags
  , pkgs
  , hsPkgs
  , pkgconfPkgs
  , errorHandler
  , config
  , ... }:
  {
    flags = {};
    package = {
      specVersion = "2.0";
      identifier = { name = "atelier-core"; version = "0.1.0.0"; };
      license = "MIT";
      copyright = "";
      maintainer = "christian.georgii@tweag.io";
      author = "Christian Georgii";
      homepage = "https://github.com/atelier-hub/atelier#readme";
      url = "";
      synopsis = "Foundational Effectful-based effects and utilities";
      description = "Core effects and utilities for effect-based applications, built on Effectful — part of the atelier toolkit.";
      buildType = "Simple";
      isLocal = true;
      detailLevel = "FullDetails";
      licenseFiles = [ "LICENSE" ];
      dataDir = ".";
      dataFiles = [];
      extraSrcFiles = [];
      extraTmpFiles = [];
      extraDocFiles = [ "CHANGELOG.md" "README.md" ];
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."aeson" or (errorHandler.buildDepError "aeson"))
          (hsPkgs."atelier-prelude" or (errorHandler.buildDepError "atelier-prelude"))
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."base64-bytestring" or (errorHandler.buildDepError "base64-bytestring"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          (hsPkgs."casing" or (errorHandler.buildDepError "casing"))
          (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
          (hsPkgs."contra-tracer" or (errorHandler.buildDepError "contra-tracer"))
          (hsPkgs."daemons" or (errorHandler.buildDepError "daemons"))
          (hsPkgs."data-default" or (errorHandler.buildDepError "data-default"))
          (hsPkgs."directory" or (errorHandler.buildDepError "directory"))
          (hsPkgs."effectful" or (errorHandler.buildDepError "effectful"))
          (hsPkgs."effectful-core" or (errorHandler.buildDepError "effectful-core"))
          (hsPkgs."effectful-plugin" or (errorHandler.buildDepError "effectful-plugin"))
          (hsPkgs."effectful-th" or (errorHandler.buildDepError "effectful-th"))
          (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
          (hsPkgs."fsnotify" or (errorHandler.buildDepError "fsnotify"))
          (hsPkgs."hs-opentelemetry-api" or (errorHandler.buildDepError "hs-opentelemetry-api"))
          (hsPkgs."hs-opentelemetry-exporter-otlp" or (errorHandler.buildDepError "hs-opentelemetry-exporter-otlp"))
          (hsPkgs."hs-opentelemetry-sdk" or (errorHandler.buildDepError "hs-opentelemetry-sdk"))
          (hsPkgs."http-api-data" or (errorHandler.buildDepError "http-api-data"))
          (hsPkgs."http-types" or (errorHandler.buildDepError "http-types"))
          (hsPkgs."ki" or (errorHandler.buildDepError "ki"))
          (hsPkgs."list-t" or (errorHandler.buildDepError "list-t"))
          (hsPkgs."optparse-applicative" or (errorHandler.buildDepError "optparse-applicative"))
          (hsPkgs."process" or (errorHandler.buildDepError "process"))
          (hsPkgs."prometheus-client" or (errorHandler.buildDepError "prometheus-client"))
          (hsPkgs."prometheus-metrics-ghc" or (errorHandler.buildDepError "prometheus-metrics-ghc"))
          (hsPkgs."stm" or (errorHandler.buildDepError "stm"))
          (hsPkgs."stm-containers" or (errorHandler.buildDepError "stm-containers"))
          (hsPkgs."text" or (errorHandler.buildDepError "text"))
          (hsPkgs."time" or (errorHandler.buildDepError "time"))
          (hsPkgs."time-units" or (errorHandler.buildDepError "time-units"))
          (hsPkgs."typed-process" or (errorHandler.buildDepError "typed-process"))
          (hsPkgs."unagi-chan" or (errorHandler.buildDepError "unagi-chan"))
          (hsPkgs."unix" or (errorHandler.buildDepError "unix"))
          (hsPkgs."unordered-containers" or (errorHandler.buildDepError "unordered-containers"))
          (hsPkgs."uuid" or (errorHandler.buildDepError "uuid"))
          (hsPkgs."wai" or (errorHandler.buildDepError "wai"))
          (hsPkgs."warp" or (errorHandler.buildDepError "warp"))
        ];
        buildable = true;
        modules = [
          "Paths_atelier_core"
          "Atelier/Component"
          "Atelier/Config"
          "Atelier/Effects/Arguments"
          "Atelier/Effects/Await"
          "Atelier/Effects/Cache"
          "Atelier/Effects/Cache/Config"
          "Atelier/Effects/Cache/Singleflight"
          "Atelier/Effects/Chan"
          "Atelier/Effects/Clock"
          "Atelier/Effects/Conc"
          "Atelier/Effects/Conc/Traced"
          "Atelier/Effects/Console"
          "Atelier/Effects/Debounce"
          "Atelier/Effects/Delay"
          "Atelier/Effects/Env"
          "Atelier/Effects/Exit"
          "Atelier/Effects/File"
          "Atelier/Effects/FileSystem"
          "Atelier/Effects/FileWatcher"
          "Atelier/Effects/Input"
          "Atelier/Effects/Internal/Coroutine"
          "Atelier/Effects/Iterator"
          "Atelier/Effects/Log"
          "Atelier/Effects/Monitoring/Metrics"
          "Atelier/Effects/Monitoring/Metrics/Registry"
          "Atelier/Effects/Monitoring/Metrics/Server"
          "Atelier/Effects/Monitoring/Tracing"
          "Atelier/Effects/Monitoring/Tracing/Provider"
          "Atelier/Effects/Posix/Daemons"
          "Atelier/Effects/Posix/IO"
          "Atelier/Effects/Process"
          "Atelier/Effects/Publishing"
          "Atelier/Effects/Tally"
          "Atelier/Effects/Timeout"
          "Atelier/Effects/UUID"
          "Atelier/Effects/Yield"
          "Atelier/Exception"
          "Atelier/Time"
          "Atelier/Types/Base64"
          "Atelier/Types/HttpApiDataReadShow"
          "Atelier/Types/JsonReadShow"
          "Atelier/Types/QuietSnake"
          "Atelier/Types/Semaphore"
          "Atelier/Types/Semaphore/STM"
          "Atelier/Types/WithDefaults"
        ];
        hsSourceDirs = [ "src" ];
      };
      tests = {
        "atelier-test" = {
          depends = [
            (hsPkgs."aeson" or (errorHandler.buildDepError "aeson"))
            (hsPkgs."async" or (errorHandler.buildDepError "async"))
            (hsPkgs."atelier-core" or (errorHandler.buildDepError "atelier-core"))
            (hsPkgs."atelier-prelude" or (errorHandler.buildDepError "atelier-prelude"))
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
            (hsPkgs."data-default" or (errorHandler.buildDepError "data-default"))
            (hsPkgs."effectful" or (errorHandler.buildDepError "effectful"))
            (hsPkgs."effectful-core" or (errorHandler.buildDepError "effectful-core"))
            (hsPkgs."effectful-plugin" or (errorHandler.buildDepError "effectful-plugin"))
            (hsPkgs."hedgehog" or (errorHandler.buildDepError "hedgehog"))
            (hsPkgs."hs-opentelemetry-api" or (errorHandler.buildDepError "hs-opentelemetry-api"))
            (hsPkgs."hspec" or (errorHandler.buildDepError "hspec"))
            (hsPkgs."hspec-hedgehog" or (errorHandler.buildDepError "hspec-hedgehog"))
            (hsPkgs."stm" or (errorHandler.buildDepError "stm"))
            (hsPkgs."stm-containers" or (errorHandler.buildDepError "stm-containers"))
            (hsPkgs."tasty" or (errorHandler.buildDepError "tasty"))
            (hsPkgs."tasty-hspec" or (errorHandler.buildDepError "tasty-hspec"))
            (hsPkgs."time" or (errorHandler.buildDepError "time"))
          ];
          build-tools = [
            (hsPkgs.pkgsBuildBuild.tasty-discover.components.exes.tasty-discover or (pkgs.pkgsBuildBuild.tasty-discover or (errorHandler.buildToolDepError "tasty-discover:tasty-discover")))
          ];
          buildable = true;
          modules = [
            "Unit/Atelier/ConfigSpec"
            "Unit/Atelier/Effects/AwaitSpec"
            "Unit/Atelier/Effects/Cache/SingleflightSpec"
            "Unit/Atelier/Effects/CacheSpec"
            "Unit/Atelier/Effects/ChanSpec"
            "Unit/Atelier/Effects/Conc/TeardownStressSpec"
            "Unit/Atelier/Effects/Conc/TracedSpec"
            "Unit/Atelier/Effects/ConcSpec"
            "Unit/Atelier/Effects/ConsoleSpec"
            "Unit/Atelier/Effects/DebounceSpec"
            "Unit/Atelier/Effects/FileSystemSpec"
            "Unit/Atelier/Effects/FileWatcherSpec"
            "Unit/Atelier/Effects/IteratorSpec"
            "Unit/Atelier/Effects/LogSpec"
            "Unit/Atelier/Effects/PublishingSpec"
            "Unit/Atelier/Effects/TallySpec"
            "Unit/Atelier/Effects/YieldSpec"
            "Unit/Atelier/Types/Semaphore/STMSpec"
            "Unit/Atelier/Types/SemaphoreSpec"
            "Unit/Atelier/Types/WithDefaultsSpec"
            "Paths_atelier_core"
          ];
          hsSourceDirs = [ "test" ];
          mainPath = [ "Driver.hs" ];
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchgit {
      url = "0";
      rev = "minimal";
      sha256 = "";
    }) // {
      url = "0";
      rev = "minimal";
      sha256 = "";
    };
    postUnpack = "sourceRoot+=/atelier-core; echo source root reset to $sourceRoot";
  }