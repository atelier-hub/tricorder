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
      identifier = { name = "vector-builder"; version = "0.3.8.7"; };
      license = "MIT";
      copyright = "(c) 2016, Nikita Volkov";
      maintainer = "Nikita Volkov <nikita.y.volkov@mail.ru>";
      author = "Nikita Volkov <nikita.y.volkov@mail.ru>";
      homepage = "https://github.com/nikita-volkov/vector-builder";
      url = "";
      synopsis = "Vector builder";
      description = "An API for efficient and convenient construction of vectors.\nIt provides the composable `Builder` abstraction, which has instances of the `Monoid` and `Semigroup` classes.\n.\n[Usage]\n.\nFirst you use the `Builder` abstraction to specify the structure of the vector.\nThen you execute the builder to actually produce the vector.\n.\n[Example]\n.\nThe following code shows how you can efficiently concatenate different datastructures into a single immutable vector:\n.\n>\n>import qualified Data.Vector as A\n>import qualified VectorBuilder.Builder as B\n>import qualified VectorBuilder.Vector as C\n>\n>\n>myVector :: A.Vector a -> [a] -> a -> A.Vector a\n>myVector vector list element =\n>  C.build builder\n>  where\n>    builder =\n>      B.vector vector <>\n>      B.foldable list <>\n>      B.singleton element";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."vector" or (errorHandler.buildDepError "vector"))
        ];
        buildable = true;
      };
      tests = {
        "tests" = {
          depends = [
            (hsPkgs."attoparsec" or (errorHandler.buildDepError "attoparsec"))
            (hsPkgs."quickcheck-instances" or (errorHandler.buildDepError "quickcheck-instances"))
            (hsPkgs."rerebase" or (errorHandler.buildDepError "rerebase"))
            (hsPkgs."tasty" or (errorHandler.buildDepError "tasty"))
            (hsPkgs."tasty-hunit" or (errorHandler.buildDepError "tasty-hunit"))
            (hsPkgs."tasty-quickcheck" or (errorHandler.buildDepError "tasty-quickcheck"))
            (hsPkgs."vector-builder" or (errorHandler.buildDepError "vector-builder"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/vector-builder-0.3.8.7.tar.gz";
      sha256 = "b1ca331c87885b1fd168f4ab49a8590f9a36779513af8d8fdbeaf824265bcb51";
    });
  }) // {
    package-description-override = "cabal-version: 3.0\nname:          vector-builder\nversion:       0.3.8.7\nsynopsis:      Vector builder\ndescription:\n  An API for efficient and convenient construction of vectors.\n  It provides the composable `Builder` abstraction, which has instances of the `Monoid` and `Semigroup` classes.\n  .\n  [Usage]\n  .\n  First you use the `Builder` abstraction to specify the structure of the vector.\n  Then you execute the builder to actually produce the vector.\n  .\n  [Example]\n  .\n  The following code shows how you can efficiently concatenate different datastructures into a single immutable vector:\n  .\n  >\n  >import qualified Data.Vector as A\n  >import qualified VectorBuilder.Builder as B\n  >import qualified VectorBuilder.Vector as C\n  >\n  >\n  >myVector :: A.Vector a -> [a] -> a -> A.Vector a\n  >myVector vector list element =\n  >  C.build builder\n  >  where\n  >    builder =\n  >      B.vector vector <>\n  >      B.foldable list <>\n  >      B.singleton element\n\ncategory:      Vector\nhomepage:      https://github.com/nikita-volkov/vector-builder\nbug-reports:   https://github.com/nikita-volkov/vector-builder/issues\nauthor:        Nikita Volkov <nikita.y.volkov@mail.ru>\nmaintainer:    Nikita Volkov <nikita.y.volkov@mail.ru>\ncopyright:     (c) 2016, Nikita Volkov\nlicense:       MIT\nlicense-file:  LICENSE\n\nsource-repository head\n  type:     git\n  location: https://github.com/nikita-volkov/vector-builder\n\nlibrary\n  hs-source-dirs:     library\n  default-extensions:\n    NoImplicitPrelude\n    NoMonomorphismRestriction\n    Arrows\n    BangPatterns\n    ConstraintKinds\n    DataKinds\n    DefaultSignatures\n    DeriveDataTypeable\n    DeriveFoldable\n    DeriveFunctor\n    DeriveGeneric\n    DeriveTraversable\n    EmptyDataDecls\n    FlexibleContexts\n    FlexibleInstances\n    FunctionalDependencies\n    GADTs\n    GeneralizedNewtypeDeriving\n    LambdaCase\n    LiberalTypeSynonyms\n    MagicHash\n    MultiParamTypeClasses\n    MultiWayIf\n    OverloadedStrings\n    ParallelListComp\n    PatternGuards\n    QuasiQuotes\n    RankNTypes\n    RecordWildCards\n    ScopedTypeVariables\n    StandaloneDeriving\n    TemplateHaskell\n    TupleSections\n    TypeFamilies\n    TypeOperators\n    UnboxedTuples\n\n  default-language:   Haskell2010\n  exposed-modules:\n    VectorBuilder.Alternative\n    VectorBuilder.Builder\n    VectorBuilder.MonadPlus\n    VectorBuilder.MVector\n    VectorBuilder.Vector\n\n  other-modules:\n    VectorBuilder.Core.Builder\n    VectorBuilder.Core.Update\n    VectorBuilder.Prelude\n\n  build-depends:\n    , base >=4.10 && <5\n    , vector >=0.12 && <0.14\n\ntest-suite tests\n  type:               exitcode-stdio-1.0\n  hs-source-dirs:     tests\n  main-is:            Main.hs\n  other-modules:      Main.Sample\n  default-extensions:\n    NoImplicitPrelude\n    NoMonomorphismRestriction\n    Arrows\n    BangPatterns\n    ConstraintKinds\n    DataKinds\n    DefaultSignatures\n    DeriveDataTypeable\n    DeriveFoldable\n    DeriveFunctor\n    DeriveGeneric\n    DeriveTraversable\n    EmptyDataDecls\n    FlexibleContexts\n    FlexibleInstances\n    FunctionalDependencies\n    GADTs\n    GeneralizedNewtypeDeriving\n    LambdaCase\n    LiberalTypeSynonyms\n    MagicHash\n    MultiParamTypeClasses\n    MultiWayIf\n    OverloadedStrings\n    ParallelListComp\n    PatternGuards\n    QuasiQuotes\n    RankNTypes\n    RecordWildCards\n    ScopedTypeVariables\n    StandaloneDeriving\n    TemplateHaskell\n    TupleSections\n    TypeFamilies\n    TypeOperators\n    UnboxedTuples\n\n  default-language:   Haskell2010\n  build-depends:\n    , attoparsec >=0.13 && <0.15\n    , quickcheck-instances >=0.3.11 && <0.5\n    , rerebase <2\n    , tasty >=0.12 && <2\n    , tasty-hunit >=0.9 && <0.11\n    , tasty-quickcheck >=0.9 && <0.12\n    , vector-builder\n";
  }