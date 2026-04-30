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
      specVersion = "1.10";
      identifier = { name = "sop-core"; version = "0.5.0.2"; };
      license = "BSD-3-Clause";
      copyright = "";
      maintainer = "andres@well-typed.com";
      author = "Edsko de Vries <edsko@well-typed.com>, Andres Löh <andres@well-typed.com>";
      homepage = "";
      url = "";
      synopsis = "True Sums of Products";
      description = "Implementation of n-ary sums and n-ary products.\n\nThe module \"Data.SOP\" is the main module of this library and contains\nmore detailed documentation.\n\nThe main use case of this package is to serve as the core of\n@<https://hackage.haskell.org/package/generics-sop generics-sop>@.\n\nA detailed description of the ideas behind this library is provided by\nthe paper:\n\n* Edsko de Vries and Andres Löh.\n<http://www.andres-loeh.de/TrueSumsOfProducts True Sums of Products>.\nWorkshop on Generic Programming (WGP) 2014.\n";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."deepseq" or (errorHandler.buildDepError "deepseq"))
        ];
        buildable = true;
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/sop-core-0.5.0.2.tar.gz";
      sha256 = "87bffd2254b98ded822d449fcd1c33dbd74d2ce96bf35e7a6714abc5a2297265";
    });
  }) // {
    package-description-override = "name:                sop-core\r\nversion:             0.5.0.2\r\nx-revision: 6\r\nsynopsis:            True Sums of Products\r\ndescription:\r\n  Implementation of n-ary sums and n-ary products.\r\n  .\r\n  The module \"Data.SOP\" is the main module of this library and contains\r\n  more detailed documentation.\r\n  .\r\n  The main use case of this package is to serve as the core of\r\n  @<https://hackage.haskell.org/package/generics-sop generics-sop>@.\r\n  .\r\n  A detailed description of the ideas behind this library is provided by\r\n  the paper:\r\n  .\r\n    * Edsko de Vries and Andres Löh.\r\n      <http://www.andres-loeh.de/TrueSumsOfProducts True Sums of Products>.\r\n      Workshop on Generic Programming (WGP) 2014.\r\n  .\r\nlicense:             BSD3\r\nlicense-file:        LICENSE\r\nauthor:              Edsko de Vries <edsko@well-typed.com>, Andres Löh <andres@well-typed.com>\r\nmaintainer:          andres@well-typed.com\r\ncategory:            Data\r\nbuild-type:          Simple\r\ncabal-version:       >=1.10\r\nextra-source-files:  CHANGELOG.md doctest.sh\r\ntested-with:         GHC == 8.0.2, GHC == 8.2.2, GHC == 8.4.4, GHC == 8.6.5, GHC == 8.8.4, GHC == 8.10.7, GHC == 9.0.2, GHC == 9.2.7, GHC == 9.4.4, GHC == 9.6.6, GHC == 9.8.4, GHC == 9.10.1, GHC == 9.12.1, GHC == 9.14.1\r\n\r\nsource-repository head\r\n  type:                git\r\n  location:            https://github.com/well-typed/generics-sop\r\n\r\nlibrary\r\n  exposed-modules:     Data.SOP\r\n                       Data.SOP.Dict\r\n                       -- exposed via Data.SOP:\r\n                       Data.SOP.BasicFunctors\r\n                       Data.SOP.Classes\r\n                       Data.SOP.Constraint\r\n                       Data.SOP.NP\r\n                       Data.SOP.NS\r\n                       Data.SOP.Sing\r\n  build-depends:       base                 >= 4.9  && < 4.23,\r\n                       deepseq              >= 1.3  && < 1.6\r\n  hs-source-dirs:      src\r\n  default-language:    Haskell2010\r\n  ghc-options:         -Wall\r\n  default-extensions:  CPP\r\n                       ScopedTypeVariables\r\n                       TypeFamilies\r\n                       RankNTypes\r\n                       TypeOperators\r\n                       GADTs\r\n                       ConstraintKinds\r\n                       MultiParamTypeClasses\r\n                       TypeSynonymInstances\r\n                       FlexibleInstances\r\n                       FlexibleContexts\r\n                       DeriveFunctor\r\n                       DeriveFoldable\r\n                       DeriveTraversable\r\n                       DefaultSignatures\r\n                       KindSignatures\r\n                       DataKinds\r\n                       FunctionalDependencies\r\n\r\n  if impl(ghc <8.2)\r\n    default-extensions: AutoDeriveTypeable\r\n\r\n  -- if impl(ghc >= 8.6)\r\n  --   default-extensions: NoStarIsType\r\n  other-extensions:    PolyKinds\r\n                       UndecidableInstances\r\n                       DeriveGeneric\r\n                       StandaloneDeriving\r\n                       EmptyCase\r\n                       UndecidableSuperClasses\r\n                       BangPatterns\r\n";
  }