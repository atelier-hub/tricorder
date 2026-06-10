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
      specVersion = "1.10";
      identifier = { name = "prometheus-client"; version = "1.1.1"; };
      license = "Apache-2.0";
      copyright = "2015 Will Coster";
      maintainer = "willcoster@gmail.com";
      author = "Will Coster";
      homepage = "https://github.com/fimad/prometheus-haskell";
      url = "";
      synopsis = "Haskell client library for http://prometheus.io.";
      description = "Haskell client library for http://prometheus.io.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."atomic-primops" or (errorHandler.buildDepError "atomic-primops"))
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          (hsPkgs."clock" or (errorHandler.buildDepError "clock"))
          (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
          (hsPkgs."deepseq" or (errorHandler.buildDepError "deepseq"))
          (hsPkgs."primitive" or (errorHandler.buildDepError "primitive"))
          (hsPkgs."mtl" or (errorHandler.buildDepError "mtl"))
          (hsPkgs."stm" or (errorHandler.buildDepError "stm"))
          (hsPkgs."transformers" or (errorHandler.buildDepError "transformers"))
          (hsPkgs."transformers-compat" or (errorHandler.buildDepError "transformers-compat"))
          (hsPkgs."utf8-string" or (errorHandler.buildDepError "utf8-string"))
          (hsPkgs."exceptions" or (errorHandler.buildDepError "exceptions"))
          (hsPkgs."text" or (errorHandler.buildDepError "text"))
          (hsPkgs."data-sketches" or (errorHandler.buildDepError "data-sketches"))
        ];
        buildable = true;
      };
      tests = {
        "doctest" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."doctest" or (errorHandler.buildDepError "doctest"))
            (hsPkgs."prometheus-client" or (errorHandler.buildDepError "prometheus-client"))
          ];
          buildable = true;
        };
        "spec" = {
          depends = [
            (hsPkgs."QuickCheck" or (errorHandler.buildDepError "QuickCheck"))
            (hsPkgs."atomic-primops" or (errorHandler.buildDepError "atomic-primops"))
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
            (hsPkgs."clock" or (errorHandler.buildDepError "clock"))
            (hsPkgs."hspec" or (errorHandler.buildDepError "hspec"))
            (hsPkgs."mtl" or (errorHandler.buildDepError "mtl"))
            (hsPkgs."random-shuffle" or (errorHandler.buildDepError "random-shuffle"))
            (hsPkgs."stm" or (errorHandler.buildDepError "stm"))
            (hsPkgs."transformers" or (errorHandler.buildDepError "transformers"))
            (hsPkgs."transformers-compat" or (errorHandler.buildDepError "transformers-compat"))
            (hsPkgs."utf8-string" or (errorHandler.buildDepError "utf8-string"))
            (hsPkgs."deepseq" or (errorHandler.buildDepError "deepseq"))
            (hsPkgs."exceptions" or (errorHandler.buildDepError "exceptions"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
            (hsPkgs."primitive" or (errorHandler.buildDepError "primitive"))
            (hsPkgs."data-sketches" or (errorHandler.buildDepError "data-sketches"))
          ];
          buildable = true;
        };
      };
      benchmarks = {
        "bench" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."criterion" or (errorHandler.buildDepError "criterion"))
            (hsPkgs."prometheus-client" or (errorHandler.buildDepError "prometheus-client"))
            (hsPkgs."random" or (errorHandler.buildDepError "random"))
            (hsPkgs."utf8-string" or (errorHandler.buildDepError "utf8-string"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/prometheus-client-1.1.1.tar.gz";
      sha256 = "6a709ec749651d86e1e3a1189193d3d6a74489eaf8f10297c31cc863fc4644c8";
    });
  }) // {
    package-description-override = "name:                prometheus-client\r\nversion:             1.1.1\r\nx-revision: 1\r\nsynopsis:            Haskell client library for http://prometheus.io.\r\ndescription:         Haskell client library for http://prometheus.io.\r\nhomepage:            https://github.com/fimad/prometheus-haskell\r\nlicense:             Apache-2.0\r\nlicense-file:        LICENSE\r\nauthor:              Will Coster\r\nmaintainer:          willcoster@gmail.com\r\ncopyright:           2015 Will Coster\r\ncategory:            Network\r\nbuild-type:          Simple\r\ncabal-version:       >=1.10\r\n\r\nsource-repository head\r\n  type:     git\r\n  location: https://github.com/fimad/prometheus-haskell\r\n\r\nlibrary\r\n  hs-source-dirs:      src/\r\n  default-language:    Haskell2010\r\n  exposed-modules:\r\n      Prometheus\r\n  other-modules:\r\n      Prometheus.Info\r\n    , Prometheus.Label\r\n    , Prometheus.Export.Text\r\n    , Prometheus.Metric\r\n    , Prometheus.Metric.Counter\r\n    , Prometheus.Metric.Gauge\r\n    , Prometheus.Metric.Histogram\r\n    , Prometheus.Metric.Observer\r\n    , Prometheus.Metric.Summary\r\n    , Prometheus.Metric.Vector\r\n    , Prometheus.MonadMonitor\r\n    , Prometheus.Registry\r\n  build-depends:\r\n      atomic-primops     >=0.4\r\n    , base               >=4.7 && <5\r\n    , bytestring         >=0.9\r\n    , clock\r\n    , containers\r\n    , deepseq\r\n    , primitive\r\n    , mtl                >=2\r\n    , stm                >=2.3\r\n    , transformers\r\n    , transformers-compat\r\n    , utf8-string\r\n    , exceptions\r\n    , text\r\n    , data-sketches      <0.4\r\n  ghc-options: -Wall\r\n\r\ntest-suite doctest\r\n  type:                 exitcode-stdio-1.0\r\n  default-language:     Haskell2010\r\n  hs-source-dirs:       tests\r\n  ghc-options:          -Wall\r\n  main-is:              doctest.hs\r\n  build-depends:\r\n      base               >=4.7 && <5\r\n    , doctest\r\n    , prometheus-client\r\n\r\ntest-suite spec\r\n  type:              exitcode-stdio-1.0\r\n  default-language:  Haskell2010\r\n  hs-source-dirs:    src, tests\r\n  main-is:           Spec.hs\r\n  build-depends:\r\n      QuickCheck\r\n    , atomic-primops\r\n    , base               >=4.7 && <5\r\n    , bytestring\r\n    , containers\r\n    , clock\r\n    , hspec\r\n    , mtl\r\n    , random-shuffle\r\n    , stm\r\n    , transformers\r\n    , transformers-compat\r\n    , utf8-string\r\n    , deepseq\r\n    , exceptions\r\n    , text\r\n    , primitive\r\n    , data-sketches\r\n  ghc-options: -Wall\r\n\r\nbenchmark bench\r\n  type:             exitcode-stdio-1.0\r\n  default-language: Haskell2010\r\n  hs-source-dirs:   benchmarks\r\n  main-is:          Main.hs\r\n  build-depends:\r\n      base               >=4.7 && <5\r\n    , bytestring\r\n    , criterion          >=1.2\r\n    , prometheus-client\r\n    , random\r\n    , utf8-string\r\n    , text\r\n  ghc-options: -Wall\r\n";
  }