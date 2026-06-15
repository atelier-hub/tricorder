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
      identifier = { name = "strict-mutable-base"; version = "1.1.0.0"; };
      license = "BSD-3-Clause";
      copyright = "";
      maintainer = "andrzej@rybczak.net";
      author = "Andrzej Rybczak";
      homepage = "https://github.com/arybczak/strict-mutable";
      url = "";
      synopsis = "Strict variants of mutable data types from base.";
      description = "Strict (WHNF) variants of @Chan@, @IORef@ and @MVar@ for proactive\nprevention of space leaks.";
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
      url = "http://hackage.haskell.org/package/strict-mutable-base-1.1.0.0.tar.gz";
      sha256 = "ffe3d127d84a3931a67005f4388de4d8f908c8ed57feb3e7797d6eb0d13e90ff";
    });
  }) // {
    package-description-override = "cabal-version:      3.0\nbuild-type:         Simple\nname:               strict-mutable-base\nversion:            1.1.0.0\nhomepage:           https://github.com/arybczak/strict-mutable\nlicense:            BSD-3-Clause\nlicense-file:       LICENSE\ncategory:           Data\nmaintainer:         andrzej@rybczak.net\nauthor:             Andrzej Rybczak\n\nsynopsis: Strict variants of mutable data types from base.\n\ndescription: Strict (WHNF) variants of @Chan@, @IORef@ and @MVar@ for proactive\n             prevention of space leaks.\n\nextra-doc-files:\n  CHANGELOG.md\n  README.md\n\ntested-with: GHC == { 8.0.2, 8.2.2, 8.4.4, 8.6.5, 8.8.4, 8.10.7, 9.0.2, 9.2.8, 9.4.8, 9.6.6, 9.8.2, 9.10.1 }\n\nbug-reports:   https://github.com/arybczak/strict-mutable/issues\nsource-repository head\n  type:     git\n  location: https://github.com/arybczak/strict-mutable.git\n\ncommon language\n    ghc-options:        -Wall -Wcompat\n\n    default-language:   Haskell2010\n\n    default-extensions: GeneralizedNewtypeDeriving\n                        LambdaCase\n                        MagicHash\n                        TupleSections\n                        UnboxedTuples\n\nlibrary\n    import:           language\n\n    build-depends:    base >=4.9 && < 5\n                    , deepseq >= 1.4.3.0\n\n    hs-source-dirs:   src\n\n    exposed-modules:  Control.Concurrent.Chan.Strict\n                      Control.Concurrent.MVar.Strict\n                      Data.IORef.Strict\n";
  }