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
      identifier = { name = "servant-client"; version = "0.20.3.0"; };
      license = "BSD-3-Clause";
      copyright = "2014-2016 Zalora South East Asia Pte Ltd, 2016-2019 Servant Contributors";
      maintainer = "haskell-servant-maintainers@googlegroups.com";
      author = "Servant Contributors";
      homepage = "http://docs.servant.dev/";
      url = "";
      synopsis = "Automatic derivation of querying functions for servant";
      description = "This library lets you derive automatically Haskell functions that\nlet you query each endpoint of a <http://hackage.haskell.org/package/servant servant> webservice.\n.\nSee <http://docs.servant.dev/en/stable/tutorial/Client.html the client section of the tutorial>.\n.\n<https://github.com/haskell-servant/servant/blob/master/servant-client/CHANGELOG.md CHANGELOG>";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
          (hsPkgs."deepseq" or (errorHandler.buildDepError "deepseq"))
          (hsPkgs."mtl" or (errorHandler.buildDepError "mtl"))
          (hsPkgs."stm" or (errorHandler.buildDepError "stm"))
          (hsPkgs."time" or (errorHandler.buildDepError "time"))
          (hsPkgs."transformers" or (errorHandler.buildDepError "transformers"))
          (hsPkgs."servant" or (errorHandler.buildDepError "servant"))
          (hsPkgs."servant-client-core" or (errorHandler.buildDepError "servant-client-core"))
          (hsPkgs."base-compat" or (errorHandler.buildDepError "base-compat"))
          (hsPkgs."exceptions" or (errorHandler.buildDepError "exceptions"))
          (hsPkgs."http-client" or (errorHandler.buildDepError "http-client"))
          (hsPkgs."http-media" or (errorHandler.buildDepError "http-media"))
          (hsPkgs."http-types" or (errorHandler.buildDepError "http-types"))
          (hsPkgs."kan-extensions" or (errorHandler.buildDepError "kan-extensions"))
          (hsPkgs."monad-control" or (errorHandler.buildDepError "monad-control"))
          (hsPkgs."semigroupoids" or (errorHandler.buildDepError "semigroupoids"))
          (hsPkgs."transformers-base" or (errorHandler.buildDepError "transformers-base"))
        ];
        buildable = true;
      };
      tests = {
        "spec" = {
          depends = [
            (hsPkgs."aeson" or (errorHandler.buildDepError "aeson"))
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."base-compat" or (errorHandler.buildDepError "base-compat"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."http-api-data" or (errorHandler.buildDepError "http-api-data"))
            (hsPkgs."http-client" or (errorHandler.buildDepError "http-client"))
            (hsPkgs."http-types" or (errorHandler.buildDepError "http-types"))
            (hsPkgs."mtl" or (errorHandler.buildDepError "mtl"))
            (hsPkgs."servant-client" or (errorHandler.buildDepError "servant-client"))
            (hsPkgs."servant-client-core" or (errorHandler.buildDepError "servant-client-core"))
            (hsPkgs."sop-core" or (errorHandler.buildDepError "sop-core"))
            (hsPkgs."generics-sop" or (errorHandler.buildDepError "generics-sop"))
            (hsPkgs."stm" or (errorHandler.buildDepError "stm"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
            (hsPkgs."transformers" or (errorHandler.buildDepError "transformers"))
            (hsPkgs."wai" or (errorHandler.buildDepError "wai"))
            (hsPkgs."warp" or (errorHandler.buildDepError "warp"))
            (hsPkgs."entropy" or (errorHandler.buildDepError "entropy"))
            (hsPkgs."hspec" or (errorHandler.buildDepError "hspec"))
            (hsPkgs."HUnit" or (errorHandler.buildDepError "HUnit"))
            (hsPkgs."network" or (errorHandler.buildDepError "network"))
            (hsPkgs."QuickCheck" or (errorHandler.buildDepError "QuickCheck"))
            (hsPkgs."servant" or (errorHandler.buildDepError "servant"))
            (hsPkgs."servant-server" or (errorHandler.buildDepError "servant-server"))
          ];
          build-tools = [
            (hsPkgs.pkgsBuildBuild.hspec-discover.components.exes.hspec-discover or (pkgs.pkgsBuildBuild.hspec-discover or (errorHandler.buildToolDepError "hspec-discover:hspec-discover")))
          ];
          buildable = if compiler.isGhcjs && true then false else true;
        };
        "readme" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."http-client" or (errorHandler.buildDepError "http-client"))
            (hsPkgs."markdown-unlit" or (errorHandler.buildDepError "markdown-unlit"))
            (hsPkgs."servant" or (errorHandler.buildDepError "servant"))
            (hsPkgs."servant-client" or (errorHandler.buildDepError "servant-client"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
          ];
          build-tools = [
            (hsPkgs.pkgsBuildBuild.markdown-unlit.components.exes.markdown-unlit or (pkgs.pkgsBuildBuild.markdown-unlit or (errorHandler.buildToolDepError "markdown-unlit:markdown-unlit")))
          ];
          buildable = if compiler.isGhcjs && true then false else true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/servant-client-0.20.3.0.tar.gz";
      sha256 = "9667bc4a1aa3ca672d6322721288cbc924429582d9fd3197c8b1dab25f8fb54f";
    });
  }) // {
    package-description-override = "cabal-version:      3.0\r\nname:               servant-client\r\nversion:            0.20.3.0\r\nx-revision: 2\r\nsynopsis:           Automatic derivation of querying functions for servant\r\ncategory:           Servant, Web\r\ndescription:\r\n  This library lets you derive automatically Haskell functions that\r\n  let you query each endpoint of a <http://hackage.haskell.org/package/servant servant> webservice.\r\n  .\r\n  See <http://docs.servant.dev/en/stable/tutorial/Client.html the client section of the tutorial>.\r\n  .\r\n  <https://github.com/haskell-servant/servant/blob/master/servant-client/CHANGELOG.md CHANGELOG>\r\n\r\nhomepage:           http://docs.servant.dev/\r\nbug-reports:        http://github.com/haskell-servant/servant/issues\r\nlicense:            BSD-3-Clause\r\nlicense-file:       LICENSE\r\nauthor:             Servant Contributors\r\nmaintainer:         haskell-servant-maintainers@googlegroups.com\r\ncopyright:\r\n  2014-2016 Zalora South East Asia Pte Ltd, 2016-2019 Servant Contributors\r\n\r\nbuild-type:         Simple\r\ntested-with:        GHC ==9.2.8 || ==9.4.8 || ==9.6.6 || ==9.8.4 || ==9.10.1 || ==9.12.1\r\n\r\nextra-source-files:\r\n  CHANGELOG.md\r\n  README.md\r\n\r\nsource-repository head\r\n  type:     git\r\n  location: http://github.com/haskell-servant/servant.git\r\n\r\ncommon extensions\r\n  default-extensions:\r\n    AllowAmbiguousTypes\r\n    ConstraintKinds\r\n    DataKinds\r\n    DeriveAnyClass\r\n    DeriveDataTypeable\r\n    DeriveFunctor\r\n    DeriveGeneric\r\n    DerivingStrategies\r\n    DerivingVia\r\n    DuplicateRecordFields\r\n    ExplicitNamespaces\r\n    FlexibleContexts\r\n    FlexibleInstances\r\n    FunctionalDependencies\r\n    GADTs\r\n    GeneralizedNewtypeDeriving\r\n    InstanceSigs\r\n    KindSignatures\r\n    LambdaCase\r\n    MultiParamTypeClasses\r\n    NamedFieldPuns\r\n    NoStarIsType\r\n    OverloadedLabels\r\n    OverloadedStrings\r\n    PackageImports\r\n    PolyKinds\r\n    QuantifiedConstraints\r\n    RankNTypes\r\n    RecordWildCards\r\n    ScopedTypeVariables\r\n    StrictData\r\n    TupleSections\r\n    TypeApplications\r\n    TypeFamilies\r\n    TypeOperators\r\n    UndecidableInstances\r\n    ViewPatterns\r\n\r\n  default-language:   Haskell2010\r\n\r\ncommon ghc-options\r\n  ghc-options:\r\n    -Wall -Wcompat -Widentities -Wincomplete-record-updates\r\n    -Wincomplete-uni-patterns -Wpartial-fields -Wredundant-constraints\r\n    -fhide-source-paths -Wno-unused-do-bind -fdicts-strict\r\n    -Wno-unticked-promoted-constructors -Werror=unused-imports\r\n    -Wunused-packages\r\n\r\nlibrary\r\n  import:          extensions\r\n  import:          ghc-options\r\n  exposed-modules:\r\n    Servant.Client\r\n    Servant.Client.Internal.HttpClient\r\n    Servant.Client.Internal.HttpClient.Streaming\r\n    Servant.Client.Streaming\r\n\r\n  -- Bundled with GHC: Lower bound to not force re-installs\r\n  -- text and mtl are bundled starting with GHC-8.4\r\n  build-depends:\r\n    , base          >= 4.16.4.0 && < 4.22\r\n    , bytestring    >=0.11 && <0.13\r\n    , containers    >=0.6.5.1  && <0.9\r\n    , deepseq       >=1.4.2.0  && <1.6\r\n    , mtl           ^>=2.2.2   || ^>=2.3.1\r\n    , stm           >=2.4.5.1  && <2.6\r\n    , time          >=1.6.0.1  && <1.15\r\n    , transformers  >=0.5.2.0  && <0.7\r\n\r\n  -- Servant dependencies.\r\n  -- Strict dependency on `servant-client-core` as we re-export things.\r\n  build-depends:\r\n    , servant              >=0.20.3 && <0.21\r\n    , servant-client-core  >=0.20.3 && <0.21\r\n\r\n  -- Other dependencies: Lower bound around what is in the latest Stackage LTS.\r\n  -- Here can be exceptions if we really need features from the newer versions.\r\n  build-depends:\r\n    , base-compat          >=0.10.5   && <0.15\r\n    , exceptions           >=0.10.0   && <0.11\r\n    , http-client          >=0.5.13.1 && <0.8\r\n    , http-media           >=0.7.1.3  && <0.9\r\n    , http-types           >=0.12.2   && <0.13\r\n    , kan-extensions       >=5.2      && <5.3\r\n    , monad-control        >=1.0.2.3  && <1.1\r\n    , semigroupoids        >=5.3.1    && <6.1\r\n    , transformers-base    >=0.4.5.2  && <0.5\r\n\r\n  hs-source-dirs:  src\r\n\r\ntest-suite spec\r\n  import:             extensions\r\n  import:             ghc-options\r\n  type:               exitcode-stdio-1.0\r\n  ghc-options:        -Wall -rtsopts -threaded \"-with-rtsopts=-T -N2\"\r\n\r\n  if impl(ghcjs)\r\n    buildable: False\r\n\r\n  hs-source-dirs:     test\r\n  main-is:            Spec.hs\r\n  other-modules:\r\n    Servant.BasicAuthSpec\r\n    Servant.BrokenSpec\r\n    Servant.ClientTestUtils\r\n    Servant.ConnectionErrorSpec\r\n    Servant.FailSpec\r\n    Servant.GenAuthSpec\r\n    Servant.GenericSpec\r\n    Servant.HoistClientSpec\r\n    Servant.MiddlewareSpec\r\n    Servant.StreamSpec\r\n    Servant.SuccessSpec\r\n    Servant.WrappedApiSpec\r\n\r\n  -- Dependencies inherited from the library. No need to specify bounds.\r\n  build-depends:\r\n    , aeson\r\n    , base\r\n    , base-compat\r\n    , bytestring\r\n    , http-api-data\r\n    , http-client\r\n    , http-types\r\n    , mtl\r\n    , servant-client\r\n    , servant-client-core\r\n    , sop-core\r\n    , generics-sop\r\n    , stm\r\n    , text\r\n    , transformers\r\n    , wai\r\n    , warp\r\n\r\n  -- Additional dependencies\r\n  build-depends:\r\n    , entropy         >=0.4.1.3  && <0.5\r\n    , hspec           >=2.6.0    && <2.12\r\n    , HUnit           >=1.6.0.0  && <1.7\r\n    , network         >=2.8.0.0  && <3.3\r\n    , QuickCheck      >=2.12.6.1 && <2.17\r\n    , servant         >=0.20.2   && <0.21\r\n    , servant-server  >=0.20.2   && <0.21\r\n\r\n  build-tool-depends: hspec-discover:hspec-discover >=2.6.0 && <2.12\r\n\r\ntest-suite readme\r\n  import:             extensions\r\n  import:             ghc-options\r\n  type:               exitcode-stdio-1.0\r\n  main-is:            README.lhs\r\n  build-depends:\r\n    , base\r\n    , http-client\r\n    , markdown-unlit\r\n    , servant\r\n    , servant-client\r\n    , text\r\n\r\n  build-tool-depends: markdown-unlit:markdown-unlit\r\n  ghc-options:        -pgmL markdown-unlit\r\n\r\n  if impl(ghcjs)\r\n    buildable: False\r\n";
  }