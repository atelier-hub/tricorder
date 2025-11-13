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
      identifier = { name = "effectful-core"; version = "2.6.1.0"; };
      license = "BSD-3-Clause";
      copyright = "";
      maintainer = "andrzej@rybczak.net";
      author = "Andrzej Rybczak";
      homepage = "";
      url = "";
      synopsis = "An easy to use, performant extensible effects library.";
      description = "An easy to use, performant extensible effects library with seamless\nintegration with the existing Haskell ecosystem.\n.\nThis library provides core definitions with a minimal dependency\nfootprint. See the @<https://hackage.haskell.org/package/effectful effectful>@\npackage for the \"batteries-included\" variant.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
          (hsPkgs."deepseq" or (errorHandler.buildDepError "deepseq"))
          (hsPkgs."exceptions" or (errorHandler.buildDepError "exceptions"))
          (hsPkgs."mtl" or (errorHandler.buildDepError "mtl"))
          (hsPkgs."monad-control" or (errorHandler.buildDepError "monad-control"))
          (hsPkgs."primitive" or (errorHandler.buildDepError "primitive"))
          (hsPkgs."strict-mutable-base" or (errorHandler.buildDepError "strict-mutable-base"))
          (hsPkgs."transformers-base" or (errorHandler.buildDepError "transformers-base"))
          (hsPkgs."unliftio-core" or (errorHandler.buildDepError "unliftio-core"))
        ];
        buildable = true;
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/effectful-core-2.6.1.0.tar.gz";
      sha256 = "9c679af666dafb02220630a4dd389c24beb6e9c4fdbf1ba09e6601933db869f2";
    });
  }) // {
    package-description-override = "cabal-version:      3.0\nbuild-type:         Simple\nname:               effectful-core\nversion:            2.6.1.0\nlicense:            BSD-3-Clause\nlicense-file:       LICENSE\ncategory:           Control\nmaintainer:         andrzej@rybczak.net\nauthor:             Andrzej Rybczak\nsynopsis:           An easy to use, performant extensible effects library.\n\ndescription:\n  An easy to use, performant extensible effects library with seamless\n  integration with the existing Haskell ecosystem.\n  .\n  This library provides core definitions with a minimal dependency\n  footprint. See the @<https://hackage.haskell.org/package/effectful effectful>@\n  package for the \"batteries-included\" variant.\n\nextra-source-files:\n  CHANGELOG.md\n  README.md\n\ntested-with: GHC == { 8.10.7, 9.0.2, 9.2.8, 9.4.8, 9.6.7, 9.8.4, 9.10.2, 9.12.2, 9.14.1 }\n\nbug-reports:   https://github.com/haskell-effectful/effectful/issues\nsource-repository head\n  type:     git\n  location: https://github.com/haskell-effectful/effectful.git\n\ncommon language\n    ghc-options:        -Wall\n                        -Wcompat\n                        -Wno-unticked-promoted-constructors\n                        -Wmissing-deriving-strategies\n                        -Werror=prepositive-qualified-module\n\n    default-language:   Haskell2010\n\n    default-extensions: BangPatterns\n                        ConstraintKinds\n                        DataKinds\n                        DeriveFunctor\n                        DeriveGeneric\n                        DerivingStrategies\n                        FlexibleContexts\n                        FlexibleInstances\n                        GADTs\n                        GeneralizedNewtypeDeriving\n                        ImportQualifiedPost\n                        LambdaCase\n                        MultiParamTypeClasses\n                        NoStarIsType\n                        PolyKinds\n                        RankNTypes\n                        RoleAnnotations\n                        ScopedTypeVariables\n                        StandaloneDeriving\n                        TupleSections\n                        TypeApplications\n                        TypeFamilies\n                        TypeOperators\n                        UndecidableInstances\n\nlibrary\n    import:         language\n\n    ghc-options:    -O2\n\n    build-depends:    base                >= 4.14      && < 5\n                    , containers          >= 0.6\n                    , deepseq             >= 1.2\n                    , exceptions          >= 0.10.4\n                    , mtl                 >= 2.2.1\n                    , monad-control       >= 1.0.3\n                    , primitive           >= 0.7.3.0\n                    , strict-mutable-base >= 1.1.0.0\n                    , transformers-base   >= 0.4.6\n                    , unliftio-core       >= 0.2.0.1\n\n    hs-source-dirs:  src\n\n    if impl(ghc < 9)\n      c-sources:     cbits/utils.c\n\n    exposed-modules: Effectful\n                     Effectful.Dispatch.Dynamic\n                     Effectful.Dispatch.Static\n                     Effectful.Dispatch.Static.Primitive\n                     Effectful.Dispatch.Static.Unsafe\n                     Effectful.Error.Dynamic\n                     Effectful.Error.Static\n                     Effectful.Exception\n                     Effectful.Fail\n                     Effectful.Internal.Effect\n                     Effectful.Internal.Env\n                     Effectful.Internal.MTL\n                     Effectful.Internal.Monad\n                     Effectful.Internal.Unlift\n                     Effectful.Internal.Utils\n                     Effectful.Labeled\n                     Effectful.Labeled.Error\n                     Effectful.Labeled.Reader\n                     Effectful.Labeled.State\n                     Effectful.Labeled.Writer\n                     Effectful.NonDet\n                     Effectful.Prim\n                     Effectful.Provider\n                     Effectful.Provider.List\n                     Effectful.Reader.Dynamic\n                     Effectful.Reader.Static\n                     Effectful.State.Dynamic\n                     Effectful.State.Static.Local\n                     Effectful.State.Static.Shared\n                     Effectful.Writer.Dynamic\n                     Effectful.Writer.Static.Local\n                     Effectful.Writer.Static.Shared\n";
  }