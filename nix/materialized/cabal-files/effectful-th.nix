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
      identifier = { name = "effectful-th"; version = "1.0.0.3"; };
      license = "BSD-3-Clause";
      copyright = "";
      maintainer = "andrzej@rybczak.net";
      author = "Andrzej Rybczak";
      homepage = "";
      url = "";
      synopsis = "Template Haskell utilities for the effectful library.";
      description = "Generate functions for performing operations of dynamically dispatched effects\nvia Template Haskell.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
          (hsPkgs."effectful-core" or (errorHandler.buildDepError "effectful-core"))
          (hsPkgs."exceptions" or (errorHandler.buildDepError "exceptions"))
          (hsPkgs."template-haskell" or (errorHandler.buildDepError "template-haskell"))
          (hsPkgs."th-abstraction" or (errorHandler.buildDepError "th-abstraction"))
        ];
        buildable = true;
      };
      tests = {
        "th-tests" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."effectful-core" or (errorHandler.buildDepError "effectful-core"))
            (hsPkgs."effectful-th" or (errorHandler.buildDepError "effectful-th"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/effectful-th-1.0.0.3.tar.gz";
      sha256 = "3b4e8fd04657194b3efc983df8ababa06c1671ef1e1469adcdec134b0af0f237";
    });
  }) // {
    package-description-override = "cabal-version:      3.0\r\nbuild-type:         Simple\r\nname:               effectful-th\r\nversion:            1.0.0.3\r\nx-revision: 1\r\nlicense:            BSD-3-Clause\r\nlicense-file:       LICENSE\r\ncategory:           Control\r\nmaintainer:         andrzej@rybczak.net\r\nauthor:             Andrzej Rybczak\r\nsynopsis:           Template Haskell utilities for the effectful library.\r\n\r\ndescription:\r\n  Generate functions for performing operations of dynamically dispatched effects\r\n  via Template Haskell.\r\n\r\nextra-source-files:\r\n  CHANGELOG.md\r\n  README.md\r\n\r\ntested-with: GHC == { 8.10.7, 9.0.2, 9.2.8, 9.4.8, 9.6.5, 9.8.2, 9.10.1 }\r\n\r\nbug-reports:   https://github.com/haskell-effectful/effectful/issues\r\nsource-repository head\r\n  type:     git\r\n  location: https://github.com/haskell-effectful/effectful.git\r\n\r\ncommon language\r\n    ghc-options:        -Wall\r\n                        -Wcompat\r\n                        -Wno-unticked-promoted-constructors\r\n                        -Wmissing-deriving-strategies\r\n                        -Werror=prepositive-qualified-module\r\n\r\n    default-language:   Haskell2010\r\n\r\n    default-extensions: BangPatterns\r\n                        ConstraintKinds\r\n                        DataKinds\r\n                        DeriveFunctor\r\n                        DeriveGeneric\r\n                        DerivingStrategies\r\n                        FlexibleContexts\r\n                        FlexibleInstances\r\n                        GADTs\r\n                        GeneralizedNewtypeDeriving\r\n                        ImportQualifiedPost\r\n                        LambdaCase\r\n                        MultiParamTypeClasses\r\n                        NoStarIsType\r\n                        PolyKinds\r\n                        RankNTypes\r\n                        RecordWildCards\r\n                        RoleAnnotations\r\n                        ScopedTypeVariables\r\n                        StandaloneDeriving\r\n                        TupleSections\r\n                        TypeApplications\r\n                        TypeFamilies\r\n                        TypeOperators\r\n\r\nlibrary\r\n    import:         language\r\n\r\n    build-depends:    base                >= 4.14      && < 5\r\n                    , containers          >= 0.6\r\n                    , effectful-core      >= 1.0.0.0   && < 3.0.0.0\r\n                    , exceptions          >= 0.10.4\r\n                    , template-haskell    >= 2.16      && < 2.24\r\n                    , th-abstraction      >= 0.6       && < 0.8\r\n\r\n    hs-source-dirs:  src\r\n\r\n    exposed-modules: Effectful.TH\r\n\r\ntest-suite th-tests\r\n    import:         language\r\n\r\n    build-depends:    base\r\n                    , effectful-core\r\n                    , effectful-th\r\n\r\n    hs-source-dirs: tests\r\n\r\n    type:           exitcode-stdio-1.0\r\n    main-is:        ThTests.hs\r\n";
  }