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
      specVersion = "1.18";
      identifier = { name = "atelier-prelude"; version = "0.1.0.0"; };
      license = "MIT";
      copyright = "";
      maintainer = "cgeorgii@gmail.com";
      author = "Christian Georgii";
      homepage = "https://github.com/atelier-hub/tricorder#readme";
      url = "";
      synopsis = "Custom relude-based prelude with Effectful conventions";
      description = "A custom prelude based on relude, adapted for Effectful — part of the atelier toolkit.";
      buildType = "Simple";
      isLocal = true;
      detailLevel = "FullDetails";
      licenseFiles = [ "LICENSE" ];
      dataDir = ".";
      dataFiles = [];
      extraSrcFiles = [];
      extraTmpFiles = [];
      extraDocFiles = [ "CHANGELOG.md" ];
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."effectful-core" or (errorHandler.buildDepError "effectful-core"))
          (hsPkgs."relude" or (errorHandler.buildDepError "relude"))
        ];
        buildable = true;
        modules = [ "Paths_atelier_prelude" ];
        hsSourceDirs = [ "src" ];
      };
    };
  } // rec { src = pkgs.lib.mkDefault ../atelier-prelude; }) // {
    cabal-generator = "hpack";
  }