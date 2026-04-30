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
      identifier = { name = "servant-client-core"; version = "0.20.3.0"; };
      license = "BSD-3-Clause";
      copyright = "2014-2016 Zalora South East Asia Pte Ltd, 2016-2019 Servant Contributors";
      maintainer = "haskell-servant-maintainers@googlegroups.com";
      author = "Servant Contributors";
      homepage = "http://docs.servant.dev/";
      url = "";
      synopsis = "Core functionality and class for client function generation for servant APIs";
      description = "This library provides backend-agnostic generation of client functions. For\nmore information, see the README.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."attoparsec" or (errorHandler.buildDepError "attoparsec"))
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          (hsPkgs."constraints" or (errorHandler.buildDepError "constraints"))
          (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
          (hsPkgs."deepseq" or (errorHandler.buildDepError "deepseq"))
          (hsPkgs."template-haskell" or (errorHandler.buildDepError "template-haskell"))
          (hsPkgs."text" or (errorHandler.buildDepError "text"))
          (hsPkgs."servant" or (errorHandler.buildDepError "servant"))
          (hsPkgs."aeson" or (errorHandler.buildDepError "aeson"))
          (hsPkgs."base-compat" or (errorHandler.buildDepError "base-compat"))
          (hsPkgs."base64-bytestring" or (errorHandler.buildDepError "base64-bytestring"))
          (hsPkgs."exceptions" or (errorHandler.buildDepError "exceptions"))
          (hsPkgs."free" or (errorHandler.buildDepError "free"))
          (hsPkgs."http-media" or (errorHandler.buildDepError "http-media"))
          (hsPkgs."http-types" or (errorHandler.buildDepError "http-types"))
          (hsPkgs."network-uri" or (errorHandler.buildDepError "network-uri"))
          (hsPkgs."safe" or (errorHandler.buildDepError "safe"))
          (hsPkgs."sop-core" or (errorHandler.buildDepError "sop-core"))
        ];
        buildable = true;
      };
      tests = {
        "spec" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."base-compat" or (errorHandler.buildDepError "base-compat"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."transformers" or (errorHandler.buildDepError "transformers"))
            (hsPkgs."servant" or (errorHandler.buildDepError "servant"))
            (hsPkgs."servant-client-core" or (errorHandler.buildDepError "servant-client-core"))
            (hsPkgs."deepseq" or (errorHandler.buildDepError "deepseq"))
            (hsPkgs."hspec" or (errorHandler.buildDepError "hspec"))
            (hsPkgs."QuickCheck" or (errorHandler.buildDepError "QuickCheck"))
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
      url = "http://hackage.haskell.org/package/servant-client-core-0.20.3.0.tar.gz";
      sha256 = "d653580e988407386cf6042da6a617fd2c7d5dff6149b33730d3434086eb66ef";
    });
  }) // {
    package-description-override = "cabal-version:      3.0\r\nname:               servant-client-core\r\nversion:            0.20.3.0\r\nx-revision: 2\r\nsynopsis:\r\n  Core functionality and class for client function generation for servant APIs\r\n\r\ncategory:           Servant, Web\r\ndescription:\r\n  This library provides backend-agnostic generation of client functions. For\r\n  more information, see the README.\r\n\r\nhomepage:           http://docs.servant.dev/\r\nbug-reports:        http://github.com/haskell-servant/servant/issues\r\nlicense:            BSD-3-Clause\r\nlicense-file:       LICENSE\r\nauthor:             Servant Contributors\r\nmaintainer:         haskell-servant-maintainers@googlegroups.com\r\ncopyright:\r\n  2014-2016 Zalora South East Asia Pte Ltd, 2016-2019 Servant Contributors\r\n\r\nbuild-type:         Simple\r\ntested-with:        GHC ==9.2.8 || ==9.4.8 || ==9.6.6 || ==9.8.4 || ==9.10.1 || ==9.12.1\r\n\r\nextra-source-files:\r\n  CHANGELOG.md\r\n  README.md\r\n\r\nsource-repository head\r\n  type:     git\r\n  location: http://github.com/haskell-servant/servant.git\r\n\r\ncommon extensions\r\n  default-extensions:\r\n    AllowAmbiguousTypes\r\n    ConstraintKinds\r\n    DataKinds\r\n    DeriveAnyClass\r\n    DeriveDataTypeable\r\n    DeriveFunctor\r\n    DeriveGeneric\r\n    DerivingStrategies\r\n    DerivingVia\r\n    DuplicateRecordFields\r\n    ExplicitNamespaces\r\n    FlexibleContexts\r\n    FlexibleInstances\r\n    FunctionalDependencies\r\n    GADTs\r\n    InstanceSigs\r\n    KindSignatures\r\n    LambdaCase\r\n    MultiParamTypeClasses\r\n    NoStarIsType\r\n    OverloadedLabels\r\n    OverloadedStrings\r\n    PackageImports\r\n    PolyKinds\r\n    RankNTypes\r\n    RecordWildCards\r\n    QuantifiedConstraints\r\n    ScopedTypeVariables\r\n    StrictData\r\n    TupleSections\r\n    TypeApplications\r\n    TypeFamilies\r\n    TypeOperators\r\n    UndecidableInstances\r\n    ViewPatterns\r\n\r\n  default-language:   Haskell2010\r\n\r\ncommon ghc-options\r\n  ghc-options:\r\n    -Wall -Wcompat -Widentities -Wincomplete-record-updates\r\n    -Wincomplete-uni-patterns -Wpartial-fields -Wredundant-constraints\r\n    -fhide-source-paths -Wno-unused-do-bind -fdicts-strict\r\n    -Wno-unticked-promoted-constructors -Werror=unused-imports\r\n    -Wunused-packages\r\n\r\nlibrary\r\n  import:          extensions\r\n  import:          ghc-options\r\n  exposed-modules:\r\n    Servant.Client.Core\r\n    Servant.Client.Core.Auth\r\n    Servant.Client.Core.BaseUrl\r\n    Servant.Client.Core.BasicAuth\r\n    Servant.Client.Core.ClientError\r\n    Servant.Client.Core.HasClient\r\n    Servant.Client.Core.Reexport\r\n    Servant.Client.Core.Request\r\n    Servant.Client.Core.Response\r\n    Servant.Client.Core.MultiVerb.ResponseUnrender\r\n    Servant.Client.Core.RunClient\r\n    Servant.Client.Core.ServerSentEvents\r\n    Servant.Client.Free\r\n    Servant.Client.Generic\r\n\r\n  other-modules:   Servant.Client.Core.Internal\r\n\r\n  -- Bundled with GHC: Lower bound to not force re-installs\r\n  -- text and mtl are bundled starting with GHC-8.4\r\n  --\r\n  -- note: mtl lower bound is so low because of GHC-7.8\r\n  build-depends:\r\n    , attoparsec        >= 0.13.2.2 && < 0.15\r\n    , base              >= 4.16.4.0 && < 4.22\r\n    , bytestring        >=0.11 && <0.13\r\n    , constraints       >=0.2      && <0.15\r\n    , containers        >=0.6.5.1  && <0.9\r\n    , deepseq           >=1.4.2.0  && <1.6\r\n    , template-haskell  >=2.11.1.0 && <2.24\r\n    , text              >=1.2.3.0  && <2.2\r\n\r\n  -- Servant dependencies\r\n  build-depends:   servant >=0.20.3\r\n\r\n  -- Other dependencies: Lower bound around what is in the latest Stackage LTS.\r\n  -- Here can be exceptions if we really need features from the newer versions.\r\n  build-depends:\r\n    , aeson              >=1.4.1.0 && <3\r\n    , base-compat        >=0.10.5  && <0.15\r\n    , base64-bytestring  >=1.0.0.1 && <1.3\r\n    , exceptions         >=0.10.0  && <0.11\r\n    , free               >=5.1     && <5.3\r\n    , http-media         >=0.7.1.3 && <0.9\r\n    , http-types         >=0.12.2  && <0.13\r\n    , network-uri        >=2.6.1.0 && <2.7\r\n    , safe               >=0.3.17  && <0.4\r\n    , sop-core           >=0.4.0.0 && <0.6\r\n\r\n  hs-source-dirs:  src\r\n\r\ntest-suite spec\r\n  import:             extensions\r\n  import:             ghc-options\r\n  type:               exitcode-stdio-1.0\r\n  hs-source-dirs:     test\r\n  main-is:            Spec.hs\r\n  other-modules:\r\n    Servant.Client.Core.Internal.BaseUrlSpec\r\n    Servant.Client.Core.RequestSpec\r\n    Servant.Client.Core.ServerSentEventsSpec\r\n\r\n  -- Dependencies inherited from the library. No need to specify bounds.\r\n  build-depends:\r\n    , base\r\n    , base-compat\r\n    , bytestring\r\n    , transformers\r\n    , servant\r\n    , servant-client-core\r\n\r\n  -- Additional dependencies\r\n  build-depends:\r\n    , deepseq     >=1.4.2.0  && <1.6\r\n    , hspec       >=2.6.0    && <2.12\r\n    , QuickCheck  >=2.12.6.1 && <2.17\r\n\r\n  build-tool-depends: hspec-discover:hspec-discover >=2.6.0 && <2.12\r\n";
  }