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
    flags = { bench = false; };
    package = {
      specVersion = "1.10";
      identifier = { name = "async"; version = "2.2.5"; };
      license = "BSD-3-Clause";
      copyright = "(c) Simon Marlow 2012";
      maintainer = "Simon Marlow <marlowsd@gmail.com>";
      author = "Simon Marlow";
      homepage = "https://github.com/simonmar/async";
      url = "";
      synopsis = "Run IO operations asynchronously and wait for their results";
      description = "This package provides a higher-level interface over\nthreads, in which an @Async a@ is a concurrent\nthread that will eventually deliver a value of\ntype @a@.  The package provides ways to create\n@Async@ computations, wait for their results, and\ncancel them.\n\nUsing @Async@ is safer than using threads in two\nways:\n\n* When waiting for a thread to return a result,\nif the thread dies with an exception then the\ncaller must either re-throw the exception\n('wait') or handle it ('waitCatch'); the\nexception cannot be ignored.\n\n* The API makes it possible to build a tree of\nthreads that are automatically killed when\ntheir parent dies (see 'withAsync').";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."hashable" or (errorHandler.buildDepError "hashable"))
          (hsPkgs."stm" or (errorHandler.buildDepError "stm"))
        ];
        buildable = true;
      };
      exes = {
        "concasync" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."async" or (errorHandler.buildDepError "async"))
            (hsPkgs."stm" or (errorHandler.buildDepError "stm"))
          ];
          buildable = if !flags.bench then false else true;
        };
        "conccancel" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."async" or (errorHandler.buildDepError "async"))
            (hsPkgs."stm" or (errorHandler.buildDepError "stm"))
          ];
          buildable = if !flags.bench then false else true;
        };
        "race" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."async" or (errorHandler.buildDepError "async"))
            (hsPkgs."stm" or (errorHandler.buildDepError "stm"))
          ];
          buildable = if !flags.bench then false else true;
        };
      };
      tests = {
        "test-async" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."async" or (errorHandler.buildDepError "async"))
            (hsPkgs."stm" or (errorHandler.buildDepError "stm"))
            (hsPkgs."test-framework" or (errorHandler.buildDepError "test-framework"))
            (hsPkgs."test-framework-hunit" or (errorHandler.buildDepError "test-framework-hunit"))
            (hsPkgs."HUnit" or (errorHandler.buildDepError "HUnit"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/async-2.2.5.tar.gz";
      sha256 = "1818473ebab9212afad2ed76297aefde5fae8b5d4404daf36939aece6a8f16f7";
    });
  }) // {
    package-description-override = "name:                async\r\nversion:             2.2.5\r\nx-revision: 3\r\n-- don't forget to update ./changelog.md!\r\nsynopsis:            Run IO operations asynchronously and wait for their results\r\n\r\ndescription:\r\n This package provides a higher-level interface over\r\n threads, in which an @Async a@ is a concurrent\r\n thread that will eventually deliver a value of\r\n type @a@.  The package provides ways to create\r\n @Async@ computations, wait for their results, and\r\n cancel them.\r\n .\r\n Using @Async@ is safer than using threads in two\r\n ways:\r\n .\r\n * When waiting for a thread to return a result,\r\n   if the thread dies with an exception then the\r\n   caller must either re-throw the exception\r\n   ('wait') or handle it ('waitCatch'); the\r\n   exception cannot be ignored.\r\n .\r\n * The API makes it possible to build a tree of\r\n   threads that are automatically killed when\r\n   their parent dies (see 'withAsync').\r\n\r\nlicense:             BSD3\r\nlicense-file:        LICENSE\r\nauthor:              Simon Marlow\r\nmaintainer:          Simon Marlow <marlowsd@gmail.com>\r\ncopyright:           (c) Simon Marlow 2012\r\ncategory:            Concurrency\r\nbuild-type:          Simple\r\ncabal-version:       >=1.10\r\nhomepage:            https://github.com/simonmar/async\r\nbug-reports:         https://github.com/simonmar/async/issues\r\ntested-with:\r\n    GHC == 9.10.1\r\n    GHC == 9.8.2\r\n    GHC == 9.6.6\r\n    GHC == 9.4.8\r\n    GHC == 9.2.8\r\n    GHC == 9.0.2\r\n    GHC == 8.10.7\r\n    GHC == 8.8.4\r\n    GHC == 8.6.5\r\n    GHC == 8.4.4\r\n    GHC == 8.2.2\r\n    GHC == 8.0.2\r\n    -- CI does not support GHC 7\r\n    -- GHC == 7.10.3\r\n    -- GHC == 7.8.4\r\n    -- GHC == 7.6.3\r\n    -- GHC == 7.4.2\r\n    -- GHC == 7.2.2\r\n    -- GHC == 7.0.4\r\n\r\nextra-source-files:\r\n    changelog.md\r\n    bench/race.hs\r\n\r\nsource-repository head\r\n    type: git\r\n    location: https://github.com/simonmar/async.git\r\n\r\nlibrary\r\n    default-language:    Haskell2010\r\n    other-extensions:    CPP, MagicHash, RankNTypes, UnboxedTuples\r\n    if impl(ghc>=7.1)\r\n        other-extensions: Trustworthy\r\n    exposed-modules:     Control.Concurrent.Async\r\n                         Control.Concurrent.Async.Internal\r\n    build-depends:       base     >= 4.3     && < 4.22,\r\n                         hashable >= 1.1.2.0 && < 1.6,\r\n                         stm      >= 2.2     && < 2.6\r\n\r\ntest-suite test-async\r\n    default-language: Haskell2010\r\n    type:       exitcode-stdio-1.0\r\n    hs-source-dirs: test\r\n    main-is:    test-async.hs\r\n    build-depends: base,\r\n                   async,\r\n                   stm,\r\n                   test-framework,\r\n                   test-framework-hunit,\r\n                   HUnit\r\n\r\nflag bench\r\n    default: False\r\n\r\nexecutable concasync\r\n    if !flag(bench)\r\n       buildable: False\r\n    default-language: Haskell2010\r\n    hs-source-dirs: bench\r\n    main-is:    concasync.hs\r\n    build-depends: base, async, stm\r\n    ghc-options: -O2\r\n\r\nexecutable conccancel\r\n    if !flag(bench)\r\n       buildable: False\r\n    default-language: Haskell2010\r\n    hs-source-dirs: bench\r\n    main-is:    conccancel.hs\r\n    build-depends: base, async, stm\r\n    ghc-options: -O2 -threaded\r\n\r\nexecutable race\r\n    if !flag(bench)\r\n       buildable: False\r\n    default-language: Haskell2010\r\n    hs-source-dirs: bench\r\n    main-is:    race.hs\r\n    build-depends: base, async, stm\r\n    ghc-options: -O2 -threaded\r\n";
  }