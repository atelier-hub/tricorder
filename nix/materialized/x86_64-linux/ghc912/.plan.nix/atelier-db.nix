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
      specVersion = "2.0";
      identifier = { name = "atelier-db"; version = "0.1.0.0"; };
      license = "MIT";
      copyright = "";
      maintainer = "christian.georgii@tweag.io";
      author = "Christian Georgii";
      homepage = "https://github.com/atelier-hub/tricorder#readme";
      url = "";
      synopsis = "Relational database effect for atelier (Hasql/Rel8)";
      description = "Relational database access via Hasql and Rel8, exposed as an Effectful effect — part of the atelier toolkit.";
      buildType = "Simple";
      isLocal = true;
      detailLevel = "FullDetails";
      licenseFiles = [ "LICENSE" ];
      dataDir = ".";
      dataFiles = [];
      extraSrcFiles = [];
      extraTmpFiles = [];
      extraDocFiles = [ "CHANGELOG.md" "README.md" ];
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."aeson" or (errorHandler.buildDepError "aeson"))
          (hsPkgs."atelier-core" or (errorHandler.buildDepError "atelier-core"))
          (hsPkgs."atelier-prelude" or (errorHandler.buildDepError "atelier-prelude"))
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
          (hsPkgs."data-default" or (errorHandler.buildDepError "data-default"))
          (hsPkgs."effectful" or (errorHandler.buildDepError "effectful"))
          (hsPkgs."effectful-core" or (errorHandler.buildDepError "effectful-core"))
          (hsPkgs."effectful-plugin" or (errorHandler.buildDepError "effectful-plugin"))
          (hsPkgs."effectful-th" or (errorHandler.buildDepError "effectful-th"))
          (hsPkgs."hasql" or (errorHandler.buildDepError "hasql"))
          (hsPkgs."hasql-pool" or (errorHandler.buildDepError "hasql-pool"))
          (hsPkgs."hasql-transaction" or (errorHandler.buildDepError "hasql-transaction"))
          (hsPkgs."rel8" or (errorHandler.buildDepError "rel8"))
          (hsPkgs."text" or (errorHandler.buildDepError "text"))
          (hsPkgs."time" or (errorHandler.buildDepError "time"))
        ];
        buildable = true;
        modules = [ "Paths_atelier_db" ];
        hsSourceDirs = [ "src" ];
      };
    };
  } // rec { src = pkgs.lib.mkDefault ../atelier-db; }) // {
    cabal-generator = "hpack";
  }[ "src" ];
      };
    };
  } // rec { src = pkgs.lib.mkDefault ../atelier-db; }