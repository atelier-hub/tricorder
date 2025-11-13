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
      identifier = { name = "hasql-transaction"; version = "1.2.1"; };
      license = "MIT";
      copyright = "(c) 2015, Nikita Volkov";
      maintainer = "Nikita Volkov <nikita.y.volkov@mail.ru>";
      author = "Nikita Volkov <nikita.y.volkov@mail.ru>";
      homepage = "https://github.com/nikita-volkov/hasql-transaction";
      url = "";
      synopsis = "Composable abstraction over retryable transactions for Hasql";
      description = "";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          (hsPkgs."bytestring-tree-builder" or (errorHandler.buildDepError "bytestring-tree-builder"))
          (hsPkgs."contravariant" or (errorHandler.buildDepError "contravariant"))
          (hsPkgs."hasql" or (errorHandler.buildDepError "hasql"))
          (hsPkgs."mtl" or (errorHandler.buildDepError "mtl"))
          (hsPkgs."transformers" or (errorHandler.buildDepError "transformers"))
        ];
        buildable = true;
      };
      tests = {
        "conflicts-test" = {
          depends = [
            (hsPkgs."async" or (errorHandler.buildDepError "async"))
            (hsPkgs."hasql" or (errorHandler.buildDepError "hasql"))
            (hsPkgs."hasql-transaction" or (errorHandler.buildDepError "hasql-transaction"))
            (hsPkgs."rerebase" or (errorHandler.buildDepError "rerebase"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/hasql-transaction-1.2.1.tar.gz";
      sha256 = "74dcf830c53bd0d0a488ba565a8054d940643395a02e26bdd94c5628d2037357";
    });
  }) // {
    package-description-override = "cabal-version: 3.0\nname: hasql-transaction\nversion: 1.2.1\ncategory: Hasql, Database, PostgreSQL\nsynopsis:\n  Composable abstraction over retryable transactions for Hasql\n\nhomepage: https://github.com/nikita-volkov/hasql-transaction\nbug-reports: https://github.com/nikita-volkov/hasql-transaction/issues\nauthor: Nikita Volkov <nikita.y.volkov@mail.ru>\nmaintainer: Nikita Volkov <nikita.y.volkov@mail.ru>\ncopyright: (c) 2015, Nikita Volkov\nlicense: MIT\nlicense-file: LICENSE\nextra-source-files: CHANGELOG.md\ntested-with: ghc ==9.8.2 || ==8.10.1\n\nsource-repository head\n  type: git\n  location: git://github.com/nikita-volkov/hasql-transaction.git\n\ncommon base\n  default-language: Haskell2010\n  default-extensions:\n    ApplicativeDo\n    BangPatterns\n    BlockArguments\n    ConstraintKinds\n    DataKinds\n    DefaultSignatures\n    DeriveDataTypeable\n    DeriveFoldable\n    DeriveFunctor\n    DeriveGeneric\n    DeriveTraversable\n    DerivingVia\n    EmptyDataDecls\n    FlexibleContexts\n    FlexibleInstances\n    FunctionalDependencies\n    GADTs\n    GeneralizedNewtypeDeriving\n    ImportQualifiedPost\n    LambdaCase\n    LiberalTypeSynonyms\n    MultiParamTypeClasses\n    MultiWayIf\n    NoImplicitPrelude\n    NoMonomorphismRestriction\n    OverloadedStrings\n    PatternGuards\n    QuasiQuotes\n    RankNTypes\n    RecordWildCards\n    RoleAnnotations\n    ScopedTypeVariables\n    StandaloneDeriving\n    StrictData\n    TupleSections\n    TypeFamilies\n    TypeOperators\n\ncommon executable\n  import: base\n  ghc-options:\n    -O2\n    -threaded\n    -with-rtsopts=-N\n    -rtsopts\n    -funbox-strict-fields\n\ncommon test\n  import: base\n  ghc-options:\n    -threaded\n    -with-rtsopts=-N\n\nlibrary\n  import: base\n  hs-source-dirs: library\n  exposed-modules:\n    Hasql.Transaction\n    Hasql.Transaction.Sessions\n\n  other-modules:\n    Hasql.Transaction.Config\n    Hasql.Transaction.Private.Prelude\n    Hasql.Transaction.Private.SQL\n    Hasql.Transaction.Private.Sessions\n    Hasql.Transaction.Private.Statements\n    Hasql.Transaction.Private.Transaction\n\n  build-depends:\n    base >=4.12 && <5,\n    bytestring >=0.10 && <0.13,\n    bytestring-tree-builder >=0.2.7.8 && <0.3,\n    contravariant >=1.3 && <2,\n    hasql >=1.9 && <1.10,\n    mtl >=2.2 && <3,\n    transformers >=0.5 && <0.7,\n\ntest-suite conflicts-test\n  import: test\n  type: exitcode-stdio-1.0\n  hs-source-dirs: conflicts-test\n  main-is: Main.hs\n  other-modules:\n    Main.Statements\n    Main.Transactions\n\n  ghc-options:\n    -O2\n    -threaded\n    -with-rtsopts=-N\n\n  build-depends:\n    async >=2.1 && <3,\n    hasql >=1.9,\n    hasql-transaction,\n    rerebase >=1.11 && <2,\n";
  }