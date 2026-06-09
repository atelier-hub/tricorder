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
      identifier = { name = "postgresql-binary"; version = "0.14.2"; };
      license = "MIT";
      copyright = "(c) 2014, Nikita Volkov";
      maintainer = "Nikita Volkov <nikita.y.volkov@mail.ru>";
      author = "Nikita Volkov <nikita.y.volkov@mail.ru>";
      homepage = "https://github.com/nikita-volkov/postgresql-binary";
      url = "";
      synopsis = "Encoders and decoders for the PostgreSQL's binary format";
      description = "An API for dealing with PostgreSQL's binary data format.\n.\nIt can be used to implement performant bindings to Postgres.\nE.g., <http://hackage.haskell.org/package/hasql hasql>\nis based on this library.\n.\nIt supports all Postgres versions starting from 8.3\nand is tested against 8.3, 9.3 and 9.5\nwith the @integer_datetimes@ setting off and on.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."aeson" or (errorHandler.buildDepError "aeson"))
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."binary-parser" or (errorHandler.buildDepError "binary-parser"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          (hsPkgs."bytestring-strict-builder" or (errorHandler.buildDepError "bytestring-strict-builder"))
          (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
          (hsPkgs."iproute" or (errorHandler.buildDepError "iproute"))
          (hsPkgs."scientific" or (errorHandler.buildDepError "scientific"))
          (hsPkgs."text" or (errorHandler.buildDepError "text"))
          (hsPkgs."time" or (errorHandler.buildDepError "time"))
          (hsPkgs."transformers" or (errorHandler.buildDepError "transformers"))
          (hsPkgs."unordered-containers" or (errorHandler.buildDepError "unordered-containers"))
          (hsPkgs."uuid" or (errorHandler.buildDepError "uuid"))
          (hsPkgs."vector" or (errorHandler.buildDepError "vector"))
        ];
        buildable = true;
      };
      tests = {
        "tasty" = {
          depends = [
            (hsPkgs."QuickCheck" or (errorHandler.buildDepError "QuickCheck"))
            (hsPkgs."aeson" or (errorHandler.buildDepError "aeson"))
            (hsPkgs."iproute" or (errorHandler.buildDepError "iproute"))
            (hsPkgs."postgresql-binary" or (errorHandler.buildDepError "postgresql-binary"))
            (hsPkgs."postgresql-libpq" or (errorHandler.buildDepError "postgresql-libpq"))
            (hsPkgs."quickcheck-instances" or (errorHandler.buildDepError "quickcheck-instances"))
            (hsPkgs."rerebase" or (errorHandler.buildDepError "rerebase"))
            (hsPkgs."tasty" or (errorHandler.buildDepError "tasty"))
            (hsPkgs."tasty-hunit" or (errorHandler.buildDepError "tasty-hunit"))
            (hsPkgs."tasty-quickcheck" or (errorHandler.buildDepError "tasty-quickcheck"))
          ];
          buildable = true;
        };
      };
      benchmarks = {
        "encoding" = {
          depends = [
            (hsPkgs."criterion" or (errorHandler.buildDepError "criterion"))
            (hsPkgs."postgresql-binary" or (errorHandler.buildDepError "postgresql-binary"))
            (hsPkgs."rerebase" or (errorHandler.buildDepError "rerebase"))
          ];
          buildable = true;
        };
        "decoding" = {
          depends = [
            (hsPkgs."criterion" or (errorHandler.buildDepError "criterion"))
            (hsPkgs."postgresql-binary" or (errorHandler.buildDepError "postgresql-binary"))
            (hsPkgs."rerebase" or (errorHandler.buildDepError "rerebase"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/postgresql-binary-0.14.2.tar.gz";
      sha256 = "e3f03ebe1f7e429520562c6a7157dbad78635d647839dff5479b6eff34014421";
    });
  }) // {
    package-description-override = "cabal-version: 3.0\nname: postgresql-binary\nversion: 0.14.2\nsynopsis: Encoders and decoders for the PostgreSQL's binary format\ndescription:\n  An API for dealing with PostgreSQL's binary data format.\n  .\n  It can be used to implement performant bindings to Postgres.\n  E.g., <http://hackage.haskell.org/package/hasql hasql>\n  is based on this library.\n  .\n  It supports all Postgres versions starting from 8.3\n  and is tested against 8.3, 9.3 and 9.5\n  with the @integer_datetimes@ setting off and on.\n\ncategory: PostgreSQL, Database, Codecs, Parsing\nhomepage: https://github.com/nikita-volkov/postgresql-binary\nbug-reports: https://github.com/nikita-volkov/postgresql-binary/issues\nauthor: Nikita Volkov <nikita.y.volkov@mail.ru>\nmaintainer: Nikita Volkov <nikita.y.volkov@mail.ru>\ncopyright: (c) 2014, Nikita Volkov\nlicense: MIT\nlicense-file: LICENSE\nextra-source-files: CHANGELOG.md\n\nsource-repository head\n  type: git\n  location: https://github.com/nikita-volkov/postgresql-binary\n\ncommon base\n  default-language: Haskell2010\n  default-extensions:\n    Arrows\n    BangPatterns\n    ConstraintKinds\n    DataKinds\n    DefaultSignatures\n    DeriveDataTypeable\n    DeriveFunctor\n    DeriveGeneric\n    EmptyDataDecls\n    FlexibleContexts\n    FlexibleInstances\n    FunctionalDependencies\n    GADTs\n    GeneralizedNewtypeDeriving\n    LambdaCase\n    LiberalTypeSynonyms\n    MagicHash\n    MultiParamTypeClasses\n    MultiWayIf\n    NoImplicitPrelude\n    NoMonomorphismRestriction\n    OverloadedStrings\n    ParallelListComp\n    PatternGuards\n    QuasiQuotes\n    RankNTypes\n    RecordWildCards\n    ScopedTypeVariables\n    StandaloneDeriving\n    TemplateHaskell\n    TupleSections\n    TypeFamilies\n    TypeOperators\n    UnboxedTuples\n\nlibrary\n  import: base\n  hs-source-dirs: library\n  ghc-options: -funbox-strict-fields\n  exposed-modules:\n    PostgreSQL.Binary.Decoding\n    PostgreSQL.Binary.Encoding\n    PostgreSQL.Binary.Range\n\n  other-modules:\n    PostgreSQL.Binary.BuilderPrim\n    PostgreSQL.Binary.Encoding.Builders\n    PostgreSQL.Binary.Inet\n    PostgreSQL.Binary.Integral\n    PostgreSQL.Binary.Interval\n    PostgreSQL.Binary.Numeric\n    PostgreSQL.Binary.Prelude\n    PostgreSQL.Binary.Time\n\n  build-depends:\n    aeson >=2 && <3,\n    base >=4.12 && <5,\n    binary-parser >=0.5.7 && <0.6,\n    bytestring >=0.10.4 && <0.13,\n    bytestring-strict-builder >=0.4.5.4 && <0.5,\n    containers >=0.5 && <0.8,\n    iproute >=1.7 && <2,\n    scientific >=0.3 && <0.4,\n    text >=1.2 && <3,\n    time >=1.9 && <2,\n    transformers >=0.3 && <0.7,\n    unordered-containers >=0.2 && <0.3,\n    uuid >=1.3 && <1.4,\n    vector >=0.12 && <0.14,\n\n-- This test-suite must be executed in a single-thread.\ntest-suite tasty\n  import: base\n  type: exitcode-stdio-1.0\n  hs-source-dirs: tasty\n  main-is: Main.hs\n  other-modules:\n    Main.Apx\n    Main.Composite\n    Main.DB\n    Main.Gens\n    Main.IO\n    Main.PTI\n    Main.Prelude\n    Main.Properties\n    Main.TextEncoder\n\n  build-depends:\n    QuickCheck >=2.10 && <3,\n    aeson >=2 && <3,\n    iproute >=1.4 && <2,\n    postgresql-binary,\n    postgresql-libpq >=0.9 && <0.12,\n    quickcheck-instances >=0.3.22 && <0.4,\n    rerebase >=1.20.1.1 && <2,\n    tasty >=1.4 && <2,\n    tasty-hunit >=0.10 && <0.11,\n    tasty-quickcheck >=0.10 && <0.12,\n\nbenchmark encoding\n  import: base\n  type: exitcode-stdio-1.0\n  hs-source-dirs: encoding\n  main-is: Main.hs\n  ghc-options:\n    -O2\n    -threaded\n    -with-rtsopts=-N\n    -funbox-strict-fields\n\n  build-depends:\n    criterion >=1.5.9 && <2,\n    postgresql-binary,\n    rerebase >=1.20.1.1 && <2,\n\nbenchmark decoding\n  import: base\n  type: exitcode-stdio-1.0\n  hs-source-dirs: decoding\n  main-is: Main.hs\n  ghc-options:\n    -O2\n    -threaded\n    -with-rtsopts=-N\n    -funbox-strict-fields\n\n  build-depends:\n    criterion >=1.5.9 && <2,\n    postgresql-binary,\n    rerebase >=1.20.1.1 && <2,\n";
  }