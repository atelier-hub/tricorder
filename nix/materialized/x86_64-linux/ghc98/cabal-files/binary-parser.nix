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
      identifier = { name = "binary-parser"; version = "0.5.7.7"; };
      license = "MIT";
      copyright = "(c) 2015, Nikita Volkov";
      maintainer = "Nikita Volkov <nikita.y.volkov@mail.ru>";
      author = "Nikita Volkov <nikita.y.volkov@mail.ru>";
      homepage = "https://github.com/nikita-volkov/binary-parser";
      url = "";
      synopsis = "An efficient but limited parser API specialised to bytestrings";
      description = "";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          (hsPkgs."mtl" or (errorHandler.buildDepError "mtl"))
          (hsPkgs."text" or (errorHandler.buildDepError "text"))
          (hsPkgs."transformers" or (errorHandler.buildDepError "transformers"))
        ];
        buildable = true;
      };
      tests = {
        "tests" = {
          depends = [
            (hsPkgs."base-prelude" or (errorHandler.buildDepError "base-prelude"))
            (hsPkgs."binary-parser" or (errorHandler.buildDepError "binary-parser"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."tasty" or (errorHandler.buildDepError "tasty"))
            (hsPkgs."tasty-hunit" or (errorHandler.buildDepError "tasty-hunit"))
            (hsPkgs."tasty-quickcheck" or (errorHandler.buildDepError "tasty-quickcheck"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/binary-parser-0.5.7.7.tar.gz";
      sha256 = "59d3007f0cc5db875de9468bcd05850a9ce893a229cfe50c4a2f4383ca72d27b";
    });
  }) // {
    package-description-override = "cabal-version: 3.0\nname:          binary-parser\nversion:       0.5.7.7\nsynopsis:\n  An efficient but limited parser API specialised to bytestrings\n\ncategory:      Parser, Binary\nhomepage:      https://github.com/nikita-volkov/binary-parser\nbug-reports:   https://github.com/nikita-volkov/binary-parser/issues\nauthor:        Nikita Volkov <nikita.y.volkov@mail.ru>\nmaintainer:    Nikita Volkov <nikita.y.volkov@mail.ru>\ncopyright:     (c) 2015, Nikita Volkov\nlicense:       MIT\nlicense-file:  LICENSE\n\nsource-repository head\n  type:     git\n  location: git://github.com/nikita-volkov/binary-parser.git\n\ncommon base\n  default-language:   Haskell2010\n  default-extensions:\n    NoImplicitPrelude\n    NoMonomorphismRestriction\n    Arrows\n    BangPatterns\n    ConstraintKinds\n    DataKinds\n    DefaultSignatures\n    DeriveDataTypeable\n    DeriveFoldable\n    DeriveFunctor\n    DeriveGeneric\n    DeriveTraversable\n    DerivingVia\n    EmptyDataDecls\n    FlexibleContexts\n    FlexibleInstances\n    FunctionalDependencies\n    GADTs\n    GeneralizedNewtypeDeriving\n    LambdaCase\n    LiberalTypeSynonyms\n    MagicHash\n    MultiParamTypeClasses\n    MultiWayIf\n    OverloadedStrings\n    ParallelListComp\n    PatternGuards\n    QuasiQuotes\n    RankNTypes\n    RecordWildCards\n    RoleAnnotations\n    ScopedTypeVariables\n    StandaloneDeriving\n    TemplateHaskell\n    TupleSections\n    TypeFamilies\n    TypeOperators\n    UnboxedTuples\n\nlibrary\n  import:          base\n  hs-source-dirs:  library\n  other-modules:   BinaryParser.Prelude\n  exposed-modules: BinaryParser\n  build-depends:\n    , base >=4.12 && <5\n    , bytestring >=0.10 && <0.13\n    , mtl >=2 && <3\n    , text >=1 && <3\n    , transformers >=0.4 && <0.8\n\ntest-suite tests\n  import:         base\n  type:           exitcode-stdio-1.0\n  hs-source-dirs: tests\n  main-is:        Main.hs\n  build-depends:\n    , base-prelude >=1.6 && <2\n    , binary-parser\n    , bytestring >=0.10 && <0.13\n    , tasty >=1.2.3 && <2\n    , tasty-hunit ^>=0.10\n    , tasty-quickcheck >=0.10 && <0.12\n";
  }