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
      identifier = { name = "OneTuple"; version = "0.4.2"; };
      license = "BSD-3-Clause";
      copyright = "(c) John Dorsey 2008";
      maintainer = "Oleg Grenrus <oleg.grenrus@iki.fi>, John Dorsey <haskell@colquitt.org>";
      author = "John Dorsey <haskell@colquitt.org>";
      homepage = "";
      url = "";
      synopsis = "Singleton Tuple";
      description = "This package is a compatibility package for a singleton data type\n\n> data Solo a = MkSolo a\n\nNote: it's not a @newtype@\n\n@Solo@ is available in @base-4.16@ (GHC-9.2).";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = (([
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."template-haskell" or (errorHandler.buildDepError "template-haskell"))
        ] ++ (if compiler.isGhc && compiler.version.ge "9.0"
          then [
            (hsPkgs."ghc-prim" or (errorHandler.buildDepError "ghc-prim"))
          ]
          else [
            (hsPkgs."hashable" or (errorHandler.buildDepError "hashable"))
          ])) ++ pkgs.lib.optional (!(compiler.isGhc && compiler.version.ge "9.0")) (hsPkgs."foldable1-classes-compat" or (errorHandler.buildDepError "foldable1-classes-compat"))) ++ pkgs.lib.optional (!(compiler.isGhc && compiler.version.ge "9.2")) (hsPkgs."base-orphans" or (errorHandler.buildDepError "base-orphans"));
        buildable = true;
      };
      tests = {
        "instances" = {
          depends = ([
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."hashable" or (errorHandler.buildDepError "hashable"))
            (hsPkgs."OneTuple" or (errorHandler.buildDepError "OneTuple"))
          ] ++ pkgs.lib.optionals (!(compiler.isGhc && compiler.version.ge "8.0")) [
            (hsPkgs."semigroups" or (errorHandler.buildDepError "semigroups"))
            (hsPkgs."transformers" or (errorHandler.buildDepError "transformers"))
            (hsPkgs."transformers-compat" or (errorHandler.buildDepError "transformers-compat"))
          ]) ++ pkgs.lib.optional (!(compiler.isGhc && compiler.version.ge "9.6")) (hsPkgs."foldable1-classes-compat" or (errorHandler.buildDepError "foldable1-classes-compat"));
          buildable = true;
        };
        "th" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."OneTuple" or (errorHandler.buildDepError "OneTuple"))
            (hsPkgs."template-haskell" or (errorHandler.buildDepError "template-haskell"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/OneTuple-0.4.2.tar.gz";
      sha256 = "174da8a0f4004d17b08182cb25b0e045fce5de1fdeae84e9d75fdea2867aab55";
    });
  }) // {
    package-description-override = "cabal-version:      1.12\nname:               OneTuple\nversion:            0.4.2\nx-revision:         1\nsynopsis:           Singleton Tuple\ncategory:           Data\ndescription:\n  This package is a compatibility package for a singleton data type\n  .\n  > data Solo a = MkSolo a\n  .\n  Note: it's not a @newtype@\n  .\n  @Solo@ is available in @base-4.16@ (GHC-9.2).\n\ncopyright:          (c) John Dorsey 2008\nlicense:            BSD3\nlicense-file:       LICENSE\nauthor:             John Dorsey <haskell@colquitt.org>\nmaintainer:\n  Oleg Grenrus <oleg.grenrus@iki.fi>, John Dorsey <haskell@colquitt.org>\n\nstability:          experimental\nbuild-type:         Simple\ntested-with:\n  GHC ==8.6.5\n   || ==8.8.4\n   || ==8.10.7\n   || ==9.0.2\n   || ==9.2.8\n   || ==9.4.8\n   || ==9.6.4\n   || ==9.8.6\n   || ==9.10.1\n   || ==9.12.1\n\nextra-source-files: Changelog.md\n\nsource-repository head\n  type:     git\n  location: https://github.com/phadej/OneTuple.git\n\nlibrary\n  default-language: Haskell98\n  exposed-modules:\n    Data.Tuple.OneTuple\n    Data.Tuple.Solo\n    Data.Tuple.Solo.TH\n\n  hs-source-dirs:   src\n  build-depends:\n      base              >=4.12 && <4.22\n    , template-haskell\n\n  if impl(ghc >=9.0)\n    build-depends: ghc-prim\n  else\n    build-depends: hashable >=1.3.5.0 && <1.6\n\n  if !impl(ghc >=9.0)\n    build-depends: foldable1-classes-compat >=0.1 && <0.2\n\n  if !impl(ghc >=9.2)\n    build-depends: base-orphans >=0.8.6\n\ntest-suite instances\n  type:             exitcode-stdio-1.0\n  default-language: Haskell98\n  hs-source-dirs:   test\n  main-is:          instances.hs\n  build-depends:\n      base\n    , hashable\n    , OneTuple\n\n  if !impl(ghc >=8.0)\n    build-depends:\n        semigroups\n      , transformers\n      , transformers-compat\n\n  if !impl(ghc >=9.6)\n    build-depends: foldable1-classes-compat >=0.1 && <0.2\n\ntest-suite th\n  type:             exitcode-stdio-1.0\n  default-language: Haskell98\n  hs-source-dirs:   test\n  main-is:          th.hs\n  build-depends:\n      base\n    , OneTuple\n    , template-haskell\n";
  }