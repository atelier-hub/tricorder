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
      specVersion = "1.10";
      identifier = { name = "mime-types"; version = "0.1.2.0"; };
      license = "MIT";
      copyright = "";
      maintainer = "michael@snoyman.com";
      author = "Michael Snoyman";
      homepage = "https://github.com/yesodweb/wai";
      url = "";
      synopsis = "Basic mime-type handling types and functions";
      description = "API docs and the README are available at <http://www.stackage.org/package/mime-types>.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
          (hsPkgs."text" or (errorHandler.buildDepError "text"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
        ];
        buildable = true;
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/mime-types-0.1.2.0.tar.gz";
      sha256 = "013ae48a4c1726a4f91a64e882f3fe1fb903a7d4b8c14da51286fe5e4b974f61";
    });
  }) // {
    package-description-override = "name:                mime-types\nversion:             0.1.2.0\nsynopsis:            Basic mime-type handling types and functions\ndescription:         API docs and the README are available at <http://www.stackage.org/package/mime-types>.\nhomepage:            https://github.com/yesodweb/wai\nlicense:             MIT\nlicense-file:        LICENSE\nauthor:              Michael Snoyman\nmaintainer:          michael@snoyman.com\ncategory:            Web\nbuild-type:          Simple\ncabal-version:       >=1.10\nextra-source-files:  README.md ChangeLog.md\n\nlibrary\n  exposed-modules:     Network.Mime\n  default-language:    Haskell2010\n  build-depends:       base           >= 4.12   && < 5\n                     , containers\n                     , text\n                     , bytestring\n\nsource-repository head\n  type:     git\n  location: git://github.com/yesodweb/wai.git\n";
  }