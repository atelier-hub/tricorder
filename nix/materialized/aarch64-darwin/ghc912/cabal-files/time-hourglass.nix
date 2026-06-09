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
      identifier = { name = "time-hourglass"; version = "0.3.0"; };
      license = "BSD-3-Clause";
      copyright = "Vincent Hanquez <vincent@snarc.org>";
      maintainer = "Mike Pilgrem <public@pilgrem.com>";
      author = "Vincent Hanquez <vincent@snarc.org>";
      homepage = "https://github.com/mpilgrem/time-hourglass";
      url = "";
      synopsis = "A simple and efficient time library";
      description = "A simple and efficient time library.\n\nA key part of the library is the `Timeable` and `Time` type classes.\n\nTypes representing time values that are instances of the classes allow easy\nconversion between values of one time type and another.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."deepseq" or (errorHandler.buildDepError "deepseq"))
        ] ++ pkgs.lib.optional (system.isWindows) (hsPkgs."Win32" or (errorHandler.buildDepError "Win32"));
        buildable = true;
      };
      tests = {
        "test-hourglass" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."deepseq" or (errorHandler.buildDepError "deepseq"))
            (hsPkgs."tasty" or (errorHandler.buildDepError "tasty"))
            (hsPkgs."tasty-hunit" or (errorHandler.buildDepError "tasty-hunit"))
            (hsPkgs."tasty-quickcheck" or (errorHandler.buildDepError "tasty-quickcheck"))
            (hsPkgs."time" or (errorHandler.buildDepError "time"))
            (hsPkgs."time-hourglass" or (errorHandler.buildDepError "time-hourglass"))
          ];
          buildable = true;
        };
      };
      benchmarks = {
        "bench-hourglass" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."deepseq" or (errorHandler.buildDepError "deepseq"))
            (hsPkgs."tasty-bench" or (errorHandler.buildDepError "tasty-bench"))
            (hsPkgs."time" or (errorHandler.buildDepError "time"))
            (hsPkgs."time-hourglass" or (errorHandler.buildDepError "time-hourglass"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/time-hourglass-0.3.0.tar.gz";
      sha256 = "9c7c7c74dda5033160328606cb3e8724201abadf9a140271c73c89a2612b9d22";
    });
  }) // {
    package-description-override = "cabal-version: 1.12\r\n\r\n-- This file has been generated from package.yaml by hpack version 0.38.1.\r\n--\r\n-- see: https://github.com/sol/hpack\r\n\r\nname:           time-hourglass\r\nversion:        0.3.0\r\nsynopsis:       A simple and efficient time library\r\ndescription:    A simple and efficient time library.\r\n                .\r\n                A key part of the library is the `Timeable` and `Time` type classes.\r\n                .\r\n                Types representing time values that are instances of the classes allow easy\r\n                conversion between values of one time type and another.\r\ncategory:       Time\r\nstability:      experimental\r\nhomepage:       https://github.com/mpilgrem/time-hourglass\r\nbug-reports:    https://github.com/mpilgrem/time-hourglass/issues\r\nauthor:         Vincent Hanquez <vincent@snarc.org>\r\nmaintainer:     Mike Pilgrem <public@pilgrem.com>\r\ncopyright:      Vincent Hanquez <vincent@snarc.org>\r\nlicense:        BSD3\r\nlicense-file:   LICENSE\r\nbuild-type:     Simple\r\nextra-source-files:\r\n    CHANGELOG.md\r\n    README.md\r\n    examples/Example/Time/Compat.hs\r\n    tests/TimeDB.hs\r\n\r\nsource-repository head\r\n  type: git\r\n  location: https://github.com/mpilgrem/time-hourglass\r\n\r\nlibrary\r\n  exposed-modules:\r\n      Data.Hourglass\r\n      Time.Compat\r\n      Time.Epoch\r\n      Time.System\r\n      Time.Types\r\n  other-modules:\r\n      Time.Calendar\r\n      Time.Diff\r\n      Time.Format\r\n      Time.LocalTime\r\n      Time.Time\r\n      Time.Timezone\r\n      Time.Utils\r\n  hs-source-dirs:\r\n      src\r\n  other-extensions:\r\n      DeriveDataTypeable\r\n      ExistentialQuantification\r\n      FlexibleInstances\r\n      GeneralizedNewtypeDeriving\r\n      NumericUnderscores\r\n  ghc-options: -Wall\r\n  build-depends:\r\n      base >=4.12 && <5\r\n    , deepseq\r\n  default-language: Haskell2010\r\n  if os(windows)\r\n    other-modules:\r\n        Time.Internal\r\n    hs-source-dirs:\r\n        src/win\r\n    build-depends:\r\n        Win32\r\n  else\r\n    other-modules:\r\n        Time.Internal\r\n    hs-source-dirs:\r\n        src/unix\r\n    other-extensions:\r\n        ForeignFunctionInterface\r\n    c-sources:\r\n        cbits/unix.c\r\n\r\ntest-suite test-hourglass\r\n  type: exitcode-stdio-1.0\r\n  main-is: Tests.hs\r\n  other-modules:\r\n      TimeDB\r\n      CustomTimeFormatFct\r\n  hs-source-dirs:\r\n      tests\r\n  other-extensions:\r\n      BangPatterns\r\n      FlexibleInstances\r\n      NumericUnderscores\r\n      ScopedTypeVariables\r\n  ghc-options: -Wall\r\n  build-depends:\r\n      base >=4.12 && <5\r\n    , deepseq\r\n    , tasty\r\n    , tasty-hunit\r\n    , tasty-quickcheck\r\n    , time\r\n    , time-hourglass\r\n  default-language: Haskell2010\r\n  if os(windows)\r\n    other-modules:\r\n        TimeRange\r\n    hs-source-dirs:\r\n        tests/win\r\n  else\r\n    other-modules:\r\n        TimeRange\r\n    hs-source-dirs:\r\n        tests/unix\r\n\r\nbenchmark bench-hourglass\r\n  type: exitcode-stdio-1.0\r\n  main-is: Bench.hs\r\n  hs-source-dirs:\r\n      benchmarks\r\n  other-extensions:\r\n      BangPatterns\r\n  ghc-options: -Wall\r\n  build-depends:\r\n      base >=4.12 && <5\r\n    , deepseq\r\n    , tasty-bench\r\n    , time\r\n    , time-hourglass\r\n  default-language: Haskell2010\r\n";
  }