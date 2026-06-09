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
      specVersion = "2.4";
      identifier = {
        name = "hs-opentelemetry-propagator-datadog";
        version = "0.0.1.1";
      };
      license = "BSD-3-Clause";
      copyright = "";
      maintainer = "kazuki.okamoto@herp.co.jp";
      author = "Kazuki Okamoto (岡本和樹)";
      homepage = "https://github.com/iand675/hs-opentelemetry";
      url = "";
      synopsis = "Datadog Propagator for OpenTelemetry";
      description = "This package provides a Datadog style propagator for hs-opentelemetry suite.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          (hsPkgs."hs-opentelemetry-api" or (errorHandler.buildDepError "hs-opentelemetry-api"))
          (hsPkgs."http-types" or (errorHandler.buildDepError "http-types"))
          (hsPkgs."primitive" or (errorHandler.buildDepError "primitive"))
          (hsPkgs."text" or (errorHandler.buildDepError "text"))
        ];
        buildable = true;
      };
      tests = {
        "spec" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."hs-opentelemetry-propagator-datadog" or (errorHandler.buildDepError "hs-opentelemetry-propagator-datadog"))
            (hsPkgs."hs-opentelemetry-api" or (errorHandler.buildDepError "hs-opentelemetry-api"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."hspec" or (errorHandler.buildDepError "hspec"))
            (hsPkgs."pretty-hex" or (errorHandler.buildDepError "pretty-hex"))
            (hsPkgs."primitive" or (errorHandler.buildDepError "primitive"))
            (hsPkgs."QuickCheck" or (errorHandler.buildDepError "QuickCheck"))
          ];
          build-tools = [
            (hsPkgs.pkgsBuildBuild.hspec-discover.components.exes.hspec-discover or (pkgs.pkgsBuildBuild.hspec-discover or (errorHandler.buildToolDepError "hspec-discover:hspec-discover")))
          ];
          buildable = true;
        };
      };
      benchmarks = {
        "header-codec" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."hs-opentelemetry-propagator-datadog" or (errorHandler.buildDepError "hs-opentelemetry-propagator-datadog"))
            (hsPkgs."hs-opentelemetry-api" or (errorHandler.buildDepError "hs-opentelemetry-api"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."criterion" or (errorHandler.buildDepError "criterion"))
            (hsPkgs."deepseq" or (errorHandler.buildDepError "deepseq"))
            (hsPkgs."primitive" or (errorHandler.buildDepError "primitive"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/hs-opentelemetry-propagator-datadog-0.0.1.1.tar.gz";
      sha256 = "87b3c7dd4141af51f5a8e2c4ee6606c408b3130af17d2b534a261ac2a5b9fac7";
    });
  }) // {
    package-description-override = "cabal-version: 2.4\n\nname: hs-opentelemetry-propagator-datadog\nversion: 0.0.1.1\nauthor: Kazuki Okamoto (岡本和樹)\nmaintainer: kazuki.okamoto@herp.co.jp\nlicense: BSD-3-Clause\nlicense-file: LICENSE\ncategory: Telemetry\nhomepage: https://github.com/iand675/hs-opentelemetry\nbug-reports: https://github.com/iand675/hs-opentelemetry/issues\nsynopsis: Datadog Propagator for OpenTelemetry\ndescription: This package provides a Datadog style propagator for hs-opentelemetry suite.\n\ncommon common\n  build-depends: base >= 4 && < 5\n  ghc-options: -Wall\n  if impl(ghc >= 8.0)\n    ghc-options: -Wcompat\n  default-language: Haskell2010\n\nlibrary\n  import: common\n  hs-source-dirs: src\n  exposed-modules: OpenTelemetry.Propagator.Datadog\n                   OpenTelemetry.Propagator.Datadog.Internal\n  build-depends: bytestring,\n                 hs-opentelemetry-api ^>= 0.3,\n                 http-types,\n                 primitive,\n                 text\n  ghc-options: -Wcompat\n               -Wno-name-shadowing\n  if impl(ghc >= 6.4)\n    ghc-options: -Wincomplete-record-updates\n  if impl(ghc >= 6.8)\n    ghc-options: -Wmonomorphism-restriction\n  if impl(ghc >= 7.0)\n    ghc-options: -Wmissing-import-lists\n  if impl(ghc >= 7.2)\n    ghc-options: -Wincomplete-uni-patterns\n                 -Widentities\n  if impl(ghc >= 8.0)\n    ghc-options: -Wmissing-exported-signatures\n                 -Wredundant-constraints\n  if impl(ghc >= 8.2)\n    ghc-options: -Wmissing-home-modules\n  if impl(ghc >= 8.4)\n    ghc-options: -Wmissing-export-lists\n                 -Wpartial-fields\n  if impl(ghc >= 8.8)\n    ghc-options: -Wmissing-deriving-strategies\n  if impl(ghc >= 8.10)\n    ghc-options: -Wunused-packages\n  if impl(ghc >= 9.0)\n    ghc-options: -Winvalid-haddock\n  if impl(ghc >= 9.2)\n    ghc-options: -Wmissing-kind-signatures\n                 -Woperator-whitespace\n                 -Wredundant-bang-patterns\n\ntest-suite spec\n  import: common\n  type: exitcode-stdio-1.0\n  main-is: Spec.hs\n  hs-source-dirs: test/spec\n                  old-src\n  other-modules: OpenTelemetry.Propagator.DatadogSpec\n                 OpenTelemetry.Propagator.Datadog.InternalSpec\n                 Raw\n                 String\n  build-depends: hs-opentelemetry-propagator-datadog,\n                 hs-opentelemetry-api,\n                 bytestring,\n                 hspec,\n                 pretty-hex,\n                 primitive,\n                 QuickCheck\n  ghc-options: -threaded\n               -rtsopts\n               -with-rtsopts=-N\n  build-tool-depends: hspec-discover:hspec-discover\n\nbenchmark header-codec\n  import: common\n  type: exitcode-stdio-1.0\n  main-is: main.hs\n  other-modules: Raw\n                 String\n  hs-source-dirs: benchmark/header-codec\n                  old-src\n  build-depends: hs-opentelemetry-propagator-datadog,\n                 hs-opentelemetry-api,\n                 bytestring,\n                 criterion,\n                 deepseq,\n                 primitive\n";
  }