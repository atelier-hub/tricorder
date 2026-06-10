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
      identifier = { name = "hasql-pool"; version = "1.3.0.4"; };
      license = "MIT";
      copyright = "(c) 2015, Nikita Volkov";
      maintainer = "Nikita Volkov <nikita.y.volkov@mail.ru>";
      author = "Nikita Volkov <nikita.y.volkov@mail.ru>";
      homepage = "https://github.com/nikita-volkov/hasql-pool";
      url = "";
      synopsis = "Pool of connections for Hasql";
      description = "";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          (hsPkgs."hasql" or (errorHandler.buildDepError "hasql"))
          (hsPkgs."stm" or (errorHandler.buildDepError "stm"))
          (hsPkgs."text" or (errorHandler.buildDepError "text"))
          (hsPkgs."time" or (errorHandler.buildDepError "time"))
          (hsPkgs."uuid" or (errorHandler.buildDepError "uuid"))
        ];
        buildable = true;
      };
      tests = {
        "test" = {
          depends = [
            (hsPkgs."async" or (errorHandler.buildDepError "async"))
            (hsPkgs."hasql" or (errorHandler.buildDepError "hasql"))
            (hsPkgs."hasql-pool" or (errorHandler.buildDepError "hasql-pool"))
            (hsPkgs."hspec" or (errorHandler.buildDepError "hspec"))
            (hsPkgs."random" or (errorHandler.buildDepError "random"))
            (hsPkgs."rerebase" or (errorHandler.buildDepError "rerebase"))
            (hsPkgs."testcontainers-postgresql" or (errorHandler.buildDepError "testcontainers-postgresql"))
            (hsPkgs."text-builder" or (errorHandler.buildDepError "text-builder"))
            (hsPkgs."tuple" or (errorHandler.buildDepError "tuple"))
          ];
          build-tools = [
            (hsPkgs.pkgsBuildBuild.hspec-discover.components.exes.hspec-discover or (pkgs.pkgsBuildBuild.hspec-discover or (errorHandler.buildToolDepError "hspec-discover:hspec-discover")))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/hasql-pool-1.3.0.4.tar.gz";
      sha256 = "1c3c9d3eab74aeb12e1c4899e3dab40935825daf3d2bce52d75d83a4566cf8ea";
    });
  }) // {
    package-description-override = "cabal-version: 3.0\nname: hasql-pool\nversion: 1.3.0.4\ncategory: Hasql, Database, PostgreSQL\nsynopsis: Pool of connections for Hasql\nhomepage: https://github.com/nikita-volkov/hasql-pool\nbug-reports: https://github.com/nikita-volkov/hasql-pool/issues\nauthor: Nikita Volkov <nikita.y.volkov@mail.ru>\nmaintainer: Nikita Volkov <nikita.y.volkov@mail.ru>\ncopyright: (c) 2015, Nikita Volkov\nlicense: MIT\nlicense-file: LICENSE\nextra-source-files:\n  CHANGELOG.md\n  diagrams-output/*.png\n\nextra-doc-files:\n  diagrams-output/*.png\n\nsource-repository head\n  type: git\n  location: https://github.com/nikita-volkov/hasql-pool\n\ncommon base-settings\n  default-language: Haskell2010\n  default-extensions:\n    ApplicativeDo\n    Arrows\n    BangPatterns\n    BlockArguments\n    ConstraintKinds\n    DataKinds\n    DefaultSignatures\n    DeriveDataTypeable\n    DeriveFoldable\n    DeriveFunctor\n    DeriveGeneric\n    DeriveTraversable\n    DerivingVia\n    EmptyDataDecls\n    FlexibleContexts\n    FlexibleInstances\n    FunctionalDependencies\n    GADTs\n    GeneralizedNewtypeDeriving\n    ImportQualifiedPost\n    LambdaCase\n    LiberalTypeSynonyms\n    MultiParamTypeClasses\n    MultiWayIf\n    NoImplicitPrelude\n    NoMonomorphismRestriction\n    NumericUnderscores\n    OverloadedStrings\n    PatternGuards\n    QuasiQuotes\n    RankNTypes\n    RecordWildCards\n    RoleAnnotations\n    ScopedTypeVariables\n    StandaloneDeriving\n    StrictData\n    TupleSections\n    TypeApplications\n    TypeFamilies\n    TypeOperators\n\nlibrary\n  import: base-settings\n  hs-source-dirs:\n    src/library/exposed\n    src/library/other\n\n  -- cabal-gild: discover src/library/exposed\n  exposed-modules:\n    Hasql.Pool\n    Hasql.Pool.Config\n    Hasql.Pool.Config.Defaults\n    Hasql.Pool.Observation\n\n  -- cabal-gild: discover src/library/other\n  other-modules:\n    Hasql.Pool.Config.Config\n    Hasql.Pool.Config.Setting\n    Hasql.Pool.Prelude\n    Hasql.Pool.SessionErrorDestructors\n\n  build-depends:\n    base >=4.11 && <5,\n    bytestring >=0.10 && <0.14,\n    hasql >=1.9 && <1.10,\n    stm >=2.5 && <3,\n    text >=1.2 && <3,\n    time >=1.9 && <2,\n    uuid >=1.3 && <2,\n\ntest-suite test\n  import: base-settings\n  type: exitcode-stdio-1.0\n  hs-source-dirs: src/integration-tests\n  main-is: Main.hs\n  other-modules:\n    Helpers.Hooks\n    Helpers.Scripts\n    Helpers.Sessions\n    Specs.BySubject.Config.AgingTimeoutSpec\n    Specs.BySubject.Config.IdlenessTimeoutSpec\n    Specs.BySubject.Config.InitSessionSpec\n    Specs.BySubject.Helpers.Sessions.CountConnectionsSpec\n    Specs.BySubject.Helpers.Sessions.GetSettingSpec\n    Specs.BySubject.ReleaseSpec\n    Specs.BySubject.SpecHook\n    Specs.BySubject.UsageError.AcquisitionTimeoutSpec\n    Specs.BySubject.UsageError.SessionSpec\n    Specs.BySubject.UseSpec\n\n  ghc-options: -threaded\n  build-tool-depends:\n    hspec-discover:hspec-discover ^>=2.11.12\n\n  build-depends:\n    async >=2.2 && <3,\n    hasql,\n    hasql-pool,\n    hspec >=2.6 && <3,\n    random >=1.2 && <2,\n    rerebase >=1.15 && <2,\n    testcontainers-postgresql >=0.0.2 && <0.1,\n    text-builder >=1 && <1.1,\n    tuple ^>=0.3.0.2,\n";
  }