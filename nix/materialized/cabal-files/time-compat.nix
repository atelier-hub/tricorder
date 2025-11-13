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
      identifier = { name = "time-compat"; version = "1.9.8"; };
      license = "BSD-3-Clause";
      copyright = "";
      maintainer = "Oleg Grenrus <oleg.grenrus@iki.fi>";
      author = "Ashley Yakeley";
      homepage = "https://github.com/haskellari/time-compat";
      url = "";
      synopsis = "Compatibility package for time";
      description = "This packages tries to compat as much of @time@ features as possible.\n\n/TODO:/\n\n* Difference type @ParseTime@ and @FormatTime@ instances are missing.\n\n* Formatting varies depending on underlying @time@ version\n\n* @dayFractionToTimeOfDay@ on extreme values";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."base-orphans" or (errorHandler.buildDepError "base-orphans"))
          (hsPkgs."deepseq" or (errorHandler.buildDepError "deepseq"))
          (hsPkgs."hashable" or (errorHandler.buildDepError "hashable"))
          (hsPkgs."template-haskell" or (errorHandler.buildDepError "template-haskell"))
          (hsPkgs."time" or (errorHandler.buildDepError "time"))
        ];
        buildable = true;
      };
      tests = {
        "instances" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."deepseq" or (errorHandler.buildDepError "deepseq"))
            (hsPkgs."hashable" or (errorHandler.buildDepError "hashable"))
            (hsPkgs."HUnit" or (errorHandler.buildDepError "HUnit"))
            (hsPkgs."template-haskell" or (errorHandler.buildDepError "template-haskell"))
            (hsPkgs."time-compat" or (errorHandler.buildDepError "time-compat"))
          ];
          buildable = true;
        };
        "main" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."deepseq" or (errorHandler.buildDepError "deepseq"))
            (hsPkgs."QuickCheck" or (errorHandler.buildDepError "QuickCheck"))
            (hsPkgs."random" or (errorHandler.buildDepError "random"))
            (hsPkgs."tagged" or (errorHandler.buildDepError "tagged"))
            (hsPkgs."tasty" or (errorHandler.buildDepError "tasty"))
            (hsPkgs."tasty-hunit" or (errorHandler.buildDepError "tasty-hunit"))
            (hsPkgs."tasty-quickcheck" or (errorHandler.buildDepError "tasty-quickcheck"))
            (hsPkgs."template-haskell" or (errorHandler.buildDepError "template-haskell"))
            (hsPkgs."time-compat" or (errorHandler.buildDepError "time-compat"))
            (hsPkgs."time" or (errorHandler.buildDepError "time"))
          ] ++ pkgs.lib.optionals (!(compiler.isGhc && compiler.version.ge "8.0")) [
            (hsPkgs."fail" or (errorHandler.buildDepError "fail"))
            (hsPkgs."semigroups" or (errorHandler.buildDepError "semigroups"))
          ];
          buildable = if !(compiler.isGhc && compiler.version.ge "7.4")
            then false
            else true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/time-compat-1.9.8.tar.gz";
      sha256 = "502ef8694a5b131b47c0e5df2e9053d005a3b345b30f5225af04f081d3ef5cf0";
    });
  }) // {
    package-description-override = "cabal-version:      1.12\nname:               time-compat\nversion:            1.9.8\nsynopsis:           Compatibility package for time\ndescription:\n  This packages tries to compat as much of @time@ features as possible.\n  .\n  /TODO:/\n  .\n  * Difference type @ParseTime@ and @FormatTime@ instances are missing.\n  .\n  * Formatting varies depending on underlying @time@ version\n  .\n  * @dayFractionToTimeOfDay@ on extreme values\n\ncategory:           Time, Compatibility\nlicense:            BSD3\nlicense-file:       LICENSE\nmaintainer:         Oleg Grenrus <oleg.grenrus@iki.fi>\nauthor:             Ashley Yakeley\nhomepage:           https://github.com/haskellari/time-compat\nbug-reports:        https://github.com/haskellari/time-compat/issues\nbuild-type:         Simple\nextra-source-files: CHANGELOG.md\ntested-with:\n  GHC ==8.6.5\n   || ==8.8.4\n   || ==8.10.7\n   || ==9.0.2\n   || ==9.2.8\n   || ==9.4.8\n   || ==9.6.6\n   || ==9.8.4\n   || ==9.10.1\n   || ==9.12.1\n\nsource-repository head\n  type:     git\n  location: https://github.com/haskellari/time-compat.git\n\nlibrary\n  default-language:   Haskell2010\n  hs-source-dirs:     src\n  other-extensions:   CPP\n  default-extensions: Trustworthy\n  build-depends:\n      base              >=4.12    && <4.22\n    , base-orphans      >=0.9.2   && <0.10\n    , deepseq           >=1.4.4.0 && <1.6\n    , hashable          >=1.4.4.0 && <1.6\n    , template-haskell\n    , time              >=1.8.0.2 && <1.9  || >=1.9.2 && <1.9.4 || >=1.10 && <1.10.1 || >=1.11 && <1.11.2 || >=1.12 && <1.13 || >=1.14 && <1.15\n\n  default-extensions:\n    BangPatterns\n    DeriveDataTypeable\n    DeriveGeneric\n    DeriveLift\n    PatternSynonyms\n    StandaloneDeriving\n    ViewPatterns\n\n  exposed-modules:\n    Data.Time.Calendar.Compat\n    Data.Time.Calendar.Easter.Compat\n    Data.Time.Calendar.Julian.Compat\n    Data.Time.Calendar.Month.Compat\n    Data.Time.Calendar.MonthDay.Compat\n    Data.Time.Calendar.OrdinalDate.Compat\n    Data.Time.Calendar.Quarter.Compat\n    Data.Time.Calendar.WeekDate.Compat\n    Data.Time.Clock.Compat\n    Data.Time.Clock.POSIX.Compat\n    Data.Time.Clock.System.Compat\n    Data.Time.Clock.TAI.Compat\n    Data.Time.Compat\n    Data.Time.Format.Compat\n    Data.Time.Format.ISO8601.Compat\n    Data.Time.LocalTime.Compat\n\n  other-modules:\n    Data.Format\n    Data.Time.Calendar.Private\n    Data.Time.Calendar.Types\n    Data.Time.Orphans\n\ntest-suite instances\n  default-language: Haskell2010\n  type:             exitcode-stdio-1.0\n  hs-source-dirs:   test-instances\n  main-is:          Test.hs\n  build-depends:\n      base\n    , deepseq\n    , hashable          >=1.4.0.0 && <1.6\n    , HUnit             >=1.3.1   && <1.3.2 || >=1.6.0.0 && <1.7\n    , template-haskell\n    , time-compat\n\n-- This test-suite is from time library\n-- Changes:\n-- * imports: Data.Time -> Data.Time.Compat etc\n-- * disabled Test.Format.ParseTime\n-- * Test.Format.Format has also trees disabled\n-- * Test.Format.Compile doesn't work\n-- * disabled 'TimeOfDay minBound 0 0' (Test.LocalTime.Time)\n--\ntest-suite main\n  if !impl(ghc >=7.4)\n    buildable: False\n\n  default-language:   Haskell2010\n  type:               exitcode-stdio-1.0\n  hs-source-dirs:     test/main\n  default-extensions:\n    CPP\n    DeriveDataTypeable\n    DerivingStrategies\n    ExistentialQuantification\n    FlexibleInstances\n    GeneralizedNewtypeDeriving\n    MultiParamTypeClasses\n    Rank2Types\n    RecordWildCards\n    ScopedTypeVariables\n    StandaloneDeriving\n    TupleSections\n    TypeApplications\n    UndecidableInstances\n\n  ghc-options:        -Wall -fwarn-tabs\n  build-depends:\n      base\n    , deepseq\n    , QuickCheck        >=2.15.0.1 && <2.16\n    , random            >=1.2.1.3  && <1.3\n    , tagged            >=0.8.9    && <0.9\n    , tasty             >=1.5      && <1.6\n    , tasty-hunit       >=0.10     && <0.11\n    , tasty-quickcheck  >=0.11     && <0.12\n    , template-haskell\n    , time-compat\n\n  if !impl(ghc >=8.0)\n    build-depends:\n        fail        >=4.9.0.0 && <4.10\n      , semigroups  >=0.18.5  && <0.21\n\n  build-depends:      time\n  main-is:            Main.hs\n  other-modules:\n    Test.Arbitrary\n    Test.Calendar.AddDays\n    Test.Calendar.AddDaysRef\n    Test.Calendar.CalendarProps\n    Test.Calendar.Calendars\n    Test.Calendar.CalendarsRef\n    Test.Calendar.ClipDates\n    Test.Calendar.ClipDatesRef\n    Test.Calendar.ConvertBack\n    Test.Calendar.DayPeriod\n    Test.Calendar.Duration\n    Test.Calendar.Easter\n    Test.Calendar.EasterRef\n    Test.Calendar.LongWeekYears\n    Test.Calendar.LongWeekYearsRef\n    Test.Calendar.MonthDay\n    Test.Calendar.MonthDayRef\n    Test.Calendar.MonthOfYear\n    Test.Calendar.Valid\n    Test.Calendar.Week\n    Test.Calendar.Year\n    Test.Clock.Conversion\n    Test.Clock.Lift\n    Test.Clock.Resolution\n    Test.Clock.TAI\n    Test.Format.Compile\n    Test.Format.Format\n    Test.Format.ISO8601\n    Test.Format.ParseTime\n    Test.LocalTime.CalendarDiffTime\n    Test.LocalTime.Time\n    Test.LocalTime.TimeOfDay\n    Test.LocalTime.TimeRef\n    Test.TestUtil\n    Test.Types\n";
  }