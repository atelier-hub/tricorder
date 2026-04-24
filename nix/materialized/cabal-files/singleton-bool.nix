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
      specVersion = "2.2";
      identifier = { name = "singleton-bool"; version = "0.1.8"; };
      license = "BSD-3-Clause";
      copyright = "";
      maintainer = "Oleg Grenrus <oleg.grenrus@iki.fi>";
      author = "Oleg Grenrus <oleg.grenrus@iki.fi>";
      homepage = "https://github.com/phadej/singleton-bool#readme";
      url = "";
      synopsis = "Type level booleans";
      description = "Type level booleans.\n\n@singletons@ package provides similar functionality,\nbut it has tight dependency constraints.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."deepseq" or (errorHandler.buildDepError "deepseq"))
          (hsPkgs."boring" or (errorHandler.buildDepError "boring"))
          (hsPkgs."dec" or (errorHandler.buildDepError "dec"))
          (hsPkgs."some" or (errorHandler.buildDepError "some"))
        ];
        buildable = true;
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/singleton-bool-0.1.8.tar.gz";
      sha256 = "261bf3d2b93b519a7901266af43d7d454b65aac4ac8fb4e113c68de4db131473";
    });
  }) // {
    package-description-override = "cabal-version:      2.2\nname:               singleton-bool\nversion:            0.1.8\nx-revision:         1\nsynopsis:           Type level booleans\ndescription:\n  Type level booleans.\n  .\n  @singletons@ package provides similar functionality,\n  but it has tight dependency constraints.\n\ncategory:           Dependent Types\nhomepage:           https://github.com/phadej/singleton-bool#readme\nbug-reports:        https://github.com/phadej/singleton-bool/issues\nauthor:             Oleg Grenrus <oleg.grenrus@iki.fi>\nmaintainer:         Oleg Grenrus <oleg.grenrus@iki.fi>\nlicense:            BSD-3-Clause\nlicense-file:       LICENSE\nbuild-type:         Simple\nextra-source-files: CHANGELOG.md\ntested-with:\n  GHC ==8.6.5\n   || ==8.8.4\n   || ==8.10.7\n   || ==9.0.2\n   || ==9.2.8\n   || ==9.4.8\n   || ==9.6.6\n   || ==9.8.4\n   || ==9.10.1\n   || ==9.12.1\n\nsource-repository head\n  type:     git\n  location: https://github.com/phadej/singleton-bool\n\nlibrary\n  hs-source-dirs:   src\n  ghc-options:      -Wall\n  build-depends:\n    , base     >=4.12.0.0 && <4.22\n    , deepseq  >=1.4.4.0  && <1.6\n\n  build-depends:\n    , boring  ^>=0.2.2\n    , dec     ^>=0.0.6\n    , some    ^>=1.0.6\n\n  exposed-modules:  Data.Singletons.Bool\n  default-language: Haskell2010\n";
  }