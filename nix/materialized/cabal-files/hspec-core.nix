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
      identifier = { name = "hspec-core"; version = "2.11.14"; };
      license = "MIT";
      copyright = "(c) 2011-2025 Simon Hengel,\n(c) 2011-2012 Trystan Spangler,\n(c) 2011 Greg Weber";
      maintainer = "Simon Hengel <sol@typeful.net>";
      author = "Simon Hengel <sol@typeful.net>";
      homepage = "https://hspec.github.io/";
      url = "";
      synopsis = "A Testing Framework for Haskell";
      description = "This package exposes internal types and functions that can be used to extend Hspec's functionality.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."HUnit" or (errorHandler.buildDepError "HUnit"))
          (hsPkgs."QuickCheck" or (errorHandler.buildDepError "QuickCheck"))
          (hsPkgs."ansi-terminal" or (errorHandler.buildDepError "ansi-terminal"))
          (hsPkgs."array" or (errorHandler.buildDepError "array"))
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."call-stack" or (errorHandler.buildDepError "call-stack"))
          (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
          (hsPkgs."deepseq" or (errorHandler.buildDepError "deepseq"))
          (hsPkgs."directory" or (errorHandler.buildDepError "directory"))
          (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
          (hsPkgs."haskell-lexer" or (errorHandler.buildDepError "haskell-lexer"))
          (hsPkgs."hspec-expectations" or (errorHandler.buildDepError "hspec-expectations"))
          (hsPkgs."process" or (errorHandler.buildDepError "process"))
          (hsPkgs."quickcheck-io" or (errorHandler.buildDepError "quickcheck-io"))
          (hsPkgs."random" or (errorHandler.buildDepError "random"))
          (hsPkgs."tf-random" or (errorHandler.buildDepError "tf-random"))
          (hsPkgs."time" or (errorHandler.buildDepError "time"))
          (hsPkgs."transformers" or (errorHandler.buildDepError "transformers"))
        ] ++ pkgs.lib.optional (compiler.isGhc && compiler.version.ge "8.4.1") (hsPkgs."stm" or (errorHandler.buildDepError "stm"));
        buildable = true;
      };
      tests = {
        "spec" = {
          depends = [
            (hsPkgs."HUnit" or (errorHandler.buildDepError "HUnit"))
            (hsPkgs."QuickCheck" or (errorHandler.buildDepError "QuickCheck"))
            (hsPkgs."ansi-terminal" or (errorHandler.buildDepError "ansi-terminal"))
            (hsPkgs."array" or (errorHandler.buildDepError "array"))
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."base-orphans" or (errorHandler.buildDepError "base-orphans"))
            (hsPkgs."call-stack" or (errorHandler.buildDepError "call-stack"))
            (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
            (hsPkgs."deepseq" or (errorHandler.buildDepError "deepseq"))
            (hsPkgs."directory" or (errorHandler.buildDepError "directory"))
            (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
            (hsPkgs."haskell-lexer" or (errorHandler.buildDepError "haskell-lexer"))
            (hsPkgs."hspec-expectations" or (errorHandler.buildDepError "hspec-expectations"))
            (hsPkgs."hspec-meta" or (errorHandler.buildDepError "hspec-meta"))
            (hsPkgs."process" or (errorHandler.buildDepError "process"))
            (hsPkgs."quickcheck-io" or (errorHandler.buildDepError "quickcheck-io"))
            (hsPkgs."random" or (errorHandler.buildDepError "random"))
            (hsPkgs."silently" or (errorHandler.buildDepError "silently"))
            (hsPkgs."temporary" or (errorHandler.buildDepError "temporary"))
            (hsPkgs."tf-random" or (errorHandler.buildDepError "tf-random"))
            (hsPkgs."time" or (errorHandler.buildDepError "time"))
            (hsPkgs."transformers" or (errorHandler.buildDepError "transformers"))
          ] ++ pkgs.lib.optional (compiler.isGhc && compiler.version.ge "8.4.1") (hsPkgs."stm" or (errorHandler.buildDepError "stm"));
          build-tools = [
            (hsPkgs.pkgsBuildBuild.hspec-meta.components.exes.hspec-meta-discover or (pkgs.pkgsBuildBuild.hspec-meta-discover or (errorHandler.buildToolDepError "hspec-meta:hspec-meta-discover")))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/hspec-core-2.11.14.tar.gz";
      sha256 = "2909fdae00bfb0fd0e995e8da44a7c54591615af50aaca3ad135523f25dbcb42";
    });
  }) // {
    package-description-override = "cabal-version: 1.12\r\n\r\n-- This file has been generated from package.yaml by hpack version 0.38.1.\r\n--\r\n-- see: https://github.com/sol/hpack\r\n\r\nname:             hspec-core\r\nversion:          2.11.14\r\nx-revision: 1\r\nlicense:          MIT\r\nlicense-file:     LICENSE\r\ncopyright:        (c) 2011-2025 Simon Hengel,\r\n                  (c) 2011-2012 Trystan Spangler,\r\n                  (c) 2011 Greg Weber\r\nmaintainer:       Simon Hengel <sol@typeful.net>\r\nbuild-type:       Simple\r\nextra-source-files:\r\n    version.yaml\r\n    help.txt\r\ncategory:         Testing\r\nstability:        experimental\r\nbug-reports:      https://github.com/hspec/hspec/issues\r\nauthor:           Simon Hengel <sol@typeful.net>\r\nhomepage:         https://hspec.github.io/\r\nsynopsis:         A Testing Framework for Haskell\r\ndescription:      This package exposes internal types and functions that can be used to extend Hspec's functionality.\r\n\r\nsource-repository head\r\n  type: git\r\n  location: https://github.com/hspec/hspec\r\n  subdir: hspec-core\r\n\r\nlibrary\r\n  hs-source-dirs:\r\n      src\r\n      vendor\r\n  ghc-options: -Wall -fno-warn-incomplete-uni-patterns\r\n  build-depends:\r\n      HUnit ==1.6.*\r\n    , QuickCheck >=2.13.1 && <2.18\r\n    , ansi-terminal >=0.6.2\r\n    , array\r\n    , base >=4.9.0.0 && <5\r\n    , call-stack >=0.2.0\r\n    , containers\r\n    , deepseq\r\n    , directory\r\n    , filepath\r\n    , haskell-lexer\r\n    , hspec-expectations ==0.8.4.*\r\n    , process\r\n    , quickcheck-io >=0.2.0\r\n    , random\r\n    , tf-random\r\n    , time\r\n    , transformers >=0.2.2.0\r\n  exposed-modules:\r\n      Test.Hspec.Core.Extension\r\n      Test.Hspec.Core.Extension.Item\r\n      Test.Hspec.Core.Extension.Spec\r\n      Test.Hspec.Core.Extension.Tree\r\n      Test.Hspec.Core.Extension.Option\r\n      Test.Hspec.Core.Extension.Config\r\n      Test.Hspec.Core.Spec\r\n      Test.Hspec.Core.Hooks\r\n      Test.Hspec.Core.Runner\r\n      Test.Hspec.Core.Format\r\n      Test.Hspec.Core.Formatters\r\n      Test.Hspec.Core.Formatters.V1\r\n      Test.Hspec.Core.Formatters.V2\r\n      Test.Hspec.Core.QuickCheck\r\n      Test.Hspec.Core.Util\r\n  other-modules:\r\n      GetOpt.Declarative\r\n      GetOpt.Declarative.Environment\r\n      GetOpt.Declarative.Interpret\r\n      GetOpt.Declarative.Types\r\n      GetOpt.Declarative.Util\r\n      NonEmpty\r\n      Test.Hspec.Core.Annotations\r\n      Test.Hspec.Core.Clock\r\n      Test.Hspec.Core.Compat\r\n      Test.Hspec.Core.Config\r\n      Test.Hspec.Core.Config.Definition\r\n      Test.Hspec.Core.Config.Options\r\n      Test.Hspec.Core.Example\r\n      Test.Hspec.Core.Example.Location\r\n      Test.Hspec.Core.Extension.Config.Type\r\n      Test.Hspec.Core.FailureReport\r\n      Test.Hspec.Core.Formatters.Diff\r\n      Test.Hspec.Core.Formatters.Internal\r\n      Test.Hspec.Core.Formatters.Pretty\r\n      Test.Hspec.Core.Formatters.Pretty.Parser\r\n      Test.Hspec.Core.Formatters.Pretty.Unicode\r\n      Test.Hspec.Core.Formatters.V1.Free\r\n      Test.Hspec.Core.Formatters.V1.Internal\r\n      Test.Hspec.Core.Formatters.V1.Monad\r\n      Test.Hspec.Core.QuickCheck.Util\r\n      Test.Hspec.Core.Runner.Eval\r\n      Test.Hspec.Core.Runner.JobQueue\r\n      Test.Hspec.Core.Runner.PrintSlowSpecItems\r\n      Test.Hspec.Core.Runner.Result\r\n      Test.Hspec.Core.Shuffle\r\n      Test.Hspec.Core.Spec.Monad\r\n      Test.Hspec.Core.Timer\r\n      Test.Hspec.Core.Tree\r\n      Control.Concurrent.Async\r\n      Data.Algorithm.Diff\r\n      Paths_hspec_core\r\n  default-language: Haskell2010\r\n  if impl(ghc >= 8.4.1)\r\n    build-depends:\r\n        stm >=2.2\r\n  else\r\n    other-modules:\r\n        Control.Concurrent.STM.TMVar\r\n    hs-source-dirs:\r\n        vendor/stm-2.5.0.1/\r\n\r\ntest-suite spec\r\n  type: exitcode-stdio-1.0\r\n  main-is: Spec.hs\r\n  hs-source-dirs:\r\n      src\r\n      vendor\r\n      test\r\n  ghc-options: -Wall -fno-warn-incomplete-uni-patterns\r\n  cpp-options: -DTEST\r\n  build-depends:\r\n      HUnit ==1.6.*\r\n    , QuickCheck >=2.14\r\n    , ansi-terminal >=0.6.2\r\n    , array\r\n    , base >=4.9.0.0 && <5\r\n    , base-orphans\r\n    , call-stack >=0.2.0\r\n    , containers\r\n    , deepseq\r\n    , directory\r\n    , filepath\r\n    , haskell-lexer\r\n    , hspec-expectations ==0.8.4.*\r\n    , hspec-meta ==2.11.14\r\n    , process\r\n    , quickcheck-io >=0.2.0\r\n    , random\r\n    , silently >=1.2.4\r\n    , temporary\r\n    , tf-random\r\n    , time\r\n    , transformers >=0.2.2.0\r\n  build-tool-depends:\r\n      hspec-meta:hspec-meta-discover\r\n  other-modules:\r\n      GetOpt.Declarative\r\n      GetOpt.Declarative.Environment\r\n      GetOpt.Declarative.Interpret\r\n      GetOpt.Declarative.Types\r\n      GetOpt.Declarative.Util\r\n      NonEmpty\r\n      Test.Hspec.Core.Annotations\r\n      Test.Hspec.Core.Clock\r\n      Test.Hspec.Core.Compat\r\n      Test.Hspec.Core.Config\r\n      Test.Hspec.Core.Config.Definition\r\n      Test.Hspec.Core.Config.Options\r\n      Test.Hspec.Core.Example\r\n      Test.Hspec.Core.Example.Location\r\n      Test.Hspec.Core.Extension\r\n      Test.Hspec.Core.Extension.Config\r\n      Test.Hspec.Core.Extension.Config.Type\r\n      Test.Hspec.Core.Extension.Item\r\n      Test.Hspec.Core.Extension.Option\r\n      Test.Hspec.Core.Extension.Spec\r\n      Test.Hspec.Core.Extension.Tree\r\n      Test.Hspec.Core.FailureReport\r\n      Test.Hspec.Core.Format\r\n      Test.Hspec.Core.Formatters\r\n      Test.Hspec.Core.Formatters.Diff\r\n      Test.Hspec.Core.Formatters.Internal\r\n      Test.Hspec.Core.Formatters.Pretty\r\n      Test.Hspec.Core.Formatters.Pretty.Parser\r\n      Test.Hspec.Core.Formatters.Pretty.Unicode\r\n      Test.Hspec.Core.Formatters.V1\r\n      Test.Hspec.Core.Formatters.V1.Free\r\n      Test.Hspec.Core.Formatters.V1.Internal\r\n      Test.Hspec.Core.Formatters.V1.Monad\r\n      Test.Hspec.Core.Formatters.V2\r\n      Test.Hspec.Core.Hooks\r\n      Test.Hspec.Core.QuickCheck\r\n      Test.Hspec.Core.QuickCheck.Util\r\n      Test.Hspec.Core.Runner\r\n      Test.Hspec.Core.Runner.Eval\r\n      Test.Hspec.Core.Runner.JobQueue\r\n      Test.Hspec.Core.Runner.PrintSlowSpecItems\r\n      Test.Hspec.Core.Runner.Result\r\n      Test.Hspec.Core.Shuffle\r\n      Test.Hspec.Core.Spec\r\n      Test.Hspec.Core.Spec.Monad\r\n      Test.Hspec.Core.Timer\r\n      Test.Hspec.Core.Tree\r\n      Test.Hspec.Core.Util\r\n      Control.Concurrent.Async\r\n      Data.Algorithm.Diff\r\n      GetOpt.Declarative.EnvironmentSpec\r\n      GetOpt.Declarative.UtilSpec\r\n      Helper\r\n      Mock\r\n      SpecHook\r\n      Test.Hspec.Core.AnnotationsSpec\r\n      Test.Hspec.Core.ClockSpec\r\n      Test.Hspec.Core.CompatSpec\r\n      Test.Hspec.Core.Config.DefinitionSpec\r\n      Test.Hspec.Core.Config.OptionsSpec\r\n      Test.Hspec.Core.ConfigSpec\r\n      Test.Hspec.Core.Example.LocationSpec\r\n      Test.Hspec.Core.ExampleSpec\r\n      Test.Hspec.Core.FailureReportSpec\r\n      Test.Hspec.Core.FormatSpec\r\n      Test.Hspec.Core.Formatters.DiffSpec\r\n      Test.Hspec.Core.Formatters.InternalSpec\r\n      Test.Hspec.Core.Formatters.Pretty.ParserSpec\r\n      Test.Hspec.Core.Formatters.Pretty.UnicodeSpec\r\n      Test.Hspec.Core.Formatters.PrettySpec\r\n      Test.Hspec.Core.Formatters.V1Spec\r\n      Test.Hspec.Core.Formatters.V2Spec\r\n      Test.Hspec.Core.HooksSpec\r\n      Test.Hspec.Core.QuickCheck.UtilSpec\r\n      Test.Hspec.Core.Runner.EvalSpec\r\n      Test.Hspec.Core.Runner.JobQueueSpec\r\n      Test.Hspec.Core.Runner.PrintSlowSpecItemsSpec\r\n      Test.Hspec.Core.Runner.ResultSpec\r\n      Test.Hspec.Core.RunnerSpec\r\n      Test.Hspec.Core.ShuffleSpec\r\n      Test.Hspec.Core.SpecSpec\r\n      Test.Hspec.Core.TimerSpec\r\n      Test.Hspec.Core.TreeSpec\r\n      Test.Hspec.Core.UtilSpec\r\n      Paths_hspec_core\r\n  default-language: Haskell2010\r\n  if impl(ghc >= 8.4.1)\r\n    build-depends:\r\n        stm >=2.2\r\n  else\r\n    other-modules:\r\n        Control.Concurrent.STM.TMVar\r\n    hs-source-dirs:\r\n        vendor/stm-2.5.0.1/\r\n";
  }