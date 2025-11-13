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
      identifier = { name = "hasql"; version = "1.9.3.2"; };
      license = "MIT";
      copyright = "(c) 2014, Nikita Volkov";
      maintainer = "Nikita Volkov <nikita.y.volkov@mail.ru>";
      author = "Nikita Volkov <nikita.y.volkov@mail.ru>";
      homepage = "https://github.com/nikita-volkov/hasql";
      url = "";
      synopsis = "Fast PostgreSQL driver with a flexible mapping API";
      description = "Root of the \\\"hasql\\\" ecosystem.\nThis library provides connection management, execution of queries and mapping of parameters and results.\nExtended functionality such as pooling, transactions and compile-time checking is provided by extension libraries.\nFor more details and tutorials see <https://github.com/nikita-volkov/hasql the readme>.\n\nThe API comes free from all kinds of exceptions.\nAll error-reporting is explicit and is presented using the 'Either' type.\n\n\\\"hasql\\\" requires you to have the \"\\libpq\\\" C-library installed to compile.\nStarting from version 1.7 of \\\"hasql\\\" it requires \\\"libpq\\\" of at least version 14.\n\\\"libpq\\\" comes distributed with PostgreSQL,\nso typically all you need is just to install the latest PostgreSQL distro.\n\nDespite the mentioned requirements for \\\"libpq\\\" \\\"hasql\\\" is compatible\nwith a wide range of PostgreSQL servers with tests having been conducted starting from\nversion 8.3.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."aeson" or (errorHandler.buildDepError "aeson"))
          (hsPkgs."attoparsec" or (errorHandler.buildDepError "attoparsec"))
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          (hsPkgs."bytestring-strict-builder" or (errorHandler.buildDepError "bytestring-strict-builder"))
          (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
          (hsPkgs."contravariant" or (errorHandler.buildDepError "contravariant"))
          (hsPkgs."dlist" or (errorHandler.buildDepError "dlist"))
          (hsPkgs."hashable" or (errorHandler.buildDepError "hashable"))
          (hsPkgs."iproute" or (errorHandler.buildDepError "iproute"))
          (hsPkgs."mtl" or (errorHandler.buildDepError "mtl"))
          (hsPkgs."postgresql-binary" or (errorHandler.buildDepError "postgresql-binary"))
          (hsPkgs."postgresql-libpq" or (errorHandler.buildDepError "postgresql-libpq"))
          (hsPkgs."profunctors" or (errorHandler.buildDepError "profunctors"))
          (hsPkgs."scientific" or (errorHandler.buildDepError "scientific"))
          (hsPkgs."text" or (errorHandler.buildDepError "text"))
          (hsPkgs."text-builder" or (errorHandler.buildDepError "text-builder"))
          (hsPkgs."time" or (errorHandler.buildDepError "time"))
          (hsPkgs."transformers" or (errorHandler.buildDepError "transformers"))
          (hsPkgs."unordered-containers" or (errorHandler.buildDepError "unordered-containers"))
          (hsPkgs."uuid" or (errorHandler.buildDepError "uuid"))
          (hsPkgs."vector" or (errorHandler.buildDepError "vector"))
          (hsPkgs."witherable" or (errorHandler.buildDepError "witherable"))
        ];
        buildable = true;
      };
      sublibs = {
        "testing-kit" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."hasql" or (errorHandler.buildDepError "hasql"))
            (hsPkgs."testcontainers-postgresql" or (errorHandler.buildDepError "testcontainers-postgresql"))
            (hsPkgs."transformers" or (errorHandler.buildDepError "transformers"))
            (hsPkgs."uuid" or (errorHandler.buildDepError "uuid"))
          ];
          buildable = true;
        };
      };
      tests = {
        "profiling" = {
          depends = [
            (hsPkgs."hasql" or (errorHandler.buildDepError "hasql"))
            (hsPkgs."hasql".components.sublibs.testing-kit or (errorHandler.buildDepError "hasql:testing-kit"))
            (hsPkgs."rerebase" or (errorHandler.buildDepError "rerebase"))
          ];
          buildable = true;
        };
        "hspec" = {
          depends = [
            (hsPkgs."QuickCheck" or (errorHandler.buildDepError "QuickCheck"))
            (hsPkgs."contravariant-extras" or (errorHandler.buildDepError "contravariant-extras"))
            (hsPkgs."hasql" or (errorHandler.buildDepError "hasql"))
            (hsPkgs."hasql".components.sublibs.testing-kit or (errorHandler.buildDepError "hasql:testing-kit"))
            (hsPkgs."hspec" or (errorHandler.buildDepError "hspec"))
            (hsPkgs."quickcheck-instances" or (errorHandler.buildDepError "quickcheck-instances"))
            (hsPkgs."rerebase" or (errorHandler.buildDepError "rerebase"))
            (hsPkgs."testcontainers-postgresql" or (errorHandler.buildDepError "testcontainers-postgresql"))
          ];
          build-tools = [
            (hsPkgs.pkgsBuildBuild.hspec-discover.components.exes.hspec-discover or (pkgs.pkgsBuildBuild.hspec-discover or (errorHandler.buildToolDepError "hspec-discover:hspec-discover")))
          ];
          buildable = true;
        };
      };
      benchmarks = {
        "benchmarks" = {
          depends = [
            (hsPkgs."criterion" or (errorHandler.buildDepError "criterion"))
            (hsPkgs."hasql" or (errorHandler.buildDepError "hasql"))
            (hsPkgs."rerebase" or (errorHandler.buildDepError "rerebase"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/hasql-1.9.3.2.tar.gz";
      sha256 = "8e29e6b6ff98df3d2c23854ed989369855be35beda7c7343e033e3f41f5751e1";
    });
  }) // {
    package-description-override = "cabal-version: 3.0\nname: hasql\nversion: 1.9.3.2\ncategory: Hasql, Database, PostgreSQL\nsynopsis: Fast PostgreSQL driver with a flexible mapping API\ndescription:\n  Root of the \\\"hasql\\\" ecosystem.\n  This library provides connection management, execution of queries and mapping of parameters and results.\n  Extended functionality such as pooling, transactions and compile-time checking is provided by extension libraries.\n  For more details and tutorials see <https://github.com/nikita-volkov/hasql the readme>.\n\n  The API comes free from all kinds of exceptions.\n  All error-reporting is explicit and is presented using the 'Either' type.\n\n  \\\"hasql\\\" requires you to have the \"\\libpq\\\" C-library installed to compile.\n  Starting from version 1.7 of \\\"hasql\\\" it requires \\\"libpq\\\" of at least version 14.\n  \\\"libpq\\\" comes distributed with PostgreSQL,\n  so typically all you need is just to install the latest PostgreSQL distro.\n\n  Despite the mentioned requirements for \\\"libpq\\\" \\\"hasql\\\" is compatible\n  with a wide range of PostgreSQL servers with tests having been conducted starting from\n  version 8.3.\n\nhomepage: https://github.com/nikita-volkov/hasql\nbug-reports: https://github.com/nikita-volkov/hasql/issues\nauthor: Nikita Volkov <nikita.y.volkov@mail.ru>\nmaintainer: Nikita Volkov <nikita.y.volkov@mail.ru>\ncopyright: (c) 2014, Nikita Volkov\nlicense: MIT\nlicense-file: LICENSE\nextra-source-files:\n  CHANGELOG.md\n  README.md\n\nsource-repository head\n  type: git\n  location: https://github.com/nikita-volkov/hasql\n\ncommon base\n  default-language: Haskell2010\n  default-extensions:\n    ApplicativeDo\n    Arrows\n    BangPatterns\n    BlockArguments\n    ConstraintKinds\n    DataKinds\n    DefaultSignatures\n    DeriveFoldable\n    DeriveFunctor\n    DeriveGeneric\n    DeriveTraversable\n    DerivingVia\n    EmptyDataDecls\n    FlexibleContexts\n    FlexibleInstances\n    FunctionalDependencies\n    GADTs\n    GeneralizedNewtypeDeriving\n    ImportQualifiedPost\n    LambdaCase\n    LiberalTypeSynonyms\n    MultiParamTypeClasses\n    MultiWayIf\n    NamedFieldPuns\n    NoImplicitPrelude\n    NoMonomorphismRestriction\n    OverloadedStrings\n    PatternGuards\n    QuasiQuotes\n    RankNTypes\n    RecordWildCards\n    RoleAnnotations\n    ScopedTypeVariables\n    StandaloneDeriving\n    StrictData\n    TupleSections\n    TypeApplications\n    TypeFamilies\n    TypeOperators\n\ncommon executable\n  import: base\n  ghc-options:\n    -O2\n    -threaded\n    -with-rtsopts=-N\n    -rtsopts\n    -funbox-strict-fields\n\ncommon test\n  import: base\n  ghc-options:\n    -threaded\n    -with-rtsopts=-N\n\nlibrary\n  import: base\n  hs-source-dirs: library\n  exposed-modules:\n    Hasql.Connection\n    Hasql.Connection.Setting\n    Hasql.Connection.Setting.Connection\n    Hasql.Connection.Setting.Connection.Param\n    Hasql.Decoders\n    Hasql.Encoders\n    Hasql.Pipeline\n    Hasql.Session\n    Hasql.Statement\n\n  other-modules:\n    Hasql.Commands\n    Hasql.Connection.Config\n    Hasql.Connection.Config.ConnectionString\n    Hasql.Connection.Config.ConnectionString.Params\n    Hasql.Connection.Core\n    Hasql.Decoders.All\n    Hasql.Decoders.Array\n    Hasql.Decoders.Composite\n    Hasql.Decoders.Result\n    Hasql.Decoders.Results\n    Hasql.Decoders.Row\n    Hasql.Decoders.Value\n    Hasql.Encoders.All\n    Hasql.Encoders.Array\n    Hasql.Encoders.Params\n    Hasql.Encoders.Value\n    Hasql.Errors\n    Hasql.IO\n    Hasql.LibPq14\n    Hasql.LibPq14.Ffi\n    Hasql.LibPq14.Mappings\n    Hasql.Pipeline.Core\n    Hasql.PostgresTypeInfo\n    Hasql.Prelude\n    Hasql.PreparedStatementRegistry\n    Hasql.PreparedStatementRegistry.Map\n    Hasql.Session.Core\n\n  build-depends:\n    aeson >=2 && <3,\n    attoparsec >=0.10 && <0.15,\n    base >=4.14 && <5,\n    bytestring >=0.10 && <0.13,\n    bytestring-strict-builder >=0.4.5.1 && <0.5,\n    containers >=0.6 && <0.9,\n    contravariant >=1.3 && <2,\n    dlist >=0.8 && <0.9 || >=1 && <2,\n    hashable >=1.2 && <2,\n    iproute >=1.7 && <1.8,\n    mtl >=2 && <3,\n    postgresql-binary >=0.14.2 && <0.15,\n    postgresql-libpq >=0.10.1 && <0.12,\n    profunctors >=5.1 && <6,\n    scientific >=0.3 && <0.4,\n    text >=1 && <3,\n    text-builder >=1 && <1.1,\n    time >=1.9 && <2,\n    transformers >=0.6 && <0.7,\n    unordered-containers >=0.2 && <0.3,\n    uuid >=1.3 && <2,\n    vector >=0.10 && <0.14,\n    witherable >=0.5 && <0.6,\n\nlibrary testing-kit\n  import: base\n  visibility: private\n  hs-source-dirs: testing-kit\n  exposed-modules:\n    Hasql.TestingKit.Constants\n    Hasql.TestingKit.Preludes.Base\n    Hasql.TestingKit.Statements.BrokenSyntax\n    Hasql.TestingKit.Statements.GenerateSeries\n    Hasql.TestingKit.Statements.WrongDecoder\n    Hasql.TestingKit.Testcontainers\n    Hasql.TestingKit.TestingDsl\n\n  build-depends:\n    base,\n    bytestring,\n    hasql,\n    testcontainers-postgresql >=0.0.1 && <0.1,\n    transformers,\n    uuid,\n\nbenchmark benchmarks\n  import: executable\n  type: exitcode-stdio-1.0\n  hs-source-dirs: benchmarks\n  main-is: Main.hs\n  build-depends:\n    criterion >=1.6 && <2,\n    hasql,\n    rerebase <2,\n\ntest-suite profiling\n  import: base\n  type: exitcode-stdio-1.0\n  hs-source-dirs: profiling\n  main-is: Main.hs\n  ghc-options:\n    -O2\n    -threaded\n    -rtsopts\n\n  build-depends:\n    hasql,\n    hasql:testing-kit,\n    rerebase >=1 && <2,\n\ntest-suite hspec\n  import: test\n  type: exitcode-stdio-1.0\n  hs-source-dirs: hspec\n  main-is: Main.hs\n  other-modules:\n    Hasql.ConcurrencySpec\n    Hasql.ConnectionSpec\n    Hasql.EncodingDecodingSpec\n    Hasql.MiscSpec\n    Hasql.PipelineSpec\n    Hasql.SessionSpec\n    Hasql.StatementSpec\n\n  build-tool-depends: hspec-discover:hspec-discover\n  build-depends:\n    QuickCheck,\n    contravariant-extras >=0.3.5.2 && <0.4,\n    hasql,\n    hasql:testing-kit,\n    hspec,\n    quickcheck-instances >=0.3.11 && <0.4,\n    rerebase >=1 && <2,\n    testcontainers-postgresql >=0.0.1 && <0.1,\n";
  }