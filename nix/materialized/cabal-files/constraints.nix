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
      specVersion = "2.4";
      identifier = { name = "constraints"; version = "0.14.2"; };
      license = "BSD-2-Clause";
      copyright = "Copyright (C) 2011-2021 Edward A. Kmett";
      maintainer = "Edward A. Kmett <ekmett@gmail.com>";
      author = "Edward A. Kmett";
      homepage = "http://github.com/ekmett/constraints/";
      url = "";
      synopsis = "Constraint manipulation";
      description = "GHC 7.4 gave us the ability to talk about @ConstraintKinds@. They stopped crashing the compiler in GHC 7.6.\n\nThis package provides a vocabulary for working with them.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."binary" or (errorHandler.buildDepError "binary"))
          (hsPkgs."boring" or (errorHandler.buildDepError "boring"))
          (hsPkgs."deepseq" or (errorHandler.buildDepError "deepseq"))
          (hsPkgs."ghc-prim" or (errorHandler.buildDepError "ghc-prim"))
          (hsPkgs."hashable" or (errorHandler.buildDepError "hashable"))
          (hsPkgs."mtl" or (errorHandler.buildDepError "mtl"))
          (hsPkgs."transformers" or (errorHandler.buildDepError "transformers"))
        ] ++ pkgs.lib.optional (!(compiler.isGhc && compiler.version.ge "9.0")) (hsPkgs."integer-gmp" or (errorHandler.buildDepError "integer-gmp"));
        buildable = true;
      };
      tests = {
        "spec" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."constraints" or (errorHandler.buildDepError "constraints"))
            (hsPkgs."hspec" or (errorHandler.buildDepError "hspec"))
          ];
          build-tools = [
            (hsPkgs.pkgsBuildBuild.hspec-discover.components.exes.hspec-discover or (pkgs.pkgsBuildBuild.hspec-discover or (errorHandler.buildToolDepError "hspec-discover:hspec-discover")))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/constraints-0.14.2.tar.gz";
      sha256 = "4f249f805d1807ecd86e36e2aa9c9ad8206d2b70d50ff7f11b79721e08fd19f8";
    });
  }) // {
    package-description-override = "cabal-version: 2.4\r\nname:          constraints\r\ncategory:      Constraints\r\nversion:       0.14.2\r\nx-revision: 1\r\nlicense:       BSD-2-Clause\r\nlicense-file:  LICENSE\r\nauthor:        Edward A. Kmett\r\nmaintainer:    Edward A. Kmett <ekmett@gmail.com>\r\nstability:     experimental\r\nhomepage:      http://github.com/ekmett/constraints/\r\nbug-reports:   http://github.com/ekmett/constraints/issues\r\ncopyright:     Copyright (C) 2011-2021 Edward A. Kmett\r\nsynopsis:      Constraint manipulation\r\ndescription:\r\n  GHC 7.4 gave us the ability to talk about @ConstraintKinds@. They stopped crashing the compiler in GHC 7.6.\r\n  .\r\n  This package provides a vocabulary for working with them.\r\n\r\nbuild-type:    Simple\r\n\r\ntested-with:\r\n  GHC == 9.8.1\r\n  GHC == 9.6.3\r\n  GHC == 9.4.7\r\n  GHC == 9.2.8\r\n  GHC == 9.0.2\r\n  GHC == 8.10.7\r\n  GHC == 8.8.4\r\n  GHC == 8.6.5\r\n\r\nextra-source-files: README.markdown\r\n                  , CHANGELOG.markdown\r\n\r\nsource-repository head\r\n  type: git\r\n  location: https://github.com/ekmett/constraints.git\r\n\r\nlibrary\r\n  hs-source-dirs: src\r\n\r\n  default-language: Haskell2010\r\n  other-extensions:\r\n    FunctionalDependencies,\r\n    ScopedTypeVariables,\r\n    StandaloneDeriving,\r\n    FlexibleInstances,\r\n    FlexibleContexts,\r\n    ConstraintKinds,\r\n    KindSignatures,\r\n    TypeOperators,\r\n    Rank2Types,\r\n    GADTs\r\n\r\n  build-depends:\r\n    , base           >= 4.12  && < 5\r\n    , binary         >= 0.7.1 && < 0.9\r\n    , boring         >= 0.2   && < 0.3\r\n    , deepseq        >= 1.3   && < 1.6\r\n    , ghc-prim\r\n    , hashable       >= 1.2   && < 1.6\r\n    , mtl            >= 2.2   && < 2.4\r\n    , transformers   >= 0.5   && < 0.7\r\n  if !impl(ghc >= 9.0)\r\n    build-depends:\r\n      integer-gmp\r\n\r\n  exposed-modules:\r\n    Data.Constraint\r\n    Data.Constraint.Deferrable\r\n    Data.Constraint.Forall\r\n    Data.Constraint.Lifting\r\n    Data.Constraint.Nat\r\n    Data.Constraint.Symbol\r\n    Data.Constraint.Unsafe\r\n\r\n  if impl(ghc >= 9.2)\r\n    exposed-modules:\r\n      Data.Constraint.Char\r\n\r\n  ghc-options: -Wall -Wno-star-is-type\r\n\r\ntest-suite spec\r\n  type: exitcode-stdio-1.0\r\n  default-language: Haskell2010\r\n  hs-source-dirs: tests\r\n  main-is: Spec.hs\r\n  other-modules: GH55Spec\r\n                 GH117Spec\r\n  ghc-options: -Wall -threaded -rtsopts\r\n  build-tool-depends: hspec-discover:hspec-discover >= 2\r\n  build-depends:\r\n    , base\r\n    , constraints\r\n    , hspec >= 2\r\n";
  }