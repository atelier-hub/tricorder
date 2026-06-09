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
      specVersion = "3.0";
      identifier = { name = "bytestring-strict-builder"; version = "0.4.5.8"; };
      license = "MIT";
      copyright = "(c) 2017, Nikita Volkov";
      maintainer = "Nikita Volkov <nikita.y.volkov@mail.ru>";
      author = "Nikita Volkov <nikita.y.volkov@mail.ru>";
      homepage = "https://github.com/nikita-volkov/bytestring-strict-builder";
      url = "";
      synopsis = "An efficient strict bytestring builder";
      description = "According to \n<https://github.com/nikita-volkov/bytestring-builders-benchmark the competition benchmarks>, \nthis library provides on average the fastest builder of strict bytestrings. \n.\nPractical benchmarks have proven it to be highly performant as well.\nThe encoders from the \\\"postgresql-binary\\\" library have shown\na stable performance improvement by factors of up to 10 after the migration\nfrom the standard builder to \\\"bytestring-strict-builder\\\".";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
        ];
        buildable = true;
      };
      tests = {
        "tests" = {
          depends = [
            (hsPkgs."bytestring-strict-builder" or (errorHandler.buildDepError "bytestring-strict-builder"))
            (hsPkgs."quickcheck-instances" or (errorHandler.buildDepError "quickcheck-instances"))
            (hsPkgs."rerebase" or (errorHandler.buildDepError "rerebase"))
            (hsPkgs."tasty" or (errorHandler.buildDepError "tasty"))
            (hsPkgs."tasty-quickcheck" or (errorHandler.buildDepError "tasty-quickcheck"))
          ];
          buildable = true;
        };
      };
      benchmarks = {
        "benchmarks" = {
          depends = [
            (hsPkgs."bytestring-strict-builder" or (errorHandler.buildDepError "bytestring-strict-builder"))
            (hsPkgs."criterion" or (errorHandler.buildDepError "criterion"))
            (hsPkgs."rerebase" or (errorHandler.buildDepError "rerebase"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/bytestring-strict-builder-0.4.5.8.tar.gz";
      sha256 = "3b9ae00a210638d7d3972247f7106e51735327081cda17f4d0c1283b1ca2dd0b";
    });
  }) // {
    package-description-override = "cabal-version: 3.0\nname:          bytestring-strict-builder\nversion:       0.4.5.8\ncategory:      Text, ByteString, Builders, Serialization\nsynopsis:      An efficient strict bytestring builder\ndescription:\n  According to \n  <https://github.com/nikita-volkov/bytestring-builders-benchmark the competition benchmarks>, \n  this library provides on average the fastest builder of strict bytestrings. \n  .\n  Practical benchmarks have proven it to be highly performant as well.\n  The encoders from the \\\"postgresql-binary\\\" library have shown\n  a stable performance improvement by factors of up to 10 after the migration\n  from the standard builder to \\\"bytestring-strict-builder\\\".\n\nhomepage:      https://github.com/nikita-volkov/bytestring-strict-builder\nbug-reports:\n  https://github.com/nikita-volkov/bytestring-strict-builder/issues\n\nauthor:        Nikita Volkov <nikita.y.volkov@mail.ru>\nmaintainer:    Nikita Volkov <nikita.y.volkov@mail.ru>\ncopyright:     (c) 2017, Nikita Volkov\nlicense:       MIT\nlicense-file:  LICENSE\n\nsource-repository head\n  type:     git\n  location: https://github.com/nikita-volkov/bytestring-strict-builder\n\ncommon base\n  default-language:   Haskell2010\n  default-extensions:\n    NoImplicitPrelude\n    NoMonomorphismRestriction\n    Arrows\n    BangPatterns\n    ConstraintKinds\n    DataKinds\n    DefaultSignatures\n    DeriveDataTypeable\n    DeriveFoldable\n    DeriveFunctor\n    DeriveGeneric\n    DeriveTraversable\n    EmptyDataDecls\n    FlexibleContexts\n    FlexibleInstances\n    FunctionalDependencies\n    GADTs\n    GeneralizedNewtypeDeriving\n    LambdaCase\n    LiberalTypeSynonyms\n    MagicHash\n    MultiParamTypeClasses\n    MultiWayIf\n    OverloadedStrings\n    ParallelListComp\n    PatternGuards\n    QuasiQuotes\n    RankNTypes\n    RecordWildCards\n    ScopedTypeVariables\n    StandaloneDeriving\n    TemplateHaskell\n    TupleSections\n    TypeFamilies\n    TypeOperators\n    UnboxedTuples\n\nlibrary\n  import:          base\n  hs-source-dirs:  library\n  exposed-modules: ByteString.StrictBuilder\n  other-modules:\n    ByteString.StrictBuilder.Population\n    ByteString.StrictBuilder.Population.UncheckedShifting\n    ByteString.StrictBuilder.Prelude\n    ByteString.StrictBuilder.UTF8\n\n  build-depends:\n    , base >=4.11 && <5\n    , bytestring >=0.10.2 && <0.13\n\ntest-suite tests\n  import:         base\n  type:           exitcode-stdio-1.0\n  hs-source-dirs: tests\n  main-is:        Main.hs\n  build-depends:\n    , bytestring-strict-builder\n    , quickcheck-instances >=0.3.11 && <0.4\n    , rerebase >=1.10 && <2\n    , tasty >=1.4 && <2\n    , tasty-quickcheck >=0.10 && <0.12\n\nbenchmark benchmarks\n  import:         base\n  type:           exitcode-stdio-1.0\n  hs-source-dirs: benchmarks\n  main-is:        Main.hs\n  ghc-options:    -O2 -threaded -with-rtsopts=-N -funbox-strict-fields\n  build-depends:\n    , bytestring-strict-builder\n    , criterion >=1.6 && <2\n    , rerebase >=1.10 && <2\n";
  }