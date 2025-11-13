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
      specVersion = "1.12";
      identifier = { name = "hspec-api"; version = "2.11.14"; };
      license = "MIT";
      copyright = "(c) 2022-2025 Simon Hengel";
      maintainer = "Simon Hengel <sol@typeful.net>";
      author = "Simon Hengel <sol@typeful.net>";
      homepage = "https://hspec.github.io/";
      url = "";
      synopsis = "A Testing Framework for Haskell";
      description = "This package provides a stable API that can be used to extend Hspec's functionality.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."hspec-core" or (errorHandler.buildDepError "hspec-core"))
          (hsPkgs."transformers" or (errorHandler.buildDepError "transformers"))
        ];
        buildable = true;
      };
      tests = {
        "spec" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."hspec" or (errorHandler.buildDepError "hspec"))
            (hsPkgs."hspec-api" or (errorHandler.buildDepError "hspec-api"))
            (hsPkgs."hspec-core" or (errorHandler.buildDepError "hspec-core"))
            (hsPkgs."transformers" or (errorHandler.buildDepError "transformers"))
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
      url = "http://hackage.haskell.org/package/hspec-api-2.11.14.tar.gz";
      sha256 = "4870af20a4da5fdaf6d95b88b299d179ee286967749eda45d0deab26a6c5ebb1";
    });
  }) // {
    package-description-override = "cabal-version: 1.12\n\n-- This file has been generated from package.yaml by hpack version 0.38.1.\n--\n-- see: https://github.com/sol/hpack\n\nname:           hspec-api\nversion:        2.11.14\nsynopsis:       A Testing Framework for Haskell\ndescription:    This package provides a stable API that can be used to extend Hspec's functionality.\ncategory:       Testing\nstability:      stable\nhomepage:       https://hspec.github.io/\nbug-reports:    https://github.com/hspec/hspec/issues\nauthor:         Simon Hengel <sol@typeful.net>\nmaintainer:     Simon Hengel <sol@typeful.net>\ncopyright:      (c) 2022-2025 Simon Hengel\nlicense:        MIT\nlicense-file:   LICENSE\nbuild-type:     Simple\nextra-source-files:\n    version.yaml\n\nsource-repository head\n  type: git\n  location: https://github.com/hspec/hspec\n  subdir: hspec-api\n\nlibrary\n  exposed-modules:\n      Test.Hspec.Api.Format.V1\n      Test.Hspec.Api.Format.V2\n      Test.Hspec.Api.Formatters.V1\n      Test.Hspec.Api.Formatters.V2\n      Test.Hspec.Api.Formatters.V3\n  other-modules:\n      Test.Hspec.Api.Format.V1.Internal\n      Test.Hspec.Api.Format.V2.Config\n  hs-source-dirs:\n      src\n  ghc-options: -Wall\n  build-depends:\n      base ==4.*\n    , hspec-core ==2.11.14\n    , transformers\n  default-language: Haskell2010\n\ntest-suite spec\n  type: exitcode-stdio-1.0\n  main-is: Spec.hs\n  other-modules:\n      Test.Hspec.Api.Format.V1Spec\n      Test.Hspec.Api.Format.V2Spec\n      Test.Hspec.Api.Formatters.V1Spec\n      Test.Hspec.Api.Formatters.V2Spec\n      Test.Hspec.Api.Formatters.V3Spec\n      Paths_hspec_api\n  hs-source-dirs:\n      test\n  ghc-options: -Wall\n  build-tool-depends:\n      hspec-discover:hspec-discover\n  build-depends:\n      base ==4.*\n    , hspec ==2.*\n    , hspec-api\n    , hspec-core ==2.11.14\n    , transformers\n  default-language: Haskell2010\n";
  }