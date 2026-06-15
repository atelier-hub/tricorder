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
      identifier = { name = "smallcheck"; version = "1.2.1.1"; };
      license = "BSD-3-Clause";
      copyright = "";
      maintainer = "Andrew Lelechenko <andrew.lelechenko@gmail.com>";
      author = "Colin Runciman, Roman Cheplyaka";
      homepage = "https://github.com/Bodigrim/smallcheck";
      url = "";
      synopsis = "A property-based testing library";
      description = "As of 2023, this library is largely obsolete: arbitrary test generators\nwith shrinking such as [falsify](https://hackage.haskell.org/package/falsify)\noffer much better user experience.\n\nSmallCheck is a testing library that allows to verify properties\nfor all test cases up to some depth. The test cases are generated\nautomatically by SmallCheck.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = (([
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."mtl" or (errorHandler.buildDepError "mtl"))
          (hsPkgs."logict" or (errorHandler.buildDepError "logict"))
          (hsPkgs."pretty" or (errorHandler.buildDepError "pretty"))
        ] ++ pkgs.lib.optionals (compiler.isGhc && compiler.version.lt "8.0") [
          (hsPkgs."semigroups" or (errorHandler.buildDepError "semigroups"))
          (hsPkgs."transformers" or (errorHandler.buildDepError "transformers"))
        ]) ++ pkgs.lib.optionals (compiler.isGhc && compiler.version.lt "7.10") [
          (hsPkgs."nats" or (errorHandler.buildDepError "nats"))
          (hsPkgs."void" or (errorHandler.buildDepError "void"))
        ]) ++ pkgs.lib.optional (compiler.isGhc && compiler.version.lt "7.6") (hsPkgs."ghc-prim" or (errorHandler.buildDepError "ghc-prim"));
        buildable = true;
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/smallcheck-1.2.1.1.tar.gz";
      sha256 = "e043225004071840d1a13f3a2d6fba537144188e7995a978ab82086ce158fe1f";
    });
  }) // {
    package-description-override = "name:               smallcheck\nversion:            1.2.1.1\nlicense:            BSD3\nlicense-file:       LICENSE\nmaintainer:         Andrew Lelechenko <andrew.lelechenko@gmail.com>\nauthor:             Colin Runciman, Roman Cheplyaka\ncabal-version:      >=1.10\ntested-with:\n  ghc ==9.6.1 ghc ==9.4.5\n  ghc ==9.2.7 ghc ==9.0.2 ghc ==8.10.7 ghc ==8.8.4 ghc ==8.6.5 ghc ==8.4.4 ghc ==8.2.2\n  ghc ==8.0.2 ghc ==7.10.3 ghc ==7.8.4 ghc ==7.6.3 ghc ==7.4.2 ghc ==7.2.2 ghc ==7.0.4\n\nhomepage:           https://github.com/Bodigrim/smallcheck\nbug-reports:        https://github.com/Bodigrim/smallcheck/issues\nsynopsis:           A property-based testing library\ndescription:\n  As of 2023, this library is largely obsolete: arbitrary test generators\n  with shrinking such as [falsify](https://hackage.haskell.org/package/falsify)\n  offer much better user experience.\n  .\n  SmallCheck is a testing library that allows to verify properties\n  for all test cases up to some depth. The test cases are generated\n  automatically by SmallCheck.\n\ncategory:           Testing\nbuild-type:         Simple\nextra-source-files:\n  README.md\n  CREDITS.md\n  CHANGELOG.md\n\nsource-repository head\n  type:     git\n  location: git://github.com/Bodigrim/smallcheck.git\n\nlibrary\n  default-language: Haskell2010\n\n  exposed-modules:\n    Test.SmallCheck\n    Test.SmallCheck.Drivers\n    Test.SmallCheck.Series\n\n  other-modules:\n    Test.SmallCheck.Property\n    Test.SmallCheck.SeriesMonad\n    Test.SmallCheck.Property.Result\n\n  build-depends:\n    base >=4.3 && <5,\n    mtl <2.4,\n    logict >=0.5 && <0.9,\n    pretty <1.2\n\n  if impl(ghc <8.0)\n    build-depends:\n      semigroups <0.21,\n      transformers <0.7\n\n  if impl(ghc <7.10)\n    build-depends:\n      nats <1.2,\n      void <0.8\n\n  if impl(ghc <7.6)\n    build-depends:\n      ghc-prim >=0.2 && <1\n\n  if impl(ghc >= 8.0)\n    ghc-options:    -Wcompat\n";
  }