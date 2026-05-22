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
      specVersion = "1.12";
      identifier = { name = "data-sketches-core"; version = "0.1.0.0"; };
      license = "BSD-3-Clause";
      copyright = "2021 Ian Duncan, Rob Bassi, Mercury Technologies";
      maintainer = "ian@iankduncan.com";
      author = "Ian Duncan";
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
          (hsPkgs."deepseq" or (errorHandler.buildDepError "deepseq"))
          (hsPkgs."ghc-prim" or (errorHandler.buildDepError "ghc-prim"))
          (hsPkgs."mwc-random" or (errorHandler.buildDepError "mwc-random"))
          (hsPkgs."primitive" or (errorHandler.buildDepError "primitive"))
          (hsPkgs."vector" or (errorHandler.buildDepError "vector"))
          (hsPkgs."vector-algorithms" or (errorHandler.buildDepError "vector-algorithms"))
        ];
        buildable = true;
      };
      tests = {
        "data-sketches-core-test" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."data-sketches-core" or (errorHandler.buildDepError "data-sketches-core"))
            (hsPkgs."deepseq" or (errorHandler.buildDepError "deepseq"))
            (hsPkgs."ghc-prim" or (errorHandler.buildDepError "ghc-prim"))
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
      url = "http://hackage.haskell.org/package/data-sketches-core-0.1.0.0.tar.gz";
      sha256 = "2355740a772914b9c1d45c2fd28a790da1c0301867643b08c42e86fdee45dc39";
    });
  }) // {
    package-description-override = "cabal-version: 1.12\n\n-- This file has been generated from package.yaml by hpack version 0.34.4.\n--\n-- see: https://github.com/sol/hpack\n\nname:           data-sketches-core\nversion:        0.1.0.0\ndescription:    Please see the README on GitHub at <https://github.com/iand675/datasketches-haskell#readme>\nhomepage:       https://github.com/iand675/datasketches-haskell#readme\nbug-reports:    https://github.com/iand675/datasketches-haskell/issues\nauthor:         Ian Duncan\nmaintainer:     ian@iankduncan.com\ncopyright:      2021 Ian Duncan, Rob Bassi, Mercury Technologies\nlicense:        BSD3\nlicense-file:   LICENSE\nbuild-type:     Simple\nextra-source-files:\n    README.md\n    ChangeLog.md\n\nsource-repository head\n  type: git\n  location: https://github.com/iand675/datasketches-haskell\n\nlibrary\n  exposed-modules:\n      DataSketches.Core.Internal.URef\n      DataSketches.Core.Snapshot\n      DataSketches.Quantiles.RelativeErrorQuantile.Internal\n      DataSketches.Quantiles.RelativeErrorQuantile.Internal.Auxiliary\n      DataSketches.Quantiles.RelativeErrorQuantile.Internal.Compactor\n      DataSketches.Quantiles.RelativeErrorQuantile.Internal.Constants\n      DataSketches.Quantiles.RelativeErrorQuantile.Internal.DoubleBuffer\n      DataSketches.Quantiles.RelativeErrorQuantile.Internal.InequalitySearch\n      DataSketches.Quantiles.RelativeErrorQuantile.Types\n  other-modules:\n      Paths_data_sketches_core\n  hs-source-dirs:\n      src\n  default-extensions:\n      BangPatterns\n      FlexibleInstances\n      RecordWildCards\n      ScopedTypeVariables\n      StandaloneDeriving\n      TypeFamilies\n      TypeOperators\n  build-depends:\n      base >=4.7 && <5\n    , deepseq\n    , ghc-prim\n    , mwc-random\n    , primitive\n    , vector\n    , vector-algorithms\n  default-language: Haskell2010\n\ntest-suite data-sketches-core-test\n  type: exitcode-stdio-1.0\n  main-is: Spec.hs\n  other-modules:\n      Paths_data_sketches_core\n  hs-source-dirs:\n      test\n  default-extensions:\n      BangPatterns\n      FlexibleInstances\n      RecordWildCards\n      ScopedTypeVariables\n      StandaloneDeriving\n      TypeFamilies\n      TypeOperators\n  ghc-options: -threaded -rtsopts -with-rtsopts=-N\n  build-depends:\n      base >=4.7 && <5\n    , data-sketches-core\n    , deepseq\n    , ghc-prim\n    , mwc-random\n    , primitive\n    , vector\n    , vector-algorithms\n  default-language: Haskell2010\n";
  }