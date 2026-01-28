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
      identifier = { name = "data-sketches"; version = "0.3.1.0"; };
      license = "LicenseRef-Apache";
      copyright = "2021 Ian Duncan, Rob Bassi, Mercury Technologies";
      maintainer = "ian@iankduncan.com";
      author = "Ian Duncan, Rob Bassi";
      homepage = "https://github.com/iand675/datasketches-haskell#readme";
      url = "";
      synopsis = "";
      description = "Please see the README on GitHub at <https://github.com/iand675/datasketches-haskell#readme>";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."data-sketches-core" or (errorHandler.buildDepError "data-sketches-core"))
          (hsPkgs."ghc-prim" or (errorHandler.buildDepError "ghc-prim"))
          (hsPkgs."mtl" or (errorHandler.buildDepError "mtl"))
          (hsPkgs."mwc-random" or (errorHandler.buildDepError "mwc-random"))
          (hsPkgs."primitive" or (errorHandler.buildDepError "primitive"))
          (hsPkgs."vector" or (errorHandler.buildDepError "vector"))
          (hsPkgs."vector-algorithms" or (errorHandler.buildDepError "vector-algorithms"))
        ];
        buildable = true;
      };
      tests = {
        "data-sketches-test" = {
          depends = [
            (hsPkgs."QuickCheck" or (errorHandler.buildDepError "QuickCheck"))
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."data-sketches" or (errorHandler.buildDepError "data-sketches"))
            (hsPkgs."data-sketches-core" or (errorHandler.buildDepError "data-sketches-core"))
            (hsPkgs."ghc-prim" or (errorHandler.buildDepError "ghc-prim"))
            (hsPkgs."hspec" or (errorHandler.buildDepError "hspec"))
            (hsPkgs."hspec-discover" or (errorHandler.buildDepError "hspec-discover"))
            (hsPkgs."mtl" or (errorHandler.buildDepError "mtl"))
            (hsPkgs."mwc-random" or (errorHandler.buildDepError "mwc-random"))
            (hsPkgs."pretty-show" or (errorHandler.buildDepError "pretty-show"))
            (hsPkgs."primitive" or (errorHandler.buildDepError "primitive"))
            (hsPkgs."statistics" or (errorHandler.buildDepError "statistics"))
            (hsPkgs."vector" or (errorHandler.buildDepError "vector"))
            (hsPkgs."vector-algorithms" or (errorHandler.buildDepError "vector-algorithms"))
          ];
          buildable = true;
        };
      };
      benchmarks = {
        "bench" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."criterion" or (errorHandler.buildDepError "criterion"))
            (hsPkgs."data-sketches" or (errorHandler.buildDepError "data-sketches"))
            (hsPkgs."data-sketches-core" or (errorHandler.buildDepError "data-sketches-core"))
            (hsPkgs."ghc-prim" or (errorHandler.buildDepError "ghc-prim"))
            (hsPkgs."mtl" or (errorHandler.buildDepError "mtl"))
            (hsPkgs."mwc-random" or (errorHandler.buildDepError "mwc-random"))
            (hsPkgs."primitive" or (errorHandler.buildDepError "primitive"))
            (hsPkgs."vector" or (errorHandler.buildDepError "vector"))
            (hsPkgs."vector-algorithms" or (errorHandler.buildDepError "vector-algorithms"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/data-sketches-0.3.1.0.tar.gz";
      sha256 = "7ff596faf9903e57e5fad3b7517721775b3ab874ac9a15b4b15b5001d9296128";
    });
  }) // {
    package-description-override = "cabal-version: 1.18\n\n-- This file has been generated from package.yaml by hpack version 0.34.4.\n--\n-- see: https://github.com/sol/hpack\n\nname:           data-sketches\nversion:        0.3.1.0\ndescription:    Please see the README on GitHub at <https://github.com/iand675/datasketches-haskell#readme>\nhomepage:       https://github.com/iand675/datasketches-haskell#readme\nbug-reports:    https://github.com/iand675/datasketches-haskell/issues\nauthor:         Ian Duncan, Rob Bassi\nmaintainer:     ian@iankduncan.com\ncopyright:      2021 Ian Duncan, Rob Bassi, Mercury Technologies\nlicense:        Apache\nlicense-file:   LICENSE\nbuild-type:     Simple\nextra-source-files:\n    README.md\n    ChangeLog.md\nextra-doc-files:\n    docs/images/KllErrorK100SL11.png\n    docs/images/ReqErrorHraK12SL11_LT.png\n    docs/images/ReqErrorLraK12SL11_LE.png\n\nsource-repository head\n  type: git\n  location: https://github.com/iand675/datasketches-haskell\n\nlibrary\n  exposed-modules:\n      DataSketches.Quantiles.RelativeErrorQuantile\n  other-modules:\n      Paths_data_sketches\n  hs-source-dirs:\n      src\n  default-extensions:\n      BangPatterns\n      FlexibleInstances\n      RecordWildCards\n      ScopedTypeVariables\n      StandaloneDeriving\n      TypeFamilies\n      TypeOperators\n  build-depends:\n      base >=4.7 && <5\n    , data-sketches-core ==0.1.*\n    , ghc-prim\n    , mtl\n    , mwc-random\n    , primitive\n    , vector\n    , vector-algorithms\n  default-language: Haskell2010\n\ntest-suite data-sketches-test\n  type: exitcode-stdio-1.0\n  main-is: Spec.hs\n  other-modules:\n      AuxiliarySpec\n      CompactorSpec\n      DoubleBufferSpec\n      ProofCheckSpec\n      RelativeErrorQuantileSpec\n      Paths_data_sketches\n  hs-source-dirs:\n      test\n  default-extensions:\n      BangPatterns\n      FlexibleInstances\n      RecordWildCards\n      ScopedTypeVariables\n      StandaloneDeriving\n      TypeFamilies\n      TypeOperators\n  ghc-options: -threaded -rtsopts -with-rtsopts=-N\n  build-depends:\n      QuickCheck\n    , base >=4.7 && <5\n    , data-sketches\n    , data-sketches-core ==0.1.*\n    , ghc-prim\n    , hspec\n    , hspec-discover\n    , mtl\n    , mwc-random\n    , pretty-show\n    , primitive\n    , statistics\n    , vector\n    , vector-algorithms\n  default-language: Haskell2010\n\nbenchmark bench\n  type: exitcode-stdio-1.0\n  main-is: Bench.hs\n  other-modules:\n      Paths_data_sketches\n  hs-source-dirs:\n      bench\n  default-extensions:\n      BangPatterns\n      FlexibleInstances\n      RecordWildCards\n      ScopedTypeVariables\n      StandaloneDeriving\n      TypeFamilies\n      TypeOperators\n  ghc-options: -threaded -rtsopts -with-rtsopts=-N\n  build-depends:\n      base >=4.7 && <5\n    , criterion\n    , data-sketches\n    , data-sketches-core ==0.1.*\n    , ghc-prim\n    , mtl\n    , mwc-random\n    , primitive\n    , vector\n    , vector-algorithms\n  default-language: Haskell2010\n";
  }