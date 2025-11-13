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
      identifier = { name = "contra-tracer"; version = "0.1.0.2"; };
      license = "Apache-2.0";
      copyright = "2019 IOHK";
      maintainer = "operations@iohk.io";
      author = "Neil Davies, Alexander Diemand, Andreas Triantafyllos";
      homepage = "";
      url = "";
      synopsis = "A simple interface for logging, tracing or monitoring.";
      description = "";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
        ] ++ pkgs.lib.optional (compiler.isGhc && compiler.version.lt "8.5") (hsPkgs."contravariant" or (errorHandler.buildDepError "contravariant"));
        buildable = true;
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "https://chap.intersectmbo.org/package/contra-tracer-0.1.0.2.tar.gz";
      sha256 = "aece5861203eb196cc7c852ff2dfe1d593f5baaef81b81aa5f9ba43c1d6dbb54";
    });
  }) // {
    package-description-override = "name:                contra-tracer\nversion:             0.1.0.2\nsynopsis:            A simple interface for logging, tracing or monitoring.\n-- description:\nlicense:             Apache-2.0\nlicense-files:       LICENSE, NOTICE\nauthor:              Neil Davies, Alexander Diemand, Andreas Triantafyllos\nmaintainer:          operations@iohk.io\ncopyright:           2019 IOHK\ncategory:            Logging\nbuild-type:          Simple\nextra-source-files:  README.md\ncabal-version:       >=1.10\n\nlibrary\n  hs-source-dirs:      src\n  exposed-modules:     Control.Tracer\n                       Control.Tracer.Observe\n\n  default-language:    Haskell2010\n  build-depends:       base\n  if impl(ghc < 8.5)\n    build-depends:     contravariant\n  ghc-options:         -Wall -Werror\n";
  }