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
      identifier = { name = "these"; version = "1.2.1"; };
      license = "BSD-3-Clause";
      copyright = "";
      maintainer = "Oleg Grenrus <oleg.grenrus@iki.fi>";
      author = "C. McCann, Oleg Grenrus";
      homepage = "https://github.com/haskellari/these";
      url = "";
      synopsis = "An either-or-both data type.";
      description = "This package provides a data type @These a b@ which can hold a value of either\ntype or values of each type. This is usually thought of as an \"inclusive or\"\ntype (contrasting @Either a b@ as \"exclusive or\") or as an \"outer join\" type\n(contrasting @(a, b)@ as \"inner join\").\n\n@\ndata These a b = This a | That b | These a b\n@\n\nSince version 1, this package was split into parts:\n\n* <https://hackage.haskell.org/package/semialign semialign> For @Align@ and @Zip@ type-classes.\n\n* <https://hackage.haskell.org/package/semialign-indexed semialign-indexed> For @SemialignWithIndex@ class, providing @ialignWith@ and @izipWith@.\n\n* <https://hackage.haskell.org/package/these-lens these-lens> For lens combinators.\n\n* <http://hackage.haskell.org/package/monad-chronicle monad-chronicle> For transformers variant of @These@.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."binary" or (errorHandler.buildDepError "binary"))
          (hsPkgs."deepseq" or (errorHandler.buildDepError "deepseq"))
          (hsPkgs."assoc" or (errorHandler.buildDepError "assoc"))
          (hsPkgs."hashable" or (errorHandler.buildDepError "hashable"))
        ] ++ pkgs.lib.optional (!(compiler.isGhc && compiler.version.ge "9.6")) (hsPkgs."foldable1-classes-compat" or (errorHandler.buildDepError "foldable1-classes-compat"));
        buildable = true;
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/these-1.2.1.tar.gz";
      sha256 = "17d6d933365edabf801a16842c1403bdd37cc5300faa2fcca980decdab22e4de";
    });
  }) // {
    package-description-override = "cabal-version:      >=1.10\nname:               these\nversion:            1.2.1\nx-revision:         2\nsynopsis:           An either-or-both data type.\nhomepage:           https://github.com/haskellari/these\nlicense:            BSD3\nlicense-file:       LICENSE\nauthor:             C. McCann, Oleg Grenrus\nmaintainer:         Oleg Grenrus <oleg.grenrus@iki.fi>\ncategory:           Data, These\nbuild-type:         Simple\nextra-source-files: CHANGELOG.md\ndescription:\n  This package provides a data type @These a b@ which can hold a value of either\n  type or values of each type. This is usually thought of as an \"inclusive or\"\n  type (contrasting @Either a b@ as \"exclusive or\") or as an \"outer join\" type\n  (contrasting @(a, b)@ as \"inner join\").\n  .\n  @\n  data These a b = This a | That b | These a b\n  @\n  .\n  Since version 1, this package was split into parts:\n  .\n  * <https://hackage.haskell.org/package/semialign semialign> For @Align@ and @Zip@ type-classes.\n  .\n  * <https://hackage.haskell.org/package/semialign-indexed semialign-indexed> For @SemialignWithIndex@ class, providing @ialignWith@ and @izipWith@.\n  .\n  * <https://hackage.haskell.org/package/these-lens these-lens> For lens combinators.\n  .\n  * <http://hackage.haskell.org/package/monad-chronicle monad-chronicle> For transformers variant of @These@.\n\ntested-with:\n  GHC ==8.6.5\n   || ==8.8.4\n   || ==8.10.7\n   || ==9.0.2\n   || ==9.2.8\n   || ==9.4.8\n   || ==9.6.6\n   || ==9.8.4\n   || ==9.10.1\n   || ==9.12.1\n\nsource-repository head\n  type:     git\n  location: https://github.com/haskellari/these.git\n  subdir:   these\n\nlibrary\n  default-language:         Haskell2010\n  ghc-options:              -Wall -Wno-trustworthy-safe\n  hs-source-dirs:           src\n  exposed-modules:\n    Data.Functor.These\n    Data.These\n    Data.These.Combinators\n\n  -- ghc boot libs\n  build-depends:\n      base     >=4.12.0.0 && <4.22\n    , binary   >=0.8.6.0  && <0.10\n    , deepseq  >=1.4.4.0  && <1.6\n\n  -- other dependencies\n  -- note: we need to depend on assoc-1.1 to be sure that\n  -- Bifunctor type class comes from bifunctor-classes-compat\n  build-depends:\n      assoc     >=1.1.1   && <1.2\n    , hashable  >=1.4.4.0 && <1.6\n\n  if !impl(ghc >=9.6)\n    build-depends: foldable1-classes-compat >=0.1 && <0.2\n\n  x-docspec-extra-packages: lens\n";
  }