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
      identifier = { name = "postgres-options"; version = "0.2.2.0"; };
      license = "BSD-3-Clause";
      copyright = "2019 Jonathan Fischoff";
      maintainer = "jonathangfischoff@gmail.com";
      author = "Jonathan Fischoff";
      homepage = "https://github.com/jfischoff/postgres-options#readme";
      url = "";
      synopsis = "An Options type representing options for postgres connections";
      description = "This package exports an Options type representing options for postgres connections";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          (hsPkgs."split" or (errorHandler.buildDepError "split"))
          (hsPkgs."uri-bytestring" or (errorHandler.buildDepError "uri-bytestring"))
          (hsPkgs."generic-monoid" or (errorHandler.buildDepError "generic-monoid"))
        ];
        buildable = true;
      };
      tests = {
        "unit-tests" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."hspec" or (errorHandler.buildDepError "hspec"))
            (hsPkgs."postgres-options" or (errorHandler.buildDepError "postgres-options"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/postgres-options-0.2.2.0.tar.gz";
      sha256 = "65d70222f7b28695659f081cb8c87b5745a72fc01e3d4dbdd004286248bfbf3a";
    });
  }) // {
    package-description-override = "name:                postgres-options\nversion:             0.2.2.0\nsynopsis:            An Options type representing options for postgres connections\ndescription:         This package exports an Options type representing options for postgres connections\nhomepage:            https://github.com/jfischoff/postgres-options#readme\nlicense:             BSD3\nlicense-file:        LICENSE\nauthor:              Jonathan Fischoff\nmaintainer:          jonathangfischoff@gmail.com\ncopyright:           2019 Jonathan Fischoff\ncategory:            Database\nbuild-type:          Simple\n-- extra-source-files:\ncabal-version:       >=1.10\n\nlibrary\n  hs-source-dirs:      src\n  exposed-modules:     Database.PostgreSQL.Simple.Options\n  build-depends:\n      base >= 4.6 && < 5\n    , bytestring\n    , split\n    , uri-bytestring\n    , generic-monoid\n  default-language:    Haskell2010\n  ghc-options: -Wall\n               -fno-warn-unused-do-bind\n  default-extensions:\n      LambdaCase\n    , RecordWildCards\n    , GADTs\n    , OverloadedStrings\n    , DerivingStrategies\n    , DerivingVia\n    , TupleSections\n    , DeriveGeneric\n\ntest-suite unit-tests\n  type:                exitcode-stdio-1.0\n  hs-source-dirs:      test\n  main-is:             Spec.hs\n  build-depends:       base\n                     , hspec\n                     , postgres-options\n  ghc-options: -Wall\n               -fno-warn-unused-do-bind\n               -threaded\n               -rtsopts\n               -with-rtsopts=-N\n  default-language:    Haskell2010\n\n\nsource-repository head\n  type:     git\n  location: https://github.com/jfischoff/postgres-options\n";
  }