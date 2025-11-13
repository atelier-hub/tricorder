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
    flags = { benchpapi = false; };
    package = {
      specVersion = "3.0";
      identifier = { name = "mwc-random"; version = "0.15.2.0"; };
      license = "BSD-2-Clause";
      copyright = "2009, 2010, 2011 Bryan O'Sullivan";
      maintainer = "Alexey Khudyakov <alexey.skladnoy@gmail.com>";
      author = "Bryan O'Sullivan <bos@serpentine.com>";
      homepage = "https://github.com/haskell/mwc-random";
      url = "";
      synopsis = "Fast, high quality pseudo random number generation";
      description = "This package contains code for generating high quality random\nnumbers that follow either a uniform or normal distribution.  The\ngenerated numbers are suitable for use in statistical applications.\n.\nThe uniform PRNG uses Marsaglia's MWC256 (also known as MWC8222)\nmultiply-with-carry generator, which has a period of 2^8222 and\nfares well in tests of randomness.  It is also extremely fast,\nbetween 2 and 3 times faster than the Mersenne Twister.\n.\nCompared to the mersenne-random package, this package has a more\nconvenient API, is faster, and supports more statistical\ndistributions.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."primitive" or (errorHandler.buildDepError "primitive"))
          (hsPkgs."random" or (errorHandler.buildDepError "random"))
          (hsPkgs."time" or (errorHandler.buildDepError "time"))
          (hsPkgs."vector" or (errorHandler.buildDepError "vector"))
          (hsPkgs."math-functions" or (errorHandler.buildDepError "math-functions"))
        ];
        buildable = true;
      };
      tests = {
        "mwc-prop-tests" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."mwc-random" or (errorHandler.buildDepError "mwc-random"))
            (hsPkgs."QuickCheck" or (errorHandler.buildDepError "QuickCheck"))
            (hsPkgs."vector" or (errorHandler.buildDepError "vector"))
            (hsPkgs."tasty" or (errorHandler.buildDepError "tasty"))
            (hsPkgs."tasty-quickcheck" or (errorHandler.buildDepError "tasty-quickcheck"))
            (hsPkgs."tasty-hunit" or (errorHandler.buildDepError "tasty-hunit"))
            (hsPkgs."random" or (errorHandler.buildDepError "random"))
            (hsPkgs."mtl" or (errorHandler.buildDepError "mtl"))
            (hsPkgs."math-functions" or (errorHandler.buildDepError "math-functions"))
          ];
          buildable = true;
        };
        "mwc-doctests" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."mwc-random" or (errorHandler.buildDepError "mwc-random"))
            (hsPkgs."doctest" or (errorHandler.buildDepError "doctest"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."primitive" or (errorHandler.buildDepError "primitive"))
            (hsPkgs."vector" or (errorHandler.buildDepError "vector"))
            (hsPkgs."random" or (errorHandler.buildDepError "random"))
          ];
          buildable = (if compiler.isGhcjs && true || compiler.isGhc && compiler.version.lt "8.0"
            then false
            else true) && (if system.isOsx && (compiler.isGhc && compiler.version.lt "9.6")
            then false
            else true);
        };
      };
      benchmarks = {
        "mwc-bench" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."vector" or (errorHandler.buildDepError "vector"))
            (hsPkgs."mersenne-random" or (errorHandler.buildDepError "mersenne-random"))
            (hsPkgs."mwc-random" or (errorHandler.buildDepError "mwc-random"))
            (hsPkgs."random" or (errorHandler.buildDepError "random"))
            (hsPkgs."tasty" or (errorHandler.buildDepError "tasty"))
            (hsPkgs."tasty-bench" or (errorHandler.buildDepError "tasty-bench"))
          ];
          buildable = true;
        };
        "mwc-bench-papi" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."vector" or (errorHandler.buildDepError "vector"))
            (hsPkgs."mersenne-random" or (errorHandler.buildDepError "mersenne-random"))
            (hsPkgs."mwc-random" or (errorHandler.buildDepError "mwc-random"))
            (hsPkgs."random" or (errorHandler.buildDepError "random"))
            (hsPkgs."tasty" or (errorHandler.buildDepError "tasty"))
            (hsPkgs."tasty-papi" or (errorHandler.buildDepError "tasty-papi"))
          ];
          buildable = if compiler.isGhcjs && true || !flags.benchpapi || compiler.isGhc && compiler.version.lt "8.2"
            then false
            else true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/mwc-random-0.15.2.0.tar.gz";
      sha256 = "5843ab06e7c9109326aa4eb5e26486400d6e3bce25944f6671ce989499174133";
    });
  }) // {
    package-description-override = "cabal-version:  3.0\nbuild-type:     Simple\nname:           mwc-random\nversion:        0.15.2.0\nlicense:        BSD-2-Clause\nlicense-file:   LICENSE\ncopyright:      2009, 2010, 2011 Bryan O'Sullivan\n\nauthor:         Bryan O'Sullivan <bos@serpentine.com>\nmaintainer:     Alexey Khudyakov <alexey.skladnoy@gmail.com>\nhomepage:       https://github.com/haskell/mwc-random\nbug-reports:    https://github.com/haskell/mwc-random/issues\n\ncategory:       Math, Statistics\nsynopsis:       Fast, high quality pseudo random number generation\ndescription:\n  This package contains code for generating high quality random\n  numbers that follow either a uniform or normal distribution.  The\n  generated numbers are suitable for use in statistical applications.\n  .\n  The uniform PRNG uses Marsaglia's MWC256 (also known as MWC8222)\n  multiply-with-carry generator, which has a period of 2^8222 and\n  fares well in tests of randomness.  It is also extremely fast,\n  between 2 and 3 times faster than the Mersenne Twister.\n  .\n  Compared to the mersenne-random package, this package has a more\n  convenient API, is faster, and supports more statistical\n  distributions.\n\n\nextra-source-files:\n  README.md\n\nextra-doc-files:\n  docs/*.svg\n  changelog.md\n\ntested-with:\n  GHC ==8.0.2\n   || ==8.2.2\n   || ==8.4.4\n   || ==8.6.5\n   || ==8.8.4\n   || ==8.10.7\n   || ==9.0.2\n   || ==9.2.8\n   || ==9.4.8\n   || ==9.6.6\n   || ==9.8.4\n   || ==9.10.1\n   || ==9.12.1\n\n\nsource-repository head\n  type:     git\n  location: git://github.com/haskell/mwc-random\n\nflag BenchPAPI\n  Description: Enable building of benchmarks which use instruction counters.\n               It requires libpapi and only works on Linux so it's protected by flag\n  Default: False\n  Manual:  True\n\nlibrary\n  default-language: Haskell2010\n  exposed-modules: System.Random.MWC\n                   System.Random.MWC.Distributions\n                   System.Random.MWC.CondensedTable\n                   System.Random.MWC.SeedSource\n  build-depends: base           >= 4.9 && < 5\n               , primitive      >= 0.6.2\n               , random         >= 1.2\n               , time\n               , vector         >= 0.7\n               , math-functions >= 0.2.1.0\n\n  ghc-options: -O2 -Wall -funbox-strict-fields -fwarn-tabs\n\n\n-- We want to be able to build benchmarks using both tasty-bench and tasty-papi.\n-- They have similar API so we just create two shim modules which reexport\n-- definitions from corresponding library and pick one in cabal file.\ncommon bench-stanza\n  ghc-options:      -Wall\n  default-language: Haskell2010\n  build-depends: base < 5\n               , vector          >= 0.11\n               , mersenne-random\n               , mwc-random\n               , random\n               , tasty           >=1.3.1\n\nbenchmark mwc-bench\n  import:         bench-stanza\n  type:           exitcode-stdio-1.0\n  hs-source-dirs: bench bench-time\n  main-is:        Benchmark.hs\n  Other-modules:  Bench\n  build-depends:  tasty-bench >= 0.3\n\nbenchmark mwc-bench-papi\n  import:         bench-stanza\n  type:           exitcode-stdio-1.0\n  if impl(ghcjs) || !flag(BenchPAPI) || impl(ghc < 8.2)\n     buildable: False\n  hs-source-dirs: bench bench-papi\n  main-is:        Benchmark.hs\n  Other-modules:  Bench\n  build-depends:  tasty-papi >= 0.1.2\n\ntest-suite mwc-prop-tests\n  type:           exitcode-stdio-1.0\n  hs-source-dirs: tests\n  main-is:        props.hs\n  default-language: Haskell2010\n  ghc-options:\n    -Wall -threaded -rtsopts\n\n  build-depends: base\n               , mwc-random\n               , QuickCheck                 >=2.2\n               , vector                     >=0.12.1\n               , tasty                      >=1.3.1\n               , tasty-quickcheck           >=0.10.2\n               , tasty-hunit\n               , random                     >=1.2\n               , mtl\n               , math-functions             >=0.3.4\n\ntest-suite mwc-doctests\n  type:             exitcode-stdio-1.0\n  main-is:          doctests.hs\n  hs-source-dirs:   tests\n  default-language: Haskell2010\n  if impl(ghcjs) || impl(ghc < 8.0)\n    Buildable: False\n  -- Linker on macos prints warnings to console which confuses doctests.\n  -- We simply disable doctests on ma for older GHC\n  -- > warning: -single_module is obsolete\n  if os(darwin) && impl(ghc < 9.6)\n    buildable: False\n  build-depends:\n            base       -any\n          , mwc-random -any\n          , doctest    >=0.15 && <0.24\n            --\n          , bytestring\n          , primitive\n          , vector     >=0.11\n          , random     >=1.2\n";
  }