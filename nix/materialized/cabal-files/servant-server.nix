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
      identifier = { name = "servant-server"; version = "0.20.3.0"; };
      license = "BSD-3-Clause";
      copyright = "2014-2016 Zalora South East Asia Pte Ltd, 2016-2019 Servant Contributors";
      maintainer = "haskell-servant-maintainers@googlegroups.com";
      author = "Servant Contributors";
      homepage = "http://docs.servant.dev/";
      url = "";
      synopsis = "A family of combinators for defining webservices APIs and serving them";
      description = "A family of combinators for defining webservices APIs and serving them\n.\nYou can learn about the basics in the <http://docs.servant.dev/en/stable/tutorial/index.html tutorial>.\n.\n<https://github.com/haskell-servant/servant/blob/master/servant-server/example/greet.hs Here>\nis a runnable example, with comments, that defines a dummy API and implements\na webserver that serves this API, using this package.\n.\n<https://github.com/haskell-servant/servant/blob/master/servant-server/CHANGELOG.md CHANGELOG>";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          (hsPkgs."constraints" or (errorHandler.buildDepError "constraints"))
          (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
          (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
          (hsPkgs."mtl" or (errorHandler.buildDepError "mtl"))
          (hsPkgs."text" or (errorHandler.buildDepError "text"))
          (hsPkgs."transformers" or (errorHandler.buildDepError "transformers"))
          (hsPkgs."http-api-data" or (errorHandler.buildDepError "http-api-data"))
          (hsPkgs."servant" or (errorHandler.buildDepError "servant"))
          (hsPkgs."base64-bytestring" or (errorHandler.buildDepError "base64-bytestring"))
          (hsPkgs."exceptions" or (errorHandler.buildDepError "exceptions"))
          (hsPkgs."http-media" or (errorHandler.buildDepError "http-media"))
          (hsPkgs."http-types" or (errorHandler.buildDepError "http-types"))
          (hsPkgs."monad-control" or (errorHandler.buildDepError "monad-control"))
          (hsPkgs."network" or (errorHandler.buildDepError "network"))
          (hsPkgs."resourcet" or (errorHandler.buildDepError "resourcet"))
          (hsPkgs."sop-core" or (errorHandler.buildDepError "sop-core"))
          (hsPkgs."tagged" or (errorHandler.buildDepError "tagged"))
          (hsPkgs."transformers-base" or (errorHandler.buildDepError "transformers-base"))
          (hsPkgs."wai" or (errorHandler.buildDepError "wai"))
          (hsPkgs."wai-app-static" or (errorHandler.buildDepError "wai-app-static"))
          (hsPkgs."word8" or (errorHandler.buildDepError "word8"))
        ];
        buildable = true;
      };
      exes = {
        "greet" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."base-compat" or (errorHandler.buildDepError "base-compat"))
            (hsPkgs."servant-server" or (errorHandler.buildDepError "servant-server"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
            (hsPkgs."wai" or (errorHandler.buildDepError "wai"))
            (hsPkgs."aeson" or (errorHandler.buildDepError "aeson"))
            (hsPkgs."warp" or (errorHandler.buildDepError "warp"))
          ];
          buildable = true;
        };
      };
      tests = {
        "spec" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."base-compat" or (errorHandler.buildDepError "base-compat"))
            (hsPkgs."base64-bytestring" or (errorHandler.buildDepError "base64-bytestring"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."http-types" or (errorHandler.buildDepError "http-types"))
            (hsPkgs."mtl" or (errorHandler.buildDepError "mtl"))
            (hsPkgs."resourcet" or (errorHandler.buildDepError "resourcet"))
            (hsPkgs."safe" or (errorHandler.buildDepError "safe"))
            (hsPkgs."servant" or (errorHandler.buildDepError "servant"))
            (hsPkgs."servant-server" or (errorHandler.buildDepError "servant-server"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
            (hsPkgs."wai" or (errorHandler.buildDepError "wai"))
            (hsPkgs."aeson" or (errorHandler.buildDepError "aeson"))
            (hsPkgs."directory" or (errorHandler.buildDepError "directory"))
            (hsPkgs."hspec" or (errorHandler.buildDepError "hspec"))
            (hsPkgs."hspec-wai" or (errorHandler.buildDepError "hspec-wai"))
            (hsPkgs."should-not-typecheck" or (errorHandler.buildDepError "should-not-typecheck"))
            (hsPkgs."temporary" or (errorHandler.buildDepError "temporary"))
            (hsPkgs."wai-extra" or (errorHandler.buildDepError "wai-extra"))
          ];
          build-tools = [
            (hsPkgs.pkgsBuildBuild.hspec-discover.components.exes.hspec-discover or (pkgs.pkgsBuildBuild.hspec-discover or (errorHandler.buildToolDepError "hspec-discover:hspec-discover")))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/servant-server-0.20.3.0.tar.gz";
      sha256 = "30560af5d2597ae361711de8302617de3bfb3e01f10180ff48a331bbe8e49915";
    });
  }) // {
    package-description-override = "cabal-version:      3.0\r\nname:               servant-server\r\nversion:            0.20.3.0\r\nx-revision: 3\r\nsynopsis:\r\n  A family of combinators for defining webservices APIs and serving them\r\n\r\ncategory:           Servant, Web\r\ndescription:\r\n  A family of combinators for defining webservices APIs and serving them\r\n  .\r\n  You can learn about the basics in the <http://docs.servant.dev/en/stable/tutorial/index.html tutorial>.\r\n  .\r\n  <https://github.com/haskell-servant/servant/blob/master/servant-server/example/greet.hs Here>\r\n  is a runnable example, with comments, that defines a dummy API and implements\r\n  a webserver that serves this API, using this package.\r\n  .\r\n  <https://github.com/haskell-servant/servant/blob/master/servant-server/CHANGELOG.md CHANGELOG>\r\n\r\nhomepage:           http://docs.servant.dev/\r\nbug-reports:        http://github.com/haskell-servant/servant/issues\r\nlicense:            BSD-3-Clause\r\nlicense-file:       LICENSE\r\nauthor:             Servant Contributors\r\nmaintainer:         haskell-servant-maintainers@googlegroups.com\r\ncopyright:\r\n  2014-2016 Zalora South East Asia Pte Ltd, 2016-2019 Servant Contributors\r\n\r\nbuild-type:         Simple\r\ntested-with:        GHC ==9.2.8 || ==9.4.8 || ==9.6.6 || ==9.8.4 || ==9.10.1 || ==9.12.1\r\n\r\nextra-source-files:\r\n  CHANGELOG.md\r\n  README.md\r\n\r\nsource-repository head\r\n  type:     git\r\n  location: http://github.com/haskell-servant/servant.git\r\n\r\ncommon extensions\r\n  default-extensions:\r\n    AllowAmbiguousTypes\r\n    ConstraintKinds\r\n    DataKinds\r\n    DeriveAnyClass\r\n    DeriveDataTypeable\r\n    DeriveFunctor\r\n    DeriveGeneric\r\n    DerivingStrategies\r\n    DerivingVia\r\n    DuplicateRecordFields\r\n    EmptyDataDecls\r\n    ExplicitNamespaces\r\n    FlexibleContexts\r\n    FlexibleInstances\r\n    FunctionalDependencies\r\n    GADTs\r\n    GeneralizedNewtypeDeriving\r\n    InstanceSigs\r\n    KindSignatures\r\n    LambdaCase\r\n    MultiParamTypeClasses\r\n    NamedFieldPuns\r\n    NoStarIsType\r\n    OverloadedLabels\r\n    OverloadedStrings\r\n    PackageImports\r\n    PolyKinds\r\n    QuantifiedConstraints\r\n    RankNTypes\r\n    RecordWildCards\r\n    ScopedTypeVariables\r\n    TupleSections\r\n    TypeApplications\r\n    TypeFamilies\r\n    TypeOperators\r\n    UndecidableInstances\r\n    ViewPatterns\r\n\r\n  default-language:   Haskell2010\r\n\r\ncommon ghc-options\r\n  ghc-options:\r\n    -Wall -Wcompat -Widentities -Wincomplete-record-updates\r\n    -Wincomplete-uni-patterns -Wpartial-fields -Wredundant-constraints\r\n    -fhide-source-paths -Wno-unused-do-bind -fdicts-strict\r\n    -Wno-unticked-promoted-constructors -Werror=unused-imports\r\n    -Wunused-packages\r\n\r\nlibrary\r\n  import:          extensions\r\n  import:          ghc-options\r\n  exposed-modules:\r\n    Servant\r\n    Servant.Server\r\n    Servant.Server.Experimental.Auth\r\n    Servant.Server.Generic\r\n    Servant.Server.Internal\r\n    Servant.Server.Internal.BasicAuth\r\n    Servant.Server.Internal.Context\r\n    Servant.Server.Internal.Delayed\r\n    Servant.Server.Internal.DelayedIO\r\n    Servant.Server.Internal.ErrorFormatter\r\n    Servant.Server.Internal.Handler\r\n    Servant.Server.Internal.ResponseRender\r\n    Servant.Server.Internal.RouteResult\r\n    Servant.Server.Internal.Router\r\n    Servant.Server.Internal.RoutingApplication\r\n    Servant.Server.Internal.ServerError\r\n    Servant.Server.StaticFiles\r\n    Servant.Server.UVerb\r\n\r\n  -- deprecated\r\n  exposed-modules: Servant.Utils.StaticFiles\r\n\r\n  -- Bundled with GHC: Lower bound to not force re-installs\r\n  -- text and mtl are bundled starting with GHC-8.4\r\n  build-depends:\r\n    , base          >= 4.16.4.0 && < 4.22\r\n    , bytestring    >=0.11 && <0.13\r\n    , constraints   >=0.2      && <0.15\r\n    , containers    >=0.6.5.1  && <0.9\r\n    , filepath      >=1.4.1.1  && <1.6\r\n    , mtl           ^>=2.2.2   || ^>=2.3.1\r\n    , text          >=1.2.3.0  && <2.2\r\n    , transformers  >=0.5.2.0  && <0.7\r\n\r\n  -- Servant dependencies\r\n  -- strict dependency as we re-export 'servant' things.\r\n  build-depends:\r\n    , http-api-data  >=0.4.1 && <0.8\r\n    , servant        >=0.20.3 && <0.21\r\n\r\n  -- Other dependencies: Lower bound around what is in the latest Stackage LTS.\r\n  -- Here can be exceptions if we really need features from the newer versions.\r\n  build-depends:\r\n    , base64-bytestring  >=1.0.0.1 && <1.3\r\n    , exceptions         >=0.10.0  && <0.11\r\n    , http-media         >=0.7.1.3 && <0.9\r\n    , http-types         >=0.12.2  && <0.13\r\n    , monad-control      >=1.0.2.3 && <1.1\r\n    , network            >=2.8     && <3.3\r\n    , resourcet          >=1.2.2   && <1.4\r\n    , sop-core           >=0.4.0.0 && <0.6\r\n    , tagged             >=0.8.6   && <0.9\r\n    , transformers-base  >=0.4.5.2 && <0.5\r\n    , wai                >=3.2.2.1 && <3.3\r\n    , wai-app-static     >=3.1.6.2 && <3.3\r\n    , word8              >=0.1.3   && <0.2\r\n\r\n  hs-source-dirs:  src\r\n\r\nexecutable greet\r\n  import:         extensions\r\n  import:         ghc-options\r\n  main-is:        greet.hs\r\n  hs-source-dirs: example\r\n  build-depends:\r\n    , base\r\n    , base-compat\r\n    , servant-server\r\n    , text\r\n    , wai\r\n\r\n  build-depends:\r\n    , aeson  >=1.4.1.0 && <3\r\n    , warp   >=3.2.25  && <3.5\r\n\r\ntest-suite spec\r\n  import:             extensions\r\n  import:             ghc-options\r\n  type:               exitcode-stdio-1.0\r\n  hs-source-dirs:     test\r\n  main-is:            Spec.hs\r\n  other-modules:\r\n    Servant.ArbitraryMonadServerSpec\r\n    Servant.HoistSpec\r\n    Servant.Server.ErrorSpec\r\n    Servant.Server.Internal.ContextSpec\r\n    Servant.Server.Internal.RoutingApplicationSpec\r\n    Servant.Server.RouterSpec\r\n    Servant.Server.StaticFilesSpec\r\n    Servant.Server.StreamingSpec\r\n    Servant.Server.UsingContextSpec\r\n    Servant.Server.UsingContextSpec.TestCombinators\r\n    Servant.ServerSpec\r\n\r\n  -- Dependencies inherited from the library. No need to specify bounds.\r\n  build-depends:\r\n    , base\r\n    , base-compat\r\n    , base64-bytestring\r\n    , bytestring\r\n    , http-types\r\n    , mtl\r\n    , resourcet\r\n    , safe\r\n    , servant\r\n    , servant-server\r\n    , text\r\n    , wai\r\n\r\n  -- Additional dependencies\r\n  build-depends:\r\n    , aeson                 >=1.4.1.0  && <3\r\n    , directory             >=1.3.0.0  && <1.4\r\n    , hspec                 >=2.6.0    && <2.12\r\n    , hspec-wai             >=0.10.1   && <0.12\r\n    , should-not-typecheck  >=2.1.0    && <2.2\r\n    , temporary             >=1.3      && <1.4\r\n    , wai-extra             >=3.0.24.3 && <3.2\r\n\r\n  build-tool-depends: hspec-discover:hspec-discover >=2.6.0 && <2.12\r\n";
  }