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
      identifier = { name = "bytestring-tree-builder"; version = "0.2.7.13"; };
      license = "MIT";
      copyright = "(c) 2015, Nikita Volkov";
      maintainer = "Nikita Volkov <nikita.y.volkov@mail.ru>";
      author = "Nikita Volkov <nikita.y.volkov@mail.ru>";
      homepage = "https://github.com/nikita-volkov/bytestring-tree-builder";
      url = "";
      synopsis = "A very efficient ByteString builder implementation based on the binary tree";
      description = "According to\n<https://github.com/nikita-volkov/bytestring-builders-benchmark the benchmarks>\nthis builder implementation beats all the alternatives.\nIt is especially well-suited for generating strict bytestrings,\nbeating the standard builder by at least the factor of 4.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          (hsPkgs."text" or (errorHandler.buildDepError "text"))
        ];
        buildable = true;
      };
      tests = {
        "tasty" = {
          depends = [
            (hsPkgs."base-prelude" or (errorHandler.buildDepError "base-prelude"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."bytestring-tree-builder" or (errorHandler.buildDepError "bytestring-tree-builder"))
            (hsPkgs."quickcheck-instances" or (errorHandler.buildDepError "quickcheck-instances"))
            (hsPkgs."tasty" or (errorHandler.buildDepError "tasty"))
            (hsPkgs."tasty-hunit" or (errorHandler.buildDepError "tasty-hunit"))
            (hsPkgs."tasty-quickcheck" or (errorHandler.buildDepError "tasty-quickcheck"))
          ];
          buildable = true;
        };
      };
      benchmarks = {
        "benchmark" = {
          depends = [
            (hsPkgs."base-prelude" or (errorHandler.buildDepError "base-prelude"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."bytestring-tree-builder" or (errorHandler.buildDepError "bytestring-tree-builder"))
            (hsPkgs."criterion" or (errorHandler.buildDepError "criterion"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/bytestring-tree-builder-0.2.7.13.tar.gz";
      sha256 = "8f7e532e617393dfb2c285e0311317345ba108fc014b31c618f4279046fa6768";
    });
  }) // {
    package-description-override = "cabal-version: 3.0\nname:          bytestring-tree-builder\nversion:       0.2.7.13\ncategory:      ByteString\nsynopsis:\n  A very efficient ByteString builder implementation based on the binary tree\n\ndescription:\n  According to\n  <https://github.com/nikita-volkov/bytestring-builders-benchmark the benchmarks>\n  this builder implementation beats all the alternatives.\n  It is especially well-suited for generating strict bytestrings,\n  beating the standard builder by at least the factor of 4.\n\nhomepage:      https://github.com/nikita-volkov/bytestring-tree-builder\nbug-reports:\n  https://github.com/nikita-volkov/bytestring-tree-builder/issues\n\nauthor:        Nikita Volkov <nikita.y.volkov@mail.ru>\nmaintainer:    Nikita Volkov <nikita.y.volkov@mail.ru>\ncopyright:     (c) 2015, Nikita Volkov\nlicense:       MIT\nlicense-file:  LICENSE\n\nsource-repository head\n  type:     git\n  location: https://github.com/nikita-volkov/bytestring-tree-builder\n\ncommon base\n  default-language:   Haskell2010\n  default-extensions:\n    NoImplicitPrelude\n    NoMonomorphismRestriction\n    Arrows\n    BangPatterns\n    ConstraintKinds\n    DataKinds\n    DefaultSignatures\n    DeriveDataTypeable\n    DeriveFoldable\n    DeriveFunctor\n    DeriveGeneric\n    DeriveTraversable\n    EmptyDataDecls\n    FlexibleContexts\n    FlexibleInstances\n    FunctionalDependencies\n    GADTs\n    GeneralizedNewtypeDeriving\n    LambdaCase\n    LiberalTypeSynonyms\n    MagicHash\n    MultiParamTypeClasses\n    MultiWayIf\n    OverloadedStrings\n    ParallelListComp\n    PatternGuards\n    QuasiQuotes\n    RankNTypes\n    RecordWildCards\n    ScopedTypeVariables\n    StandaloneDeriving\n    TemplateHaskell\n    TupleSections\n    TypeFamilies\n    TypeOperators\n    UnboxedTuples\n\nlibrary\n  import:          base\n  hs-source-dirs:  library\n  other-modules:\n    ByteString.TreeBuilder.Poker\n    ByteString.TreeBuilder.Prelude\n    ByteString.TreeBuilder.Tree\n\n  exposed-modules: ByteString.TreeBuilder\n  build-depends:\n    , base >=4.13 && <5\n    , bytestring >=0.10 && <0.13\n    , text >=1 && <3\n\nbenchmark benchmark\n  import:         base\n  type:           exitcode-stdio-1.0\n  hs-source-dirs: benchmark\n  main-is:        Main.hs\n  ghc-options:    -O2 -threaded -with-rtsopts=-N -funbox-strict-fields\n  build-depends:\n    , base-prelude\n    , bytestring\n    , bytestring-tree-builder\n    , criterion >=1.1 && <2\n\ntest-suite tasty\n  import:         base\n  type:           exitcode-stdio-1.0\n  hs-source-dirs: tasty\n  main-is:        Main.hs\n  build-depends:\n    , base-prelude\n    , bytestring\n    , bytestring-tree-builder\n    , quickcheck-instances >=0.3.25 && <0.4\n    , tasty >=1.4 && <2\n    , tasty-hunit >=0.10 && <0.11\n    , tasty-quickcheck >=0.10 && <0.12\n";
  }