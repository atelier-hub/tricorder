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
      identifier = { name = "servant"; version = "0.20.3.0"; };
      license = "BSD-3-Clause";
      copyright = "2014-2016 Zalora South East Asia Pte Ltd, 2016-2019 Servant Contributors";
      maintainer = "haskell-servant-maintainers@googlegroups.com";
      author = "Servant Contributors";
      homepage = "http://docs.servant.dev/";
      url = "";
      synopsis = "A family of combinators for defining webservices APIs";
      description = "A family of combinators for defining webservices APIs and serving them\n.\nYou can learn about the basics in the <http://docs.servant.dev/en/stable/tutorial/index.html tutorial>.\n.\n<https://github.com/haskell-servant/servant/blob/master/servant/CHANGELOG.md CHANGELOG>";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          (hsPkgs."constraints" or (errorHandler.buildDepError "constraints"))
          (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
          (hsPkgs."mtl" or (errorHandler.buildDepError "mtl"))
          (hsPkgs."sop-core" or (errorHandler.buildDepError "sop-core"))
          (hsPkgs."generics-sop" or (errorHandler.buildDepError "generics-sop"))
          (hsPkgs."text" or (errorHandler.buildDepError "text"))
          (hsPkgs."transformers" or (errorHandler.buildDepError "transformers"))
          (hsPkgs."http-api-data" or (errorHandler.buildDepError "http-api-data"))
          (hsPkgs."singleton-bool" or (errorHandler.buildDepError "singleton-bool"))
          (hsPkgs."aeson" or (errorHandler.buildDepError "aeson"))
          (hsPkgs."attoparsec" or (errorHandler.buildDepError "attoparsec"))
          (hsPkgs."bifunctors" or (errorHandler.buildDepError "bifunctors"))
          (hsPkgs."case-insensitive" or (errorHandler.buildDepError "case-insensitive"))
          (hsPkgs."deepseq" or (errorHandler.buildDepError "deepseq"))
          (hsPkgs."http-media" or (errorHandler.buildDepError "http-media"))
          (hsPkgs."http-types" or (errorHandler.buildDepError "http-types"))
          (hsPkgs."mmorph" or (errorHandler.buildDepError "mmorph"))
          (hsPkgs."network-uri" or (errorHandler.buildDepError "network-uri"))
          (hsPkgs."QuickCheck" or (errorHandler.buildDepError "QuickCheck"))
          (hsPkgs."vault" or (errorHandler.buildDepError "vault"))
        ];
        buildable = true;
      };
      tests = {
        "spec" = {
          depends = [
            (hsPkgs."aeson" or (errorHandler.buildDepError "aeson"))
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."http-media" or (errorHandler.buildDepError "http-media"))
            (hsPkgs."mtl" or (errorHandler.buildDepError "mtl"))
            (hsPkgs."network-uri" or (errorHandler.buildDepError "network-uri"))
            (hsPkgs."servant" or (errorHandler.buildDepError "servant"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
            (hsPkgs."hspec" or (errorHandler.buildDepError "hspec"))
            (hsPkgs."QuickCheck" or (errorHandler.buildDepError "QuickCheck"))
            (hsPkgs."quickcheck-instances" or (errorHandler.buildDepError "quickcheck-instances"))
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
      url = "http://hackage.haskell.org/package/servant-0.20.3.0.tar.gz";
      sha256 = "f273e65c8f6cc6ddfa204c8d1d0bc5b7e258cec288ca5b2a2e57fadb31bf6602";
    });
  }) // {
    package-description-override = "cabal-version:      3.0\r\nname:               servant\r\nversion:            0.20.3.0\r\nx-revision: 3\r\nsynopsis:           A family of combinators for defining webservices APIs\r\ncategory:           Servant, Web\r\ndescription:\r\n  A family of combinators for defining webservices APIs and serving them\r\n  .\r\n  You can learn about the basics in the <http://docs.servant.dev/en/stable/tutorial/index.html tutorial>.\r\n  .\r\n  <https://github.com/haskell-servant/servant/blob/master/servant/CHANGELOG.md CHANGELOG>\r\n\r\nhomepage:           http://docs.servant.dev/\r\nbug-reports:        http://github.com/haskell-servant/servant/issues\r\nlicense:            BSD-3-Clause\r\nlicense-file:       LICENSE\r\nauthor:             Servant Contributors\r\nmaintainer:         haskell-servant-maintainers@googlegroups.com\r\ncopyright:\r\n  2014-2016 Zalora South East Asia Pte Ltd, 2016-2019 Servant Contributors\r\n\r\nbuild-type:         Simple\r\ntested-with:        GHC ==9.2.8 || ==9.4.8 || ==9.6.6 || ==9.8.4 || ==9.10.1 || ==9.12.1\r\n\r\nextra-source-files: CHANGELOG.md\r\n\r\nsource-repository head\r\n  type:     git\r\n  location: http://github.com/haskell-servant/servant.git\r\n\r\ncommon extensions\r\n  default-extensions:\r\n    AllowAmbiguousTypes\r\n    ConstraintKinds\r\n    DataKinds\r\n    DeriveAnyClass\r\n    DeriveDataTypeable\r\n    DeriveFunctor\r\n    DeriveGeneric\r\n    DerivingStrategies\r\n    DerivingVia\r\n    DuplicateRecordFields\r\n    ExplicitNamespaces\r\n    FlexibleContexts\r\n    FlexibleInstances\r\n    FunctionalDependencies\r\n    GADTs\r\n    InstanceSigs\r\n    KindSignatures\r\n    LambdaCase\r\n    MultiParamTypeClasses\r\n    NoStarIsType\r\n    OverloadedLabels\r\n    OverloadedStrings\r\n    PackageImports\r\n    PolyKinds\r\n    RankNTypes\r\n    RecordWildCards\r\n    ScopedTypeVariables\r\n    TupleSections\r\n    TypeApplications\r\n    TypeFamilies\r\n    TypeOperators\r\n    UndecidableInstances\r\n    ViewPatterns\r\n\r\n  default-language:   Haskell2010\r\n\r\ncommon ghc-options\r\n  ghc-options:\r\n    -Wall -Wcompat -Widentities -Wincomplete-record-updates\r\n    -Wincomplete-uni-patterns -Wpartial-fields -Wredundant-constraints\r\n    -fhide-source-paths -Wno-unused-do-bind -fdicts-strict\r\n    -Wno-unticked-promoted-constructors -Werror=unused-imports\r\n    -Wunused-packages\r\n\r\nlibrary\r\n  import:          extensions\r\n  import:          ghc-options\r\n  exposed-modules:\r\n    Servant.API\r\n    Servant.API.Alternative\r\n    Servant.API.BasicAuth\r\n    Servant.API.Capture\r\n    Servant.API.ContentTypes\r\n    Servant.API.Description\r\n    Servant.API.Empty\r\n    Servant.API.Experimental.Auth\r\n    Servant.API.Fragment\r\n    Servant.API.Generic\r\n    Servant.API.Header\r\n    Servant.API.Host\r\n    Servant.API.HttpVersion\r\n    Servant.API.IsSecure\r\n    Servant.API.Modifiers\r\n    Servant.API.NamedRoutes\r\n    Servant.API.QueryParam\r\n    Servant.API.QueryString\r\n    Servant.API.Range\r\n    Servant.API.Raw\r\n    Servant.API.RemoteHost\r\n    Servant.API.ReqBody\r\n    Servant.API.ResponseHeaders\r\n    Servant.API.ServerSentEvents\r\n    Servant.API.Status\r\n    Servant.API.Stream\r\n    Servant.API.Sub\r\n    Servant.API.TypeErrors\r\n    Servant.API.TypeLevel\r\n    Servant.API.TypeLevel.List\r\n    Servant.API.UVerb\r\n    Servant.API.MultiVerb\r\n    Servant.API.UVerb.Union\r\n    Servant.API.Vault\r\n    Servant.API.Verbs\r\n    Servant.API.WithNamedContext\r\n    Servant.API.WithResource\r\n\r\n  -- Types\r\n  exposed-modules:\r\n    Servant.Types.SourceT\r\n    Servant.Types.Internal.Response\r\n\r\n  -- Test stuff\r\n  exposed-modules: Servant.Test.ComprehensiveAPI\r\n\r\n  -- Safe links\r\n  exposed-modules: Servant.Links\r\n\r\n  -- Bundled with GHC: Lower bound to not force re-installs\r\n  -- text and mtl are bundled starting with GHC-8.4\r\n  --\r\n  -- note: mtl lower bound is so low because of GHC-7.8\r\n  build-depends:\r\n    , base          >= 4.16.4.0 && <4.22\r\n    , bytestring    >=0.11 && <0.13\r\n    , constraints   >=0.2\r\n    , containers    >=0.6.5.1  && <0.9\r\n    , mtl           ^>=2.2.2   || ^>=2.3.1\r\n    , sop-core      >=0.4.0.0  && <0.6\r\n    , generics-sop  ^>=0.5.1\r\n    , text          >=1.2.3.0  && <2.2\r\n    , transformers  >=0.5.2.0  && <0.7\r\n\r\n  -- We depend (heavily) on the API of these packages:\r\n  -- i.e. re-export, or allow using without direct dependency\r\n  build-depends:\r\n    , http-api-data   >=0.4.1 && <0.8\r\n    , singleton-bool  >=0.1.4 && <0.2\r\n\r\n  -- Other dependencies: Lower bound around what is in the latest Stackage LTS.\r\n  -- Here can be exceptions if we really need features from the newer versions.\r\n  build-depends:\r\n    , aeson             >=1.4.1.0  && <2.3\r\n    , attoparsec        >=0.13.2.2 && <0.15\r\n    , bifunctors        >=5.5.3    && <5.7\r\n    , case-insensitive  >=1.2.0.11 && <1.3\r\n    , deepseq           >=1.4.2.0  && <1.6\r\n    , http-media        >=0.7.1.3  && <0.9\r\n    , http-types        >=0.12.2   && <0.13\r\n    , mmorph            >=1.1.2    && <1.3\r\n    , network-uri       >=2.6.1.0  && <2.7\r\n    , QuickCheck        >=2.12.6.1 && <2.17\r\n    , vault             >=0.3.1.2  && <0.4\r\n\r\n  hs-source-dirs:  src\r\n\r\ntest-suite spec\r\n  import:             extensions\r\n  import:             ghc-options\r\n  type:               exitcode-stdio-1.0\r\n  hs-source-dirs:     test\r\n  main-is:            Spec.hs\r\n  other-modules:\r\n    Servant.API.ContentTypesSpec\r\n    Servant.API.ResponseHeadersSpec\r\n    Servant.API.StreamSpec\r\n    Servant.LinksSpec\r\n\r\n  -- Dependencies inherited from the library. No need to specify bounds.\r\n  build-depends:\r\n    , aeson\r\n    , base\r\n    , bytestring\r\n    , http-media\r\n    , mtl\r\n    , network-uri\r\n    , servant\r\n    , text\r\n\r\n  -- Additional dependencies\r\n  build-depends:\r\n    , hspec                 >=2.6.0    && <2.12\r\n    , QuickCheck            >=2.12.6.1 && <2.17\r\n    , quickcheck-instances  >=0.3.19   && <0.4\r\n\r\n  build-tool-depends: hspec-discover:hspec-discover >=2.6.0 && <2.12\r\n";
  }