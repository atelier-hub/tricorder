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
    flags = { unix = true; };
    package = {
      specVersion = "1.10";
      identifier = { name = "tasty"; version = "1.5.3"; };
      license = "MIT";
      copyright = "";
      maintainer = "Roman Cheplyaka <roma@ro-che.info>";
      author = "Roman Cheplyaka <roma@ro-che.info>";
      homepage = "https://github.com/UnkindPartition/tasty";
      url = "";
      synopsis = "Modern and extensible testing framework";
      description = "Tasty is a modern testing framework for Haskell.\nIt lets you combine your unit tests, golden\ntests, QuickCheck/SmallCheck properties, and any\nother types of tests into a single test suite.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = ((([
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."stm" or (errorHandler.buildDepError "stm"))
          (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
          (hsPkgs."transformers" or (errorHandler.buildDepError "transformers"))
          (hsPkgs."tagged" or (errorHandler.buildDepError "tagged"))
          (hsPkgs."optparse-applicative" or (errorHandler.buildDepError "optparse-applicative"))
          (hsPkgs."ansi-terminal" or (errorHandler.buildDepError "ansi-terminal"))
        ] ++ pkgs.lib.optional (!system.isX86_64 && !system.isAarch64 && !system.isPpc64 && !system.isS390x && !system.isRiscv64) (hsPkgs."unbounded-delays" or (errorHandler.buildDepError "unbounded-delays"))) ++ pkgs.lib.optional (!(compiler.isGhc && compiler.version.ge "8.0")) (hsPkgs."semigroups" or (errorHandler.buildDepError "semigroups"))) ++ pkgs.lib.optional (!(compiler.isGhc && compiler.version.ge "8.4")) (hsPkgs."time" or (errorHandler.buildDepError "time"))) ++ pkgs.lib.optionals (!system.isWindows && !(compiler.isGhcjs && true)) (pkgs.lib.optional (flags.unix) (hsPkgs."unix" or (errorHandler.buildDepError "unix")));
        buildable = true;
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/tasty-1.5.3.tar.gz";
      sha256 = "54a0c7b644813af871a3726ac8771b5e17b5158c792a7acf8f9e2d3ae9360780";
    });
  }) // {
    package-description-override = "cabal-version:       >=1.10\r\nname:                tasty\r\nversion:             1.5.3\r\nx-revision: 2\r\nsynopsis:            Modern and extensible testing framework\r\ndescription:         Tasty is a modern testing framework for Haskell.\r\n                     It lets you combine your unit tests, golden\r\n                     tests, QuickCheck/SmallCheck properties, and any\r\n                     other types of tests into a single test suite.\r\nlicense:             MIT\r\nlicense-file:        LICENSE\r\nauthor:              Roman Cheplyaka <roma@ro-che.info>\r\nmaintainer:          Roman Cheplyaka <roma@ro-che.info>\r\nhomepage:            https://github.com/UnkindPartition/tasty\r\nbug-reports:         https://github.com/UnkindPartition/tasty/issues\r\n-- copyright:\r\ncategory:            Testing\r\nbuild-type:          Simple\r\nextra-source-files:  CHANGELOG.md, README.md\r\n\r\nSource-repository head\r\n  type:     git\r\n  location: https://github.com/UnkindPartition/tasty.git\r\n  subdir:   core\r\n\r\nflag unix\r\n  description:\r\n    Depend on the unix package to install signal handlers\r\n  default: True\r\n\r\nlibrary\r\n  exposed-modules:\r\n    Test.Tasty,\r\n    Test.Tasty.Options,\r\n    Test.Tasty.Providers,\r\n    Test.Tasty.Providers.ConsoleFormat,\r\n    Test.Tasty.Runners\r\n    Test.Tasty.Ingredients,\r\n    Test.Tasty.Ingredients.Basic\r\n    Test.Tasty.Ingredients.ConsoleReporter\r\n\r\n    -- for testing only\r\n    Test.Tasty.Patterns.Types\r\n    Test.Tasty.Patterns.Parser\r\n    Test.Tasty.Patterns.Printer\r\n    Test.Tasty.Patterns.Eval\r\n  other-modules:\r\n    Control.Concurrent.Async\r\n    Test.Tasty.Parallel,\r\n    Test.Tasty.Core,\r\n    Test.Tasty.Options.Core,\r\n    Test.Tasty.Options.Env,\r\n    Test.Tasty.Patterns,\r\n    Test.Tasty.Patterns.Expr,\r\n    Test.Tasty.Run,\r\n    Test.Tasty.Runners.Reducers,\r\n    Test.Tasty.Runners.Utils,\r\n    Test.Tasty.CmdLine,\r\n    Test.Tasty.Ingredients.ListTests\r\n    Test.Tasty.Ingredients.IncludingOptions\r\n\r\n  build-depends:\r\n    base                 >= 4.9  && < 5,\r\n    stm                  >= 2.3  && < 2.6,\r\n    containers           >= 0.5.8 && < 0.9,\r\n    transformers         >= 0.5  && < 0.7,\r\n    tagged               >= 0.5  && < 0.9,\r\n    optparse-applicative >= 0.14 && < 0.20,\r\n    ansi-terminal        >= 0.9  && < 1.2\r\n\r\n  -- No reason to depend on unbounded-delays on 64-bit architecture\r\n  if(!arch(x86_64) && !arch(aarch64) && !arch(ppc64) && !arch(s390x) && !arch(riscv64))\r\n    build-depends:\r\n      unbounded-delays >= 0.1 && < 0.2\r\n\r\n  if(!impl(ghc >= 8.0))\r\n    build-depends: semigroups < 0.21\r\n\r\n  if(!impl(ghc >= 8.4))\r\n    build-depends: time >= 1.4 && < 1.13\r\n\r\n  if !os(windows) && !impl(ghcjs)\r\n    cpp-options: -DUSE_WCWIDTH\r\n    if flag(unix)\r\n      build-depends: unix < 2.9\r\n\r\n  -- hs-source-dirs:\r\n  default-language:    Haskell2010\r\n  default-extensions:  CPP, ScopedTypeVariables, DeriveDataTypeable\r\n  ghc-options:\r\n    -Wall\r\n    -Wno-incomplete-uni-patterns\r\n    -Wcompat\r\n";
  }