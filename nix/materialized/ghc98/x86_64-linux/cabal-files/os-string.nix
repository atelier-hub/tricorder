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
      specVersion = "2.2";
      identifier = { name = "os-string"; version = "2.0.10"; };
      license = "BSD-3-Clause";
      copyright = "Julian Ospald 2021-2023";
      maintainer = "Julian Ospald <hasufell@posteo.de>";
      author = "Julian Ospald <hasufell@posteo.de>";
      homepage = "https://github.com/haskell/os-string/blob/master/README.md";
      url = "";
      synopsis = "Library for manipulating Operating system strings.";
      description = "This package provides functionality for manipulating @OsString@ values, and is shipped with <https://www.haskell.org/ghc/ GHC>.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          (hsPkgs."deepseq" or (errorHandler.buildDepError "deepseq"))
          (hsPkgs."exceptions" or (errorHandler.buildDepError "exceptions"))
        ] ++ (if compiler.isGhc && compiler.version.lt "9.14"
          then [
            (hsPkgs."template-haskell" or (errorHandler.buildDepError "template-haskell"))
          ]
          else pkgs.lib.optionals (compiler.isGhc && true) [
            (hsPkgs."template-haskell-lift" or (errorHandler.buildDepError "template-haskell-lift"))
            (hsPkgs."template-haskell-quasiquoter" or (errorHandler.buildDepError "template-haskell-quasiquoter"))
          ]);
        buildable = true;
      };
      tests = {
        "bytestring-tests" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."os-string" or (errorHandler.buildDepError "os-string"))
            (hsPkgs."QuickCheck" or (errorHandler.buildDepError "QuickCheck"))
          ];
          buildable = true;
        };
        "encoding-tests" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."deepseq" or (errorHandler.buildDepError "deepseq"))
            (hsPkgs."os-string" or (errorHandler.buildDepError "os-string"))
            (hsPkgs."QuickCheck" or (errorHandler.buildDepError "QuickCheck"))
            (hsPkgs."quickcheck-classes-base" or (errorHandler.buildDepError "quickcheck-classes-base"))
          ];
          buildable = true;
        };
      };
      benchmarks = {
        "bench" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."os-string" or (errorHandler.buildDepError "os-string"))
            (hsPkgs."deepseq" or (errorHandler.buildDepError "deepseq"))
            (hsPkgs."tasty-bench" or (errorHandler.buildDepError "tasty-bench"))
            (hsPkgs."random" or (errorHandler.buildDepError "random"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/os-string-2.0.10.tar.gz";
      sha256 = "f682b8a6121a09fc820ce69d99e33bfa9b1a959505663ef2fedebe7b95c75aa5";
    });
  }) // {
    package-description-override = "cabal-version:      2.2\nname:               os-string\nversion:            2.0.10\n\n-- NOTE: Don't forget to update ./changelog.md\nlicense:            BSD-3-Clause\nlicense-file:       LICENSE\nauthor:             Julian Ospald <hasufell@posteo.de>\nmaintainer:         Julian Ospald <hasufell@posteo.de>\ncopyright:          Julian Ospald 2021-2023\nbug-reports:        https://github.com/haskell/os-string/issues\nhomepage:\n  https://github.com/haskell/os-string/blob/master/README.md\n\ncategory:           System\nbuild-type:         Simple\nsynopsis:           Library for manipulating Operating system strings.\ntested-with:\n  GHC ==8.6.5\n   || ==8.8.4\n   || ==8.10.7\n   || ==9.0.2\n   || ==9.2.8\n   || ==9.4.8\n   || ==9.6.3\n   || ==9.8.1\n\ndescription:\n  This package provides functionality for manipulating @OsString@ values, and is shipped with <https://www.haskell.org/ghc/ GHC>.\n\nextra-source-files:\n  System/OsString/Common.hs\n  tests/bytestring-tests/Properties/Common.hs\n  bench/Common.hs\n\nextra-doc-files:\n  changelog.md\n  README.md\n\nsource-repository head\n  type:     git\n  location: https://github.com/haskell/os-string\n\nlibrary\n  exposed-modules:\n    System.OsString.Data.ByteString.Short\n    System.OsString.Data.ByteString.Short.Internal\n    System.OsString.Data.ByteString.Short.Word16\n    System.OsString.Encoding\n    System.OsString.Encoding.Internal\n    System.OsString\n    System.OsString.Internal\n    System.OsString.Internal.Exception\n    System.OsString.Internal.Types\n    System.OsString.Posix\n    System.OsString.Windows\n\n  other-extensions:\n    CPP\n    PatternGuards\n\n  if impl(ghc >=7.2)\n    other-extensions: Safe\n\n  default-language: Haskell2010\n  build-depends:\n    , base              >=4.12.0.0      && <4.23\n    , bytestring        >=0.11.3.0\n    , deepseq\n    , exceptions\n  -- template-haskell-lift was added as a boot library in GHC-9.14\n  -- once we no longer wish to backport releases to older major releases of GHC,\n  -- this conditional can be dropped\n  if impl(ghc < 9.14)\n      build-depends: template-haskell\n  elif impl(ghc)\n      build-depends:\n        , template-haskell-lift >=0.1 && <0.2\n        , template-haskell-quasiquoter >=0.1 && <0.2\n\n  ghc-options:      -Wall\n\ntest-suite bytestring-tests\n  default-language: Haskell2010\n  ghc-options:      -Wall\n  type:             exitcode-stdio-1.0\n  main-is:          Main.hs\n  hs-source-dirs:   tests tests/bytestring-tests\n  other-modules:\n    Properties.ShortByteString\n    Properties.WindowsString\n    Properties.PosixString\n    Properties.OsString\n    Properties.ShortByteString.Word16\n    TestUtil\n\n  build-depends:\n    , base\n    , bytestring  >=0.11.3.0\n    , os-string\n    , QuickCheck  >=2.7      && <2.16\n\ntest-suite encoding-tests\n  default-language: Haskell2010\n  ghc-options:      -Wall\n  type:             exitcode-stdio-1.0\n  main-is:          Main.hs\n  hs-source-dirs:   tests tests/encoding\n  other-modules:\n    Arbitrary\n    EncodingSpec\n    TestUtil\n\n  build-depends:\n    , base\n    , bytestring  >=0.11.3.0\n    , deepseq\n    , os-string\n    , QuickCheck  >=2.7      && <2.16\n    , quickcheck-classes-base ^>=0.6.2\n\nbenchmark bench\n  main-is:          Bench.hs\n  other-modules:    BenchOsString\n                    BenchPosixString\n                    BenchWindowsString\n  type:             exitcode-stdio-1.0\n  hs-source-dirs:   bench\n  default-language: Haskell2010\n  ghc-options:      -O2 \"-with-rtsopts=-A32m\"\n  if impl(ghc >= 8.6)\n    ghc-options:    -fproc-alignment=64\n  build-depends:    base,\n                    bytestring,\n                    os-string,\n                    deepseq,\n                    tasty-bench,\n                    random\n";
  }