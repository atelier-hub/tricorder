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
    flags = { use-text-show = false; };
    package = {
      specVersion = "1.12";
      identifier = { name = "http-api-data"; version = "0.6.2"; };
      license = "BSD-3-Clause";
      copyright = "";
      maintainer = "Nickolay Kudasov <nickolay.kudasov@gmail.com>";
      author = "Nickolay Kudasov <nickolay.kudasov@gmail.com>";
      homepage = "http://github.com/fizruk/http-api-data";
      url = "";
      synopsis = "Converting to/from HTTP API data like URL pieces, headers and query parameters.";
      description = "This package defines typeclasses used for converting Haskell data types to and from HTTP API data.\n\nPlease see README.md";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
          (hsPkgs."text" or (errorHandler.buildDepError "text"))
          (hsPkgs."transformers" or (errorHandler.buildDepError "transformers"))
          (hsPkgs."cookie" or (errorHandler.buildDepError "cookie"))
          (hsPkgs."hashable" or (errorHandler.buildDepError "hashable"))
          (hsPkgs."http-types" or (errorHandler.buildDepError "http-types"))
          (hsPkgs."text-iso8601" or (errorHandler.buildDepError "text-iso8601"))
          (hsPkgs."tagged" or (errorHandler.buildDepError "tagged"))
          (hsPkgs."time-compat" or (errorHandler.buildDepError "time-compat"))
          (hsPkgs."unordered-containers" or (errorHandler.buildDepError "unordered-containers"))
          (hsPkgs."uuid-types" or (errorHandler.buildDepError "uuid-types"))
        ] ++ pkgs.lib.optional (flags.use-text-show) (hsPkgs."text-show" or (errorHandler.buildDepError "text-show"));
        buildable = true;
      };
      tests = {
        "spec" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."cookie" or (errorHandler.buildDepError "cookie"))
            (hsPkgs."http-api-data" or (errorHandler.buildDepError "http-api-data"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
            (hsPkgs."time-compat" or (errorHandler.buildDepError "time-compat"))
            (hsPkgs."unordered-containers" or (errorHandler.buildDepError "unordered-containers"))
            (hsPkgs."uuid-types" or (errorHandler.buildDepError "uuid-types"))
            (hsPkgs."HUnit" or (errorHandler.buildDepError "HUnit"))
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
      url = "http://hackage.haskell.org/package/http-api-data-0.6.2.tar.gz";
      sha256 = "dc84a9ff403922f03bdc497cedee145fdd0058b1bb47be59cf714460eaec8234";
    });
  }) // {
    package-description-override = "cabal-version:   1.12\nname:            http-api-data\nversion:         0.6.2\n\nsynopsis:        Converting to/from HTTP API data like URL pieces, headers and query parameters.\ncategory:        Web\ndescription:\n  This package defines typeclasses used for converting Haskell data types to and from HTTP API data.\n  .\n  Please see README.md\n\nlicense:         BSD3\nlicense-file:    LICENSE\nauthor:          Nickolay Kudasov <nickolay.kudasov@gmail.com>\nmaintainer:      Nickolay Kudasov <nickolay.kudasov@gmail.com>\nhomepage:        http://github.com/fizruk/http-api-data\nstability:       unstable\nbuild-type:      Simple\n\nextra-source-files:\n  test/*.hs\n  CHANGELOG.md\n  README.md\n\ntested-with:\n  GHC==8.6.5,\n  GHC==8.8.4,\n  GHC==8.10.7,\n  GHC==9.0.2,\n  GHC==9.2.8,\n  GHC==9.4.8,\n  GHC==9.6.7,\n  GHC==9.8.4,\n  GHC==9.10.1,\n  GHC==9.12.2\n\nflag use-text-show\n  description: Use text-show library for efficient ToHttpApiData implementations.\n  default: False\n  manual: True\n\nlibrary\n    hs-source-dirs: src/\n\n    -- GHC bundled\n    build-depends:   base                  >= 4.12.0.0 && < 4.22\n                   , bytestring            >= 0.10.8.2 && < 0.13\n                   , containers            >= 0.6.0.1  && < 0.8\n                   , text                  >= 1.2.3.0  && < 1.3 || >=2.0 && <2.2\n                   , transformers          >= 0.5.6.2  && < 0.7\n\n    -- other-dependencies\n    build-depends:\n                     cookie                >= 0.5.1    && < 0.6\n                   , hashable              >= 1.4.4.0  && < 1.6\n                   , http-types            >= 0.12.4   && < 0.13\n                   , text-iso8601          >= 0.1.1    && < 0.2\n                   , tagged                >= 0.8.8    && < 0.9\n                   , time-compat           >= 1.9.5    && < 1.10\n                   , unordered-containers  >= 0.2.20   && < 0.3\n                   , uuid-types            >= 1.0.6    && < 1.1\n\n    if flag(use-text-show)\n      cpp-options: -DUSE_TEXT_SHOW\n      build-depends: text-show        >= 3.10.5 && <3.12\n\n    exposed-modules:\n      Web.HttpApiData\n      Web.FormUrlEncoded\n      Web.Internal.FormUrlEncoded\n      Web.Internal.HttpApiData\n    ghc-options:     -Wall\n    default-language: Haskell2010\n\ntest-suite spec\n    type:          exitcode-stdio-1.0\n    main-is:       Spec.hs\n    other-modules:\n      Web.Internal.FormUrlEncodedSpec\n      Web.Internal.HttpApiDataSpec\n      Web.Internal.TestInstances\n    hs-source-dirs: test\n    ghc-options:   -Wall\n    default-language: Haskell2010\n    build-tool-depends: hspec-discover:hspec-discover >= 2.7.1 && <2.12\n    -- inherited  depndencies\n    build-depends:\n                     base\n                   , bytestring\n                   , cookie\n                   , http-api-data\n                   , text\n                   , time-compat\n                   , unordered-containers\n                   , uuid-types\n\n    build-depends:   HUnit                >= 1.6.0.0  && <1.7\n                   , hspec                >= 2.7.1    && <2.12\n                   , QuickCheck           >= 2.13.1   && <2.16\n                   , quickcheck-instances >= 0.3.25.2 && <0.4\n\nsource-repository head\n  type:     git\n  location: https://github.com/fizruk/http-api-data\n";
  }