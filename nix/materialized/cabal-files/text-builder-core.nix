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
      identifier = { name = "text-builder-core"; version = "0.1.1.1"; };
      license = "MIT";
      copyright = "(c) 2022, Nikita Volkov";
      maintainer = "Nikita Volkov <nikita.y.volkov@mail.ru>";
      author = "Nikita Volkov <nikita.y.volkov@mail.ru>";
      homepage = "https://github.com/nikita-volkov/text-builder-core";
      url = "";
      synopsis = "Internals of \"text-builder\"";
      description = "Core functionality of \\\"text-builder\\\" with guts exposed for efficient custom integrations.\n\nConsider this to be what you'll find in the \\\"Internal\\\" modules of packages violating PVP. You'll find more on this in [a blog post](https://nikita-volkov.github.io/internal-convention-is-a-mistake/).";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."QuickCheck" or (errorHandler.buildDepError "QuickCheck"))
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."text" or (errorHandler.buildDepError "text"))
        ];
        buildable = true;
      };
      tests = {
        "test" = {
          depends = [
            (hsPkgs."QuickCheck" or (errorHandler.buildDepError "QuickCheck"))
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."quickcheck-classes" or (errorHandler.buildDepError "quickcheck-classes"))
            (hsPkgs."quickcheck-instances" or (errorHandler.buildDepError "quickcheck-instances"))
            (hsPkgs."tasty" or (errorHandler.buildDepError "tasty"))
            (hsPkgs."tasty-quickcheck" or (errorHandler.buildDepError "tasty-quickcheck"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
            (hsPkgs."text-builder-core" or (errorHandler.buildDepError "text-builder-core"))
          ];
          buildable = true;
        };
      };
      benchmarks = {
        "bench" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."tasty-bench" or (errorHandler.buildDepError "tasty-bench"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
            (hsPkgs."text-builder-core" or (errorHandler.buildDepError "text-builder-core"))
            (hsPkgs."text-builder-linear" or (errorHandler.buildDepError "text-builder-linear"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/text-builder-core-0.1.1.1.tar.gz";
      sha256 = "a9a30930dc59f8bd2b243991df7c6a8dcf2f65353c0df1b0fed8c1ba1f2d7d86";
    });
  }) // {
    package-description-override = "cabal-version: 3.0\nname: text-builder-core\nversion: 0.1.1.1\ncategory: Text, Builders\nsynopsis: Internals of \"text-builder\"\ndescription:\n  Core functionality of \\\"text-builder\\\" with guts exposed for efficient custom integrations.\n\n  Consider this to be what you'll find in the \\\"Internal\\\" modules of packages violating PVP. You'll find more on this in [a blog post](https://nikita-volkov.github.io/internal-convention-is-a-mistake/).\n\nhomepage: https://github.com/nikita-volkov/text-builder-core\nbug-reports: https://github.com/nikita-volkov/text-builder-core/issues\nauthor: Nikita Volkov <nikita.y.volkov@mail.ru>\nmaintainer: Nikita Volkov <nikita.y.volkov@mail.ru>\ncopyright: (c) 2022, Nikita Volkov\nlicense: MIT\nlicense-file: LICENSE\n\nsource-repository head\n  type: git\n  location: https://github.com/nikita-volkov/text-builder-core\n\ncommon base\n  default-language: Haskell2010\n  default-extensions:\n    BangPatterns\n    BlockArguments\n    ConstraintKinds\n    DataKinds\n    DefaultSignatures\n    DeriveDataTypeable\n    DeriveFoldable\n    DeriveFunctor\n    DeriveGeneric\n    DeriveTraversable\n    DerivingStrategies\n    EmptyDataDecls\n    FlexibleContexts\n    FlexibleInstances\n    FunctionalDependencies\n    GADTs\n    GeneralizedNewtypeDeriving\n    LambdaCase\n    LiberalTypeSynonyms\n    MagicHash\n    MultiParamTypeClasses\n    MultiWayIf\n    NoImplicitPrelude\n    NoMonomorphismRestriction\n    NumericUnderscores\n    OverloadedStrings\n    ParallelListComp\n    PatternGuards\n    QuasiQuotes\n    RankNTypes\n    RecordWildCards\n    ScopedTypeVariables\n    StandaloneDeriving\n    StrictData\n    TemplateHaskell\n    TupleSections\n    TypeApplications\n    TypeFamilies\n    TypeOperators\n    UnboxedTuples\n    ViewPatterns\n\nlibrary\n  import: base\n  hs-source-dirs: library\n  exposed-modules: TextBuilderCore\n  other-modules:\n    TextBuilderCore.Prelude\n    TextBuilderCore.Utf16View\n    TextBuilderCore.Utf16View.Unicode\n    TextBuilderCore.Utf8View\n\n  build-depends:\n    QuickCheck >=2.14 && <3,\n    base >=4.11 && <5,\n    text >=1.2 && <3,\n\ntest-suite test\n  import: base\n  type: exitcode-stdio-1.0\n  hs-source-dirs: test\n  main-is: Main.hs\n  other-modules:\n    Features\n    Util.ExtraInstances\n    Util.TestTrees\n\n  build-depends:\n    QuickCheck >=2.14 && <3,\n    base >=4.11 && <5,\n    quickcheck-classes >=0.6.5 && <0.7,\n    quickcheck-instances >=0.3.32 && <0.4,\n    tasty >=1.2.3 && <2,\n    tasty-quickcheck ^>=0.11,\n    text >=1.2 && <3,\n    text-builder-core,\n\nbenchmark bench\n  import: base\n  type: exitcode-stdio-1.0\n  hs-source-dirs: bench\n  ghc-options:\n    -O2\n    -threaded\n    -with-rtsopts=-N\n    -with-rtsopts=-A32m\n    -with-rtsopts=-T\n    -fproc-alignment=64\n\n  main-is: Main.hs\n  build-depends:\n    base >=4.11 && <5,\n    tasty-bench ^>=0.4.1,\n    text >=2.1.2 && <3,\n    text-builder-core,\n    text-builder-linear ^>=0.1.3,\n";
  }