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
      identifier = { name = "atelier-testing"; version = "0.1.0.0"; };
      license = "MIT";
      copyright = "";
      maintainer = "cgeorgii@gmail.com";
      author = "Christian Georgii";
      homepage = "";
      url = "";
      synopsis = "Database-backed test utilities for atelier";
      description = "Test utilities for database-backed tests using tmp-postgres — part of the atelier toolkit.";
      buildType = "Simple";
      isLocal = true;
      detailLevel = "FullDetails";
      licenseFiles = [];
      dataDir = ".";
      dataFiles = [];
      extraSrcFiles = [];
      extraTmpFiles = [];
      extraDocFiles = [];
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."atelier-core" or (errorHandler.buildDepError "atelier-core"))
          (hsPkgs."atelier-db" or (errorHandler.buildDepError "atelier-db"))
          (hsPkgs."atelier-prelude" or (errorHandler.buildDepError "atelier-prelude"))
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."effectful-core" or (errorHandler.buildDepError "effectful-core"))
          (hsPkgs."effectful-plugin" or (errorHandler.buildDepError "effectful-plugin"))
          (hsPkgs."hasql" or (errorHandler.buildDepError "hasql"))
          (hsPkgs."hasql-pool" or (errorHandler.buildDepError "hasql-pool"))
          (hsPkgs."hspec" or (errorHandler.buildDepError "hspec"))
          (hsPkgs."postgres-options" or (errorHandler.buildDepError "postgres-options"))
          (hsPkgs."string-conversions" or (errorHandler.buildDepError "string-conversions"))
          (hsPkgs."text" or (errorHandler.buildDepError "text"))
          (hsPkgs."tmp-postgres" or (errorHandler.buildDepError "tmp-postgres"))
          (hsPkgs."unix" or (errorHandler.buildDepError "unix"))
          (hsPkgs."uuid" or (errorHandler.buildDepError "uuid"))
        ];
        buildable = true;
        modules = [ "Paths_atelier_testing" ];
        hsSourceDirs = [ "src" ];
      };
    };
  } // rec { src = pkgs.lib.mkDefault ../atelier-testing; }) // {
    cabal-generator = "hpack";
  }