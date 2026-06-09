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
        name = "hs-opentelemetry-propagator-b3";
        version = "0.0.1.3";
      };
      license = "BSD-3-Clause";
      copyright = "2021 Ian Duncan";
      maintainer = "ian@iankduncan.com";
      author = "Ian Duncan";
      homepage = "https://github.com/iand675/hs-opentelemetry#readme";
      url = "";
      synopsis = "Trace propagation via HTTP headers following the b3 tracestate spec.";
      description = "Please see the README on GitHub at <https://github.com/iand675/hs-opentelemetry/tree/main/propagators/b3#readme>";
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
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/hs-opentelemetry-propagator-b3-0.0.1.3.tar.gz";
      sha256 = "4142490b8cf2e35452760f32e76cf82c5f64359c5fdbdefd9858bf941e737f65";
    });
  }) // {
    package-description-override = "cabal-version: 1.12\n\n-- This file has been generated from package.yaml by hpack version 0.37.0.\n--\n-- see: https://github.com/sol/hpack\n\nname:               hs-opentelemetry-propagator-b3\nversion:            0.0.1.3\nsynopsis:           Trace propagation via HTTP headers following the b3 tracestate spec.\ndescription:        Please see the README on GitHub at <https://github.com/iand675/hs-opentelemetry/tree/main/propagators/b3#readme>\ncategory:           OpenTelemetry, Tracing, Web\nhomepage:           https://github.com/iand675/hs-opentelemetry#readme\nbug-reports:        https://github.com/iand675/hs-opentelemetry/issues\nauthor:             Ian Duncan\nmaintainer:         ian@iankduncan.com\ncopyright:          2021 Ian Duncan\nlicense:            BSD3\nlicense-file:       LICENSE\nbuild-type:         Simple\nextra-source-files:\n    README.md\n    ChangeLog.md\n\nsource-repository head\n  type: git\n  location: https://github.com/iand675/hs-opentelemetry\n\nlibrary\n  exposed-modules:\n      OpenTelemetry.Propagator.B3\n      OpenTelemetry.Propagator.B3.Internal\n  other-modules:\n      Paths_hs_opentelemetry_propagator_b3\n  hs-source-dirs:\n      src\n  ghc-options: -Wall\n  build-depends:\n      attoparsec\n    , base >=4.7 && <5\n    , bytestring\n    , hs-opentelemetry-api ==0.3.*\n    , http-types\n    , text\n  default-language: Haskell2010\n";
  }