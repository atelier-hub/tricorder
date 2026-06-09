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
    package-description-override = "cabal-version:      2.2\r\nname:               os-string\r\nversion:            2.0.10\r\nx-revision:         1\r\n\r\n-- NOTE: Don't forget to update ./changelog.md\r\nlicense:            BSD-3-Clause\r\nlicense-file:       LICENSE\r\nauthor:             Julian Ospald <hasufell@posteo.de>\r\nmaintainer:         Julian Ospald <hasufell@posteo.de>\r\ncopyright:          Julian Ospald 2021-2023\r\nbug-reports:        https://github.com/haskell/os-string/issues\r\nhomepage:\r\n  https://github.com/haskell/os-string/blob/master/README.md\r\n\r\ncategory:           System\r\nbuild-type:         Simple\r\nsynopsis:           Library for manipulating Operating system strings.\r\ntested-with:\r\n  GHC ==8.6.5\r\n   || ==8.8.4\r\n   || ==8.10.7\r\n   || ==9.0.2\r\n   || ==9.2.8\r\n   || ==9.4.8\r\n   || ==9.6.3\r\n   || ==9.8.1\r\n\r\ndescription:\r\n  This package provides functionality for manipulating @OsString@ values, and is shipped with <https://www.haskell.org/ghc/ GHC>.\r\n\r\nextra-source-files:\r\n  System/OsString/Common.hs\r\n  tests/bytestring-tests/Properties/Common.hs\r\n  bench/Common.hs\r\n\r\nextra-doc-files:\r\n  changelog.md\r\n  README.md\r\n\r\nsource-repository head\r\n  type:     git\r\n  location: https://github.com/haskell/os-string\r\n\r\nlibrary\r\n  exposed-modules:\r\n    System.OsString.Data.ByteString.Short\r\n    System.OsString.Data.ByteString.Short.Internal\r\n    System.OsString.Data.ByteString.Short.Word16\r\n    System.OsString.Encoding\r\n    System.OsString.Encoding.Internal\r\n    System.OsString\r\n    System.OsString.Internal\r\n    System.OsString.Internal.Exception\r\n    System.OsString.Internal.Types\r\n    System.OsString.Posix\r\n    System.OsString.Windows\r\n\r\n  other-extensions:\r\n    CPP\r\n    PatternGuards\r\n\r\n  if impl(ghc >=7.2)\r\n    other-extensions: Safe\r\n\r\n  default-language: Haskell2010\r\n  build-depends:\r\n    , base              >=4.12.0.0      && <4.23\r\n    , bytestring        >=0.11.3.0\r\n    , deepseq\r\n    , exceptions\r\n  -- template-haskell-lift was added as a boot library in GHC-9.14\r\n  -- once we no longer wish to backport releases to older major releases of GHC,\r\n  -- this conditional can be dropped\r\n  if impl(ghc < 9.14)\r\n      build-depends: template-haskell\r\n  elif impl(ghc)\r\n      build-depends:\r\n        , template-haskell-lift >=0.1 && <0.2\r\n        , template-haskell-quasiquoter >=0.1 && <0.2\r\n\r\n  ghc-options:      -Wall\r\n\r\ntest-suite bytestring-tests\r\n  default-language: Haskell2010\r\n  ghc-options:      -Wall\r\n  type:             exitcode-stdio-1.0\r\n  main-is:          Main.hs\r\n  hs-source-dirs:   tests tests/bytestring-tests\r\n  other-modules:\r\n    Properties.ShortByteString\r\n    Properties.WindowsString\r\n    Properties.PosixString\r\n    Properties.OsString\r\n    Properties.ShortByteString.Word16\r\n    TestUtil\r\n\r\n  build-depends:\r\n    , base\r\n    , bytestring  >=0.11.3.0\r\n    , os-string\r\n    , QuickCheck  >=2.7      && <2.19\r\n\r\ntest-suite encoding-tests\r\n  default-language: Haskell2010\r\n  ghc-options:      -Wall\r\n  type:             exitcode-stdio-1.0\r\n  main-is:          Main.hs\r\n  hs-source-dirs:   tests tests/encoding\r\n  other-modules:\r\n    Arbitrary\r\n    EncodingSpec\r\n    TestUtil\r\n\r\n  build-depends:\r\n    , base\r\n    , bytestring  >=0.11.3.0\r\n    , deepseq\r\n    , os-string\r\n    , QuickCheck  >=2.7      && <2.19\r\n    , quickcheck-classes-base ^>=0.6.2\r\n\r\nbenchmark bench\r\n  main-is:          Bench.hs\r\n  other-modules:    BenchOsString\r\n                    BenchPosixString\r\n                    BenchWindowsString\r\n  type:             exitcode-stdio-1.0\r\n  hs-source-dirs:   bench\r\n  default-language: Haskell2010\r\n  ghc-options:      -O2 \"-with-rtsopts=-A32m\"\r\n  if impl(ghc >= 8.6)\r\n    ghc-options:    -fproc-alignment=64\r\n  build-depends:    base,\r\n                    bytestring,\r\n                    os-string,\r\n                    deepseq,\r\n                    tasty-bench,\r\n                    random\r\n";
  }