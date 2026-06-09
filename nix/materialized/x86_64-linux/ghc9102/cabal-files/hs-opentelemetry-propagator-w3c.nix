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
      identifier = {
        name = "hs-opentelemetry-propagator-w3c";
        version = "0.1.0.0";
      };
      license = "BSD-3-Clause";
      copyright = "2024 Ian Duncan, Mercury Technologies";
      maintainer = "ian@iankduncan.com";
      author = "Ian Duncan, Jade Lovelace";
      homepage = "https://github.com/iand675/hs-opentelemetry#readme";
      url = "";
      synopsis = "Trace propagation via HTTP headers following the w3c tracestate spec.";
      description = "Please see the README on GitHub at <https://github.com/iand675/hs-opentelemetry/tree/main/propagators/w3c#readme>";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."attoparsec" or (errorHandler.buildDepError "attoparsec"))
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          (hsPkgs."hs-opentelemetry-api" or (errorHandler.buildDepError "hs-opentelemetry-api"))
          (hsPkgs."http-types" or (errorHandler.buildDepError "http-types"))
          (hsPkgs."text" or (errorHandler.buildDepError "text"))
        ];
        buildable = true;
      };
      tests = {
        "hs-opentelemetry-propagator-w3c-test" = {
          depends = [
            (hsPkgs."QuickCheck" or (errorHandler.buildDepError "QuickCheck"))
            (hsPkgs."attoparsec" or (errorHandler.buildDepError "attoparsec"))
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."hs-opentelemetry-api" or (errorHandler.buildDepError "hs-opentelemetry-api"))
            (hsPkgs."hs-opentelemetry-propagator-w3c" or (errorHandler.buildDepError "hs-opentelemetry-propagator-w3c"))
            (hsPkgs."hspec" or (errorHandler.buildDepError "hspec"))
            (hsPkgs."hspec-discover" or (errorHandler.buildDepError "hspec-discover"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/hs-opentelemetry-propagator-w3c-0.1.0.0.tar.gz";
      sha256 = "e3e945f1679dc604a06c4ac4311433d70e3d21a42f949c71faa4ba74f7db8af8";
    });
  }) // {
    package-description-override = "cabal-version: 1.12\n\n-- This file has been generated from package.yaml by hpack version 0.37.0.\n--\n-- see: https://github.com/sol/hpack\n\nname:               hs-opentelemetry-propagator-w3c\nversion:            0.1.0.0\nsynopsis:           Trace propagation via HTTP headers following the w3c tracestate spec.\ndescription:        Please see the README on GitHub at <https://github.com/iand675/hs-opentelemetry/tree/main/propagators/w3c#readme>\ncategory:           OpenTelemetry, Tracing, Web\nhomepage:           https://github.com/iand675/hs-opentelemetry#readme\nbug-reports:        https://github.com/iand675/hs-opentelemetry/issues\nauthor:             Ian Duncan, Jade Lovelace\nmaintainer:         ian@iankduncan.com\ncopyright:          2024 Ian Duncan, Mercury Technologies\nlicense:            BSD3\nlicense-file:       LICENSE\nbuild-type:         Simple\nextra-source-files:\n    README.md\n    ChangeLog.md\n\nsource-repository head\n  type: git\n  location: https://github.com/iand675/hs-opentelemetry\n\nlibrary\n  exposed-modules:\n      OpenTelemetry.Propagator.W3CBaggage\n      OpenTelemetry.Propagator.W3CTraceContext\n  other-modules:\n      Paths_hs_opentelemetry_propagator_w3c\n  hs-source-dirs:\n      src\n  ghc-options: -Wall\n  build-depends:\n      attoparsec\n    , base >=4.7 && <5\n    , bytestring\n    , hs-opentelemetry-api ==0.3.*\n    , http-types\n    , text\n  default-language: Haskell2010\n\ntest-suite hs-opentelemetry-propagator-w3c-test\n  type: exitcode-stdio-1.0\n  main-is: Spec.hs\n  other-modules:\n      OpenTelemetry.Propagator.W3CIntegrationSpec\n      OpenTelemetry.Propagator.W3CMultiHeaderSpec\n      OpenTelemetry.Propagator.W3CTraceContextSpec\n      Paths_hs_opentelemetry_propagator_w3c\n  hs-source-dirs:\n      test\n  ghc-options: -threaded -rtsopts -with-rtsopts=-N\n  build-depends:\n      QuickCheck\n    , attoparsec\n    , base >=4.7 && <5\n    , bytestring\n    , hs-opentelemetry-api\n    , hs-opentelemetry-propagator-w3c\n    , hspec\n    , hspec-discover\n    , text\n  default-language: Haskell2010\n";
  }