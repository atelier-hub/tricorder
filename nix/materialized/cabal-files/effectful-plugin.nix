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
    flags = { timing = false; verbose = false; };
    package = {
      specVersion = "3.0";
      identifier = { name = "effectful-plugin"; version = "2.0.0.1"; };
      license = "BSD-3-Clause";
      copyright = "";
      maintainer = "andrzej@rybczak.net";
      author = "Andrzej Rybczak";
      homepage = "";
      url = "";
      synopsis = "A GHC plugin for improving disambiguation of effects.";
      description = "Instruct GHC to do a better job with disambiguation of effects.\n.\nSee the README for more information.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
          (hsPkgs."ghc" or (errorHandler.buildDepError "ghc"))
        ];
        buildable = true;
      };
      tests = {
        "plugin-tests" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."effectful-core" or (errorHandler.buildDepError "effectful-core"))
            (hsPkgs."effectful-plugin" or (errorHandler.buildDepError "effectful-plugin"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/effectful-plugin-2.0.0.1.tar.gz";
      sha256 = "ccfafcb585b290a7b23d700cfe9f9b2d5e14079d89a4b2076e5cdc77ad4f174c";
    });
  }) // {
    package-description-override = "cabal-version:      3.0\nbuild-type:         Simple\nname:               effectful-plugin\nversion:            2.0.0.1\nlicense:            BSD-3-Clause\nlicense-file:       LICENSE\ncategory:           Control\nmaintainer:         andrzej@rybczak.net\nauthor:             Andrzej Rybczak\nsynopsis:           A GHC plugin for improving disambiguation of effects.\n\ndescription:\n  Instruct GHC to do a better job with disambiguation of effects.\n  .\n  See the README for more information.\n\nextra-source-files: CHANGELOG.md\n                    README.md\n\ntested-with: GHC == { 9.4.8, 9.6.7, 9.8.4, 9.10.2, 9.12.2, 9.14.1 }\n\nbug-reports:   https://github.com/haskell-effectful/effectful/issues\nsource-repository head\n  type:     git\n  location: https://github.com/haskell-effectful/effectful.git\n\nflag timing\n    description: Show timing information\n    default: False\n\nflag verbose\n    description: Trace plugin execution\n    default: False\n\ncommon language\n    ghc-options:        -Wall\n                        -Wcompat\n                        -Wno-unticked-promoted-constructors\n                        -Wmissing-deriving-strategies\n                        -Werror=prepositive-qualified-module\n\n    default-language:   Haskell2010\n\n    default-extensions: BangPatterns\n                        ConstraintKinds\n                        DataKinds\n                        DeriveFunctor\n                        DeriveGeneric\n                        DerivingStrategies\n                        DuplicateRecordFields\n                        FlexibleContexts\n                        FlexibleInstances\n                        GADTs\n                        GeneralizedNewtypeDeriving\n                        ImportQualifiedPost\n                        LambdaCase\n                        MultiParamTypeClasses\n                        NoStarIsType\n                        PolyKinds\n                        RankNTypes\n                        RecordWildCards\n                        RoleAnnotations\n                        ScopedTypeVariables\n                        StandaloneDeriving\n                        TupleSections\n                        TypeApplications\n                        TypeFamilies\n                        TypeOperators\n                        UndecidableInstances\n\n    if impl(ghc >= 9.4)\n      default-extensions: NoFieldSelectors\n                        , OverloadedRecordDot\n\nlibrary\n    import:         language\n\n    if flag(timing)\n      cpp-options: -DTIMING\n\n    if flag(verbose)\n      cpp-options: -DVERBOSE\n\n    build-depends:    base                >= 4.16      && < 5\n                    , containers          >= 0.5\n                    , ghc                 >= 9.4       && < 9.15\n\n    hs-source-dirs: src\n\n    exposed-modules: Effectful.Plugin\n\ntest-suite plugin-tests\n    import:         language\n\n    ghc-options:    -fplugin=Effectful.Plugin\n\n    build-depends:    base\n                    , effectful-core\n                    , effectful-plugin\n\n    hs-source-dirs: tests\n\n    type:           exitcode-stdio-1.0\n    main-is:        PluginTests.hs\n";
  }