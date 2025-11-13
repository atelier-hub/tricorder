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
    flags = { templatehaskell = true; old-random = false; };
    package = {
      specVersion = "1.10";
      identifier = { name = "QuickCheck"; version = "2.15.0.1"; };
      license = "BSD-3-Clause";
      copyright = "2000-2019 Koen Claessen, 2006-2008 Björn Bringert, 2009-2019 Nick Smallbone";
      maintainer = "Nick Smallbone <nick@smallbone.se>";
      author = "Koen Claessen <koen@chalmers.se>";
      homepage = "https://github.com/nick8325/quickcheck";
      url = "";
      synopsis = "Automatic testing of Haskell programs";
      description = "QuickCheck is a library for random testing of program properties.\nThe programmer provides a specification of the program, in the form of\nproperties which functions should satisfy, and QuickCheck then tests that the\nproperties hold in a large number of randomly generated cases.\nSpecifications are expressed in Haskell, using combinators provided by\nQuickCheck. QuickCheck provides combinators to define properties, observe the\ndistribution of test data, and define test data generators.\n\nMost of QuickCheck's functionality is exported by the main \"Test.QuickCheck\"\nmodule. The main exception is the monadic property testing library in\n\"Test.QuickCheck.Monadic\".\n\nIf you are new to QuickCheck, you can try looking at the following resources:\n\n* The <http://www.cse.chalmers.se/~rjmh/QuickCheck/manual.html official QuickCheck manual>.\nIt's a bit out-of-date in some details and doesn't cover newer QuickCheck features,\nbut is still full of good advice.\n* <https://begriffs.com/posts/2017-01-14-design-use-quickcheck.html>,\na detailed tutorial written by a user of QuickCheck.\n\nThe <https://hackage.haskell.org/package/quickcheck-instances quickcheck-instances>\ncompanion package provides instances for types in Haskell Platform packages\nat the cost of additional dependencies.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = ((((((([
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
        ] ++ [
          (hsPkgs."random" or (errorHandler.buildDepError "random"))
        ]) ++ pkgs.lib.optional (!(compiler.isHugs && true)) (hsPkgs."splitmix" or (errorHandler.buildDepError "splitmix"))) ++ pkgs.lib.optionals (compiler.isGhc && true) [
          (hsPkgs."transformers" or (errorHandler.buildDepError "transformers"))
          (hsPkgs."deepseq" or (errorHandler.buildDepError "deepseq"))
        ]) ++ pkgs.lib.optional (compiler.isGhc && true && flags.templatehaskell) (hsPkgs."template-haskell" or (errorHandler.buildDepError "template-haskell"))) ++ pkgs.lib.optional (compiler.isGhc && compiler.version.ge "7.2" && (compiler.isGhc && compiler.version.lt "7.6")) (hsPkgs."ghc-prim" or (errorHandler.buildDepError "ghc-prim"))) ++ pkgs.lib.optional (compiler.isGhc && compiler.version.ge "7.2") (hsPkgs."random" or (errorHandler.buildDepError "random"))) ++ pkgs.lib.optional (compiler.isGhc && compiler.version.ge "7.4") (hsPkgs."containers" or (errorHandler.buildDepError "containers"))) ++ pkgs.lib.optionals (compiler.isUhc && true) [
          (hsPkgs."old-time" or (errorHandler.buildDepError "old-time"))
          (hsPkgs."old-locale" or (errorHandler.buildDepError "old-locale"))
        ];
        buildable = true;
      };
      tests = {
        "test-quickcheck" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."QuickCheck" or (errorHandler.buildDepError "QuickCheck"))
          ];
          buildable = if !flags.templatehaskell then false else true;
        };
        "test-quickcheck-gcoarbitrary" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."QuickCheck" or (errorHandler.buildDepError "QuickCheck"))
          ] ++ pkgs.lib.optional (compiler.isGhc && compiler.version.ge "7.2" && (compiler.isGhc && compiler.version.lt "7.6")) (hsPkgs."ghc-prim" or (errorHandler.buildDepError "ghc-prim"));
          buildable = if !flags.templatehaskell || !(compiler.isGhc && compiler.version.ge "7.2")
            then false
            else true;
        };
        "test-quickcheck-generators" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."QuickCheck" or (errorHandler.buildDepError "QuickCheck"))
          ];
          buildable = if !flags.templatehaskell then false else true;
        };
        "test-quickcheck-gshrink" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."QuickCheck" or (errorHandler.buildDepError "QuickCheck"))
          ] ++ pkgs.lib.optional (compiler.isGhc && compiler.version.ge "7.2" && (compiler.isGhc && compiler.version.lt "7.6")) (hsPkgs."ghc-prim" or (errorHandler.buildDepError "ghc-prim"));
          buildable = if !flags.templatehaskell || !(compiler.isGhc && compiler.version.ge "7.2")
            then false
            else true;
        };
        "test-quickcheck-terminal" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."process" or (errorHandler.buildDepError "process"))
            (hsPkgs."deepseq" or (errorHandler.buildDepError "deepseq"))
            (hsPkgs."QuickCheck" or (errorHandler.buildDepError "QuickCheck"))
          ];
          buildable = if !flags.templatehaskell || !(compiler.isGhc && compiler.version.ge "7.10")
            then false
            else true;
        };
        "test-quickcheck-monadfix" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."QuickCheck" or (errorHandler.buildDepError "QuickCheck"))
          ];
          buildable = if !flags.templatehaskell || !(compiler.isGhc && compiler.version.ge "7.10")
            then false
            else true;
        };
        "test-quickcheck-split" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."QuickCheck" or (errorHandler.buildDepError "QuickCheck"))
          ];
          buildable = true;
        };
        "test-quickcheck-strictness" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."QuickCheck" or (errorHandler.buildDepError "QuickCheck"))
            (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
          ];
          buildable = if !flags.templatehaskell || !(compiler.isGhc && compiler.version.ge "7.10")
            then false
            else true;
        };
        "test-quickcheck-misc" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."QuickCheck" or (errorHandler.buildDepError "QuickCheck"))
            (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
          ];
          buildable = if !flags.templatehaskell || !(compiler.isGhc && compiler.version.ge "7.10")
            then false
            else true;
        };
        "test-quickcheck-discard" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."QuickCheck" or (errorHandler.buildDepError "QuickCheck"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/QuickCheck-2.15.0.1.tar.gz";
      sha256 = "a3b2216ddbaf481dbc82414b6120f8b726d969db3f0b51f20a7a45425ef36e7f";
    });
  }) // {
    package-description-override = "Name: QuickCheck\r\nVersion: 2.15.0.1\r\nx-revision: 1\r\nCabal-Version: >= 1.10\r\nBuild-type: Simple\r\nLicense: BSD3\r\nLicense-file: LICENSE\r\nCopyright: 2000-2019 Koen Claessen, 2006-2008 Björn Bringert, 2009-2019 Nick Smallbone\r\nAuthor: Koen Claessen <koen@chalmers.se>\r\nMaintainer: Nick Smallbone <nick@smallbone.se>\r\nBug-reports: https://github.com/nick8325/quickcheck/issues\r\nTested-with: GHC == 7.0.4  ||\r\n                 == 7.2.2  ||\r\n                 == 7.4.1  ||\r\n                 == 7.4.2  ||\r\n                 == 7.6.3  ||\r\n                 == 7.8.4  ||\r\n                 == 7.10.3 ||\r\n                 == 8.0.2  ||\r\n                 >= 8.2.2 && < 9.10\r\nHomepage: https://github.com/nick8325/quickcheck\r\nCategory:       Testing\r\nSynopsis:       Automatic testing of Haskell programs\r\nDescription:\r\n  QuickCheck is a library for random testing of program properties.\r\n  The programmer provides a specification of the program, in the form of\r\n  properties which functions should satisfy, and QuickCheck then tests that the\r\n  properties hold in a large number of randomly generated cases.\r\n  Specifications are expressed in Haskell, using combinators provided by\r\n  QuickCheck. QuickCheck provides combinators to define properties, observe the\r\n  distribution of test data, and define test data generators.\r\n  .\r\n  Most of QuickCheck's functionality is exported by the main \"Test.QuickCheck\"\r\n  module. The main exception is the monadic property testing library in\r\n  \"Test.QuickCheck.Monadic\".\r\n  .\r\n  If you are new to QuickCheck, you can try looking at the following resources:\r\n  .\r\n  * The <http://www.cse.chalmers.se/~rjmh/QuickCheck/manual.html official QuickCheck manual>.\r\n    It's a bit out-of-date in some details and doesn't cover newer QuickCheck features,\r\n    but is still full of good advice.\r\n  * <https://begriffs.com/posts/2017-01-14-design-use-quickcheck.html>,\r\n    a detailed tutorial written by a user of QuickCheck.\r\n  .\r\n  The <https://hackage.haskell.org/package/quickcheck-instances quickcheck-instances>\r\n  companion package provides instances for types in Haskell Platform packages\r\n  at the cost of additional dependencies.\r\n\r\nextra-source-files:\r\n  README\r\n  changelog\r\n  examples/Heap.hs\r\n  examples/Heap_Program.hs\r\n  examples/Heap_ProgramAlgebraic.hs\r\n  examples/Lambda.hs\r\n  examples/Merge.hs\r\n  examples/Set.hs\r\n  examples/Simple.hs\r\n  make-hugs\r\n  test-hugs\r\n\r\nsource-repository head\r\n  type:     git\r\n  location: https://github.com/nick8325/quickcheck\r\n\r\nsource-repository this\r\n  type:     git\r\n  location: https://github.com/nick8325/quickcheck\r\n  tag:      2.15.0.1\r\n\r\nflag templateHaskell\r\n  Description: Build Test.QuickCheck.All, which uses Template Haskell.\r\n  Default: True\r\n  Manual: True\r\n\r\nflag old-random\r\n  Description: Build against a pre-1.2.0 version of the random package.\r\n  Default: False\r\n  Manual: False\r\n\r\nlibrary\r\n  Hs-source-dirs: src\r\n  Build-depends: base >=4.3 && <5, containers\r\n  Default-language: Haskell2010\r\n\r\n  -- New vs old random.\r\n  if flag(old-random)\r\n    Build-depends: random >= 1.0.0.3 && < 1.2.0\r\n    cpp-options: -DOLD_RANDOM\r\n  else\r\n    Build-depends: random >= 1.2.0 && < 1.4\r\n\r\n  -- We always use splitmix directly rather than going through StdGen\r\n  -- (it's somewhat more efficient).\r\n  -- However, Hugs traps overflow on Word64, so we have to stick\r\n  -- with StdGen there.\r\n  if impl(hugs)\r\n    cpp-options: -DNO_SPLITMIX\r\n  else\r\n    Build-depends: splitmix >= 0.1.0.2 && <0.2\r\n\r\n  -- Modules that are always built.\r\n  Exposed-Modules:\r\n    Test.QuickCheck,\r\n    Test.QuickCheck.Arbitrary,\r\n    Test.QuickCheck.Gen,\r\n    Test.QuickCheck.Gen.Unsafe,\r\n    Test.QuickCheck.Monadic,\r\n    Test.QuickCheck.Modifiers,\r\n    Test.QuickCheck.Property,\r\n    Test.QuickCheck.Test,\r\n    Test.QuickCheck.Text,\r\n    Test.QuickCheck.Poly,\r\n    Test.QuickCheck.State,\r\n    Test.QuickCheck.Random,\r\n    Test.QuickCheck.Exception,\r\n    Test.QuickCheck.Features\r\n\r\n  -- GHC-specific modules.\r\n  if impl(ghc)\r\n    Exposed-Modules: Test.QuickCheck.Function\r\n    Build-depends: transformers >= 0.3, deepseq >= 1.1.0.0\r\n  else\r\n    cpp-options: -DNO_TRANSFORMERS -DNO_DEEPSEQ\r\n\r\n  if impl(ghc) && flag(templateHaskell)\r\n    Build-depends: template-haskell >= 2.4\r\n    if impl(ghc >=8.0)\r\n      Other-Extensions: TemplateHaskellQuotes\r\n    else\r\n      Other-Extensions: TemplateHaskell\r\n    Exposed-Modules: Test.QuickCheck.All\r\n  else\r\n    cpp-options: -DNO_TEMPLATE_HASKELL\r\n\r\n  if !impl(ghc >= 8.0)\r\n    cpp-options: -DNO_CALLSTACK\r\n\r\n  if !impl(ghc >= 7.4)\r\n    cpp-options: -DNO_CTYPES_CONSTRUCTORS -DNO_FOREIGN_C_USECONDS\r\n\r\n  -- The new generics appeared in GHC 7.2...\r\n  if impl(ghc < 7.2)\r\n    cpp-options: -DNO_GENERICS\r\n  -- ...but in 7.2-7.4 it lives in the ghc-prim package.\r\n  if impl(ghc >= 7.2) && impl(ghc < 7.6)\r\n    Build-depends: ghc-prim\r\n\r\n  -- Safe Haskell appeared in GHC 7.2, but GHC.Generics isn't safe until 7.4.\r\n  if impl (ghc < 7.4)\r\n    cpp-options: -DNO_SAFE_HASKELL\r\n\r\n  -- random is explicitly Trustworthy since 1.0.1.0\r\n  -- similar constraint for containers\r\n  if impl(ghc >= 7.2)\r\n    Build-depends: random >=1.0.1.0\r\n  if impl(ghc >= 7.4)\r\n    Build-depends: containers >=0.4.2.1\r\n\r\n  if !impl(ghc >= 7.6)\r\n      cpp-options: -DNO_POLYKINDS\r\n\r\n  if !impl(ghc >= 8.0)\r\n    cpp-options: -DNO_MONADFAIL\r\n\r\n  if impl(ghc >= 9.8)\r\n    ghc-options: -Wno-x-partial\r\n\r\n  -- Switch off most optional features on non-GHC systems.\r\n  if !impl(ghc)\r\n    -- If your Haskell compiler can cope without some of these, please\r\n    -- send a message to the QuickCheck mailing list!\r\n    cpp-options: -DNO_TIMEOUT -DNO_NEWTYPE_DERIVING -DNO_GENERICS\r\n      -DNO_TEMPLATE_HASKELL -DNO_SAFE_HASKELL -DNO_TYPEABLE -DNO_GADTS\r\n      -DNO_EXTRA_METHODS_IN_APPLICATIVE -DOLD_RANDOM -DNO_CALLSTACK\r\n    if !impl(hugs) && !impl(uhc)\r\n      cpp-options: -DNO_ST_MONAD -DNO_MULTI_PARAM_TYPE_CLASSES\r\n\r\n  -- LANGUAGE pragmas don't have any effect in Hugs.\r\n  if impl(hugs)\r\n    Default-Extensions: CPP\r\n\r\n  if impl(uhc)\r\n    -- Cabal under UHC needs pointing out all the dependencies of the\r\n    -- random package.\r\n    Build-depends: old-time, old-locale\r\n    -- Plus some bits of the standard library are missing.\r\n    cpp-options: -DNO_FIXED -DNO_EXCEPTIONS\r\n\r\nTest-Suite test-quickcheck\r\n    type: exitcode-stdio-1.0\r\n    Default-language: Haskell2010\r\n    hs-source-dirs:\r\n        examples\r\n    main-is: Heap.hs\r\n    build-depends: base, QuickCheck\r\n    if !flag(templateHaskell)\r\n        Buildable: False\r\n\r\nTest-Suite test-quickcheck-gcoarbitrary\r\n    type: exitcode-stdio-1.0\r\n    Default-language: Haskell2010\r\n    hs-source-dirs: tests\r\n    main-is: GCoArbitraryExample.hs\r\n    build-depends: base, QuickCheck\r\n    if !flag(templateHaskell) || !impl(ghc >= 7.2)\r\n        buildable: False\r\n    if impl(ghc >= 7.2) && impl(ghc < 7.6)\r\n        build-depends: ghc-prim\r\n\r\nTest-Suite test-quickcheck-generators\r\n    type: exitcode-stdio-1.0\r\n    Default-language: Haskell2010\r\n    hs-source-dirs: tests\r\n    main-is: Generators.hs\r\n    build-depends: base, QuickCheck\r\n    if !flag(templateHaskell)\r\n        Buildable: False\r\n\r\nTest-Suite test-quickcheck-gshrink\r\n    type: exitcode-stdio-1.0\r\n    Default-language: Haskell2010\r\n    hs-source-dirs: tests\r\n    main-is: GShrinkExample.hs\r\n    build-depends: base, QuickCheck\r\n    if !flag(templateHaskell) || !impl(ghc >= 7.2)\r\n        buildable: False\r\n    if impl(ghc >= 7.2) && impl(ghc < 7.6)\r\n        build-depends: ghc-prim\r\n\r\nTest-Suite test-quickcheck-terminal\r\n    type: exitcode-stdio-1.0\r\n    Default-language: Haskell2010\r\n    hs-source-dirs: tests\r\n    main-is: Terminal.hs\r\n    build-depends: base, process, deepseq >= 1.1.0.0, QuickCheck\r\n    if !flag(templateHaskell) || !impl(ghc >= 7.10)\r\n        buildable: False\r\n\r\nTest-Suite test-quickcheck-monadfix\r\n    type: exitcode-stdio-1.0\r\n    Default-language: Haskell2010\r\n    hs-source-dirs: tests\r\n    main-is: MonadFix.hs\r\n    build-depends: base, QuickCheck\r\n    if !flag(templateHaskell) || !impl(ghc >= 7.10)\r\n        buildable: False\r\n\r\nTest-Suite test-quickcheck-split\r\n    type: exitcode-stdio-1.0\r\n    Default-language: Haskell2010\r\n    hs-source-dirs: tests\r\n    main-is: Split.hs\r\n    build-depends: base, QuickCheck\r\n    if impl(ghc >= 9.8)\r\n      ghc-options: -Wno-x-partial\r\n\r\nTest-Suite test-quickcheck-strictness\r\n    type: exitcode-stdio-1.0\r\n    Default-language: Haskell2010\r\n    hs-source-dirs: tests\r\n    main-is: Strictness.hs\r\n    build-depends: base, QuickCheck, containers\r\n    if !flag(templateHaskell) || !impl(ghc >= 7.10)\r\n        buildable: False\r\n\r\nTest-Suite test-quickcheck-misc\r\n    type: exitcode-stdio-1.0\r\n    Default-language: Haskell2010\r\n    hs-source-dirs: tests\r\n    main-is: Misc.hs\r\n    build-depends: base, QuickCheck, containers\r\n    if !flag(templateHaskell) || !impl(ghc >= 7.10)\r\n        buildable: False\r\n\r\nTest-Suite test-quickcheck-discard\r\n    type: exitcode-stdio-1.0\r\n    Default-language: Haskell2010\r\n    hs-source-dirs: tests\r\n    main-is: DiscardRatio.hs\r\n    build-depends: base, QuickCheck\r\n";
  }