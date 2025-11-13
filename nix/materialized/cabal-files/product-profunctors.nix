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
      specVersion = "1.18";
      identifier = { name = "product-profunctors"; version = "0.11.1.1"; };
      license = "BSD-3-Clause";
      copyright = "Copyright (c) 2013, Karamaan Group LLC; 2014-2018 Purely Agile Limited; 2019-2023 Tom Ellis";
      maintainer = "Purely Agile";
      author = "Purely Agile";
      homepage = "https://github.com/tomjaguarpaw/product-profunctors";
      url = "";
      synopsis = "product-profunctors";
      description = "Product profunctors and tools for working with them";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."profunctors" or (errorHandler.buildDepError "profunctors"))
          (hsPkgs."bifunctors" or (errorHandler.buildDepError "bifunctors"))
          (hsPkgs."contravariant" or (errorHandler.buildDepError "contravariant"))
          (hsPkgs."tagged" or (errorHandler.buildDepError "tagged"))
          (hsPkgs."template-haskell" or (errorHandler.buildDepError "template-haskell"))
          (hsPkgs."th-abstraction" or (errorHandler.buildDepError "th-abstraction"))
        ] ++ pkgs.lib.optional (compiler.isGhc && compiler.version.lt "7.10") (hsPkgs."transformers" or (errorHandler.buildDepError "transformers"));
        buildable = true;
      };
      tests = {
        "test" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."profunctors" or (errorHandler.buildDepError "profunctors"))
            (hsPkgs."product-profunctors" or (errorHandler.buildDepError "product-profunctors"))
          ];
          buildable = true;
        };
      };
      benchmarks = {
        "bench" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."criterion" or (errorHandler.buildDepError "criterion"))
            (hsPkgs."deepseq" or (errorHandler.buildDepError "deepseq"))
            (hsPkgs."product-profunctors" or (errorHandler.buildDepError "product-profunctors"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/product-profunctors-0.11.1.1.tar.gz";
      sha256 = "3fbe8621294d0431a0a1ab72e358ddd563bc228580b4831104e347f2a5bb1cda";
    });
  }) // {
    package-description-override = "name:          product-profunctors\r\ncopyright:     Copyright (c) 2013, Karamaan Group LLC; 2014-2018 Purely Agile Limited; 2019-2023 Tom Ellis\r\nversion:       0.11.1.1\r\nx-revision: 6\r\nsynopsis:      product-profunctors\r\ndescription:   Product profunctors and tools for working with them\r\nhomepage:      https://github.com/tomjaguarpaw/product-profunctors\r\nbug-reports:   https://github.com/tomjaguarpaw/product-profunctors/issues\r\nlicense:       BSD3\r\nlicense-file:  LICENSE\r\nauthor:        Purely Agile\r\nmaintainer:    Purely Agile\r\ncategory:      Control, Category\r\nbuild-type:    Simple\r\ncabal-version: 1.18\r\ntested-with:   GHC==9.6, GHC==9.4, GHC==9.2, GHC==9.0, GHC==8.10, GHC==8.8\r\nextra-doc-files:\r\n    README.md\r\n    CHANGELOG.md\r\n\r\nsource-repository head\r\n  type:     git\r\n  location: https://github.com/tomjaguarpaw/product-profunctors.git\r\n\r\nlibrary\r\n  default-language: Haskell2010\r\n  build-depends:   base >= 4.5 && < 4.22\r\n                 , profunctors   >= 5   && < 5.7\r\n                 , bifunctors    >= 5.4 && < 6.0\r\n                 , contravariant >= 0.4 && < 1.6\r\n                 , tagged >= 0.0 && < 1\r\n                 , template-haskell < 2.24\r\n                 , th-abstraction >= 0.4 && < 0.8\r\n  exposed-modules: Data.Profunctor.Product,\r\n                   Data.Profunctor.Product.Adaptor\r\n                   Data.Profunctor.Product.Default,\r\n                   Data.Profunctor.Product.Examples,\r\n                   Data.Profunctor.Product.Flatten,\r\n                   Data.Profunctor.Product.Internal.Adaptor\r\n                   Data.Profunctor.Product.Internal.TH,\r\n                   Data.Profunctor.Product.Newtype,\r\n                   Data.Profunctor.Product.TH,\r\n                   Data.Profunctor.Product.Tuples\r\n                   Data.Profunctor.Product.Tuples.TH\r\n  other-modules:   Data.Profunctor.Product.Class,\r\n                   Data.Profunctor.Product.Default.Class\r\n  ghc-options:     -Wall\r\n\r\n  if impl(ghc < 7.10)\r\n    build-depends: transformers >= 0.2 && < 0.6\r\n\r\ntest-suite test\r\n  default-language: Haskell2010\r\n  type: exitcode-stdio-1.0\r\n  main-is: Main.hs\r\n  other-modules: CheckTypes,\r\n                 Definitions,\r\n                 DefinitionsUndecidable\r\n  hs-source-dirs: Test\r\n  build-depends:\r\n    base >= 4 && < 5,\r\n    profunctors,\r\n    product-profunctors\r\n  ghc-options: -Wall\r\n\r\nbenchmark bench\r\n  default-language: Haskell2010\r\n  type: exitcode-stdio-1.0\r\n  main-is: Main.hs\r\n  hs-source-dirs: Bench\r\n  build-depends:\r\n    base >= 4 && < 5,\r\n    criterion,\r\n    deepseq,\r\n    product-profunctors\r\n";
  }