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
      identifier = { name = "text-builder"; version = "1.0.0.4"; };
      license = "MIT";
      copyright = "(c) 2017, Nikita Volkov";
      maintainer = "Nikita Volkov <nikita.y.volkov@mail.ru>";
      author = "Nikita Volkov <nikita.y.volkov@mail.ru>";
      homepage = "https://github.com/nikita-volkov/text-builder";
      url = "";
      synopsis = "Efficient and flexible strict text builder";
      description = "= Summary\n\nFast strict text builder and simple type-safe formatting library.\n\n== The Builder\n\nThe builder abstraction provided by this library is much faster than the standard lazy @Builder@ and even the recently introduced @StrictTextBuilder@ from \\\"text\\\". Benchmarks are distributed with the source code. You can see the results in the README file.\n\nThe abstraction constructs text in two phases. In the first one it estimates the size of the byte array and in the second one it allocates it once and populates it in one go.\n\n== Simple and type-safe formatting library\n\nThe monoidal API of the library provides a simple yet type-safe alternative to formatting strings via @printf@-like tools or more involved solutions like the popular \\\"[formatting](https://hackage.haskell.org/package/formatting)\\\" library.\n\n== Quality\n\nEvery bit of the library is heavily covered with tests with CI running tests on a variety of versions of GHC and the \\\"text\\\" library. This is crucial because the \\\"text\\\" library has made a switch from UTF-16 to UTF-8, leading to drastic changes in its low-level constructs, which builder libraries must rely on, and this library supports both versions of \\\"text\\\".\n\n= Ecosystem\n\nFollowing is a list of libraries that, alongside this one, make an integrated ecosystem:\n\n- \"[text-builder-time](https://hackage.haskell.org/package/text-builder-time)\" - formatters for the \"time\" library\n\n- \"[text-builder-core](https://hackage.haskell.org/package/text-builder-core)\" - lower-level unsafe constructs for implementing efficient formatters compatible with this library\n\n- \"[text-builder-dev](https://hackage.haskell.org/package/text-builder-dev)\" - edge of development of new features providing a richer functionality at the cost of more frequent major releases\n\n- \"[text-builder-lawful-conversions](https://hackage.haskell.org/package/text-builder-lawful-conversions)\" - integration with the \\\"lawful-conversions\\\" library, providing bidirectional conversions with various types including `String`, `Data.Text.Text`, `Data.Text.Lazy.Text`, `Data.Text.Lazy.Builder.Builder`, `Data.Text.Encoding.StrictTextBuilder`.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          (hsPkgs."text" or (errorHandler.buildDepError "text"))
          (hsPkgs."text-builder-core" or (errorHandler.buildDepError "text-builder-core"))
          (hsPkgs."time" or (errorHandler.buildDepError "time"))
          (hsPkgs."transformers" or (errorHandler.buildDepError "transformers"))
        ];
        buildable = true;
      };
      tests = {
        "test" = {
          depends = [
            (hsPkgs."QuickCheck" or (errorHandler.buildDepError "QuickCheck"))
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."quickcheck-classes" or (errorHandler.buildDepError "quickcheck-classes"))
            (hsPkgs."quickcheck-instances" or (errorHandler.buildDepError "quickcheck-instances"))
            (hsPkgs."tasty" or (errorHandler.buildDepError "tasty"))
            (hsPkgs."tasty-quickcheck" or (errorHandler.buildDepError "tasty-quickcheck"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
            (hsPkgs."text-builder" or (errorHandler.buildDepError "text-builder"))
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
            (hsPkgs."text-builder" or (errorHandler.buildDepError "text-builder"))
            (hsPkgs."text-builder-linear" or (errorHandler.buildDepError "text-builder-linear"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/text-builder-1.0.0.4.tar.gz";
      sha256 = "9323f4a824e7b951cafbc5c180402658d4fc9f95afe4a4e2e5b317f75c619be8";
    });
  }) // {
    package-description-override = "cabal-version: 3.0\nname: text-builder\nversion: 1.0.0.4\ncategory: Text, Builders\nsynopsis: Efficient and flexible strict text builder\ndescription:\n  = Summary\n\n  Fast strict text builder and simple type-safe formatting library.\n\n  == The Builder\n\n  The builder abstraction provided by this library is much faster than the standard lazy @Builder@ and even the recently introduced @StrictTextBuilder@ from \\\"text\\\". Benchmarks are distributed with the source code. You can see the results in the README file.\n\n  The abstraction constructs text in two phases. In the first one it estimates the size of the byte array and in the second one it allocates it once and populates it in one go.\n\n  == Simple and type-safe formatting library\n\n  The monoidal API of the library provides a simple yet type-safe alternative to formatting strings via @printf@-like tools or more involved solutions like the popular \\\"[formatting](https://hackage.haskell.org/package/formatting)\\\" library.\n\n  == Quality\n\n  Every bit of the library is heavily covered with tests with CI running tests on a variety of versions of GHC and the \\\"text\\\" library. This is crucial because the \\\"text\\\" library has made a switch from UTF-16 to UTF-8, leading to drastic changes in its low-level constructs, which builder libraries must rely on, and this library supports both versions of \\\"text\\\".\n\n  = Ecosystem\n\n  Following is a list of libraries that, alongside this one, make an integrated ecosystem:\n\n  - \"[text-builder-time](https://hackage.haskell.org/package/text-builder-time)\" - formatters for the \"time\" library\n\n  - \"[text-builder-core](https://hackage.haskell.org/package/text-builder-core)\" - lower-level unsafe constructs for implementing efficient formatters compatible with this library\n\n  - \"[text-builder-dev](https://hackage.haskell.org/package/text-builder-dev)\" - edge of development of new features providing a richer functionality at the cost of more frequent major releases\n\n  - \"[text-builder-lawful-conversions](https://hackage.haskell.org/package/text-builder-lawful-conversions)\" - integration with the \\\"lawful-conversions\\\" library, providing bidirectional conversions with various types including `String`, `Data.Text.Text`, `Data.Text.Lazy.Text`, `Data.Text.Lazy.Builder.Builder`, `Data.Text.Encoding.StrictTextBuilder`.\n\nhomepage: https://github.com/nikita-volkov/text-builder\nbug-reports: https://github.com/nikita-volkov/text-builder/issues\nauthor: Nikita Volkov <nikita.y.volkov@mail.ru>\nmaintainer: Nikita Volkov <nikita.y.volkov@mail.ru>\ncopyright: (c) 2017, Nikita Volkov\nlicense: MIT\nlicense-file: LICENSE\nextra-doc-files:\n  CHANGELOG.md\n  LICENSE\n  README.md\n\nsource-repository head\n  type: git\n  location: https://github.com/nikita-volkov/text-builder\n\ncommon base\n  default-language: Haskell2010\n  default-extensions:\n    BangPatterns\n    BlockArguments\n    ConstraintKinds\n    DataKinds\n    DefaultSignatures\n    DeriveDataTypeable\n    DeriveFoldable\n    DeriveFunctor\n    DeriveGeneric\n    DeriveTraversable\n    DerivingStrategies\n    EmptyDataDecls\n    FlexibleContexts\n    FlexibleInstances\n    FunctionalDependencies\n    GADTs\n    GeneralizedNewtypeDeriving\n    LambdaCase\n    LiberalTypeSynonyms\n    MagicHash\n    MultiParamTypeClasses\n    MultiWayIf\n    NoImplicitPrelude\n    NoMonomorphismRestriction\n    NumericUnderscores\n    OverloadedStrings\n    ParallelListComp\n    PatternGuards\n    QuasiQuotes\n    RankNTypes\n    RecordWildCards\n    ScopedTypeVariables\n    StandaloneDeriving\n    StrictData\n    TemplateHaskell\n    TupleSections\n    TypeApplications\n    TypeFamilies\n    TypeOperators\n    UnboxedTuples\n    ViewPatterns\n\nlibrary\n  import: base\n  hs-source-dirs: library\n  exposed-modules: TextBuilder\n  other-modules:\n    TextBuilder.Domains.ByteString\n    TextBuilder.Domains.Combinators\n    TextBuilder.Domains.Digits\n    TextBuilder.Domains.Digits.Codepoints\n    TextBuilder.Domains.Other\n    TextBuilder.Prelude\n\n  build-depends:\n    base >=4.11 && <5,\n    bytestring >=0.10 && <0.13,\n    text >=1.2 && <3,\n    text-builder-core ^>=0.1.1.1,\n    time >=1.12 && <2,\n    transformers >=0.5 && <0.7,\n\ntest-suite test\n  import: base\n  type: exitcode-stdio-1.0\n  hs-source-dirs: test\n  main-is: Main.hs\n  other-modules:\n    Util.ExtraInstances\n    Util.TestTrees\n\n  build-depends:\n    QuickCheck >=2.14 && <3,\n    base >=4.11 && <5,\n    bytestring >=0.10 && <0.13,\n    quickcheck-classes >=0.6.5 && <0.7,\n    quickcheck-instances >=0.3.32 && <0.4,\n    tasty >=1.5.3 && <2,\n    tasty-quickcheck >=0.11.1 && <0.12,\n    text >=1.2 && <3,\n    text-builder,\n\nbenchmark bench\n  import: base\n  type: exitcode-stdio-1.0\n  hs-source-dirs: bench\n  ghc-options:\n    -O2\n    -threaded\n    -with-rtsopts=-N\n    -with-rtsopts=-A32m\n    -with-rtsopts=-T\n    -fproc-alignment=64\n\n  main-is: Main.hs\n  build-depends:\n    base >=4.11 && <5,\n    tasty-bench ^>=0.4.1,\n    text >=2.1.2 && <3,\n    text-builder,\n    text-builder-linear ^>=0.1.3,\n";
  }