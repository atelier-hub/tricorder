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
      identifier = { name = "testcontainers-postgresql"; version = "0.0.4"; };
      license = "MIT";
      copyright = "(c) 2025, Nikita Volkov";
      maintainer = "Nikita Volkov <nikita.y.volkov@mail.ru>";
      author = "Nikita Volkov <nikita.y.volkov@mail.ru>";
      homepage = "https://github.com/nikita-volkov/testcontainers-postgresql";
      url = "";
      synopsis = "Testcontainers integration for PostgreSQL";
      description = "";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."testcontainers" or (errorHandler.buildDepError "testcontainers"))
          (hsPkgs."text" or (errorHandler.buildDepError "text"))
        ];
        buildable = true;
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/testcontainers-postgresql-0.0.4.tar.gz";
      sha256 = "5b817f32412ff22edd4351a0f34c18a1d20be970a2a6f46e03b6eb390f37ea26";
    });
  }) // {
    package-description-override = "cabal-version: 3.0\nname: testcontainers-postgresql\nversion: 0.0.4\ncategory: PostgreSQL, Codecs\nsynopsis: Testcontainers integration for PostgreSQL\nhomepage: https://github.com/nikita-volkov/testcontainers-postgresql\nbug-reports: https://github.com/nikita-volkov/testcontainers-postgresql/issues\nauthor: Nikita Volkov <nikita.y.volkov@mail.ru>\nmaintainer: Nikita Volkov <nikita.y.volkov@mail.ru>\ncopyright: (c) 2025, Nikita Volkov\nlicense: MIT\nlicense-file: LICENSE\nextra-doc-files:\n  LICENSE\n  README.md\n\nsource-repository head\n  type: git\n  location: https://github.com/nikita-volkov/testcontainers-postgresql\n\ncommon base\n  default-language: Haskell2010\n  default-extensions:\n    ApplicativeDo\n    BangPatterns\n    BinaryLiterals\n    BlockArguments\n    ConstraintKinds\n    DataKinds\n    DefaultSignatures\n    DeriveDataTypeable\n    DeriveFoldable\n    DeriveFunctor\n    DeriveTraversable\n    DerivingStrategies\n    DerivingVia\n    DuplicateRecordFields\n    EmptyDataDecls\n    FlexibleContexts\n    FlexibleInstances\n    FunctionalDependencies\n    GADTs\n    GeneralizedNewtypeDeriving\n    LambdaCase\n    LiberalTypeSynonyms\n    MagicHash\n    MultiParamTypeClasses\n    MultiWayIf\n    NamedFieldPuns\n    NoImplicitPrelude\n    NoMonomorphismRestriction\n    NumericUnderscores\n    OverloadedStrings\n    ParallelListComp\n    PatternGuards\n    QuasiQuotes\n    RankNTypes\n    RecordWildCards\n    ScopedTypeVariables\n    StandaloneDeriving\n    StrictData\n    TemplateHaskell\n    TupleSections\n    TypeApplications\n    TypeFamilies\n    TypeOperators\n    UnboxedTuples\n    ViewPatterns\n\ncommon executable\n  import: base\n  ghc-options:\n    -O2\n    -threaded\n    -with-rtsopts=-N\n    -rtsopts\n    -funbox-strict-fields\n\ncommon test\n  import: base\n  ghc-options:\n    -threaded\n    -with-rtsopts=-N\n\nlibrary\n  import: base\n  hs-source-dirs: src/library\n  exposed-modules:\n    TestcontainersPostgresql\n\n  other-modules:\n    TestcontainersPostgresql.Configs.Auth\n    TestcontainersPostgresql.Configs.Config\n    TestcontainersPostgresql.Configs.Distro\n\n  build-depends:\n    base >=4.11 && <5,\n    testcontainers ^>=0.5.1,\n    text >=1.2 && <3,\n";
  }