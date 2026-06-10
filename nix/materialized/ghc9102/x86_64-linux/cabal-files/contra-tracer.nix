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
      identifier = { name = "contra-tracer"; version = "0.2.0.0"; };
      license = "Apache-2.0";
      copyright = "2019-2021 Input Output (Hong Kong) Ltd., 2019-2021 Well-Typed LLP, 2019-2021 Alexander Vieth";
      maintainer = "aovieth@gmail.com";
      author = "Alexander Vieth";
      homepage = "";
      url = "";
      synopsis = "Arrow and contravariant tracers";
      description = "A simple interface for logging, tracing and monitoring";
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
      url = "http://hackage.haskell.org/package/contra-tracer-0.2.0.0.tar.gz";
      sha256 = "9eebc1e410b2e50a7da6418b9bf194e22c92f2c05b3724aec502d82ca87262e5";
    });
  }) // {
    package-description-override = "name:                contra-tracer\nversion:             0.2.0.0\nsynopsis:            Arrow and contravariant tracers\ndescription:         A simple interface for logging, tracing and monitoring\nlicense:             Apache-2.0\nlicense-files:       LICENSE\nauthor:              Alexander Vieth\nmaintainer:          aovieth@gmail.com\ncopyright:           2019-2021 Input Output (Hong Kong) Ltd., 2019-2021 Well-Typed LLP, 2019-2021 Alexander Vieth\ncategory:            Logging\nbuild-type:          Simple\nextra-source-files:  README.md CHANGELOG.md\ncabal-version:       >=1.10\n\nsource-repository head\n  type: git\n  location: https://github.com/avieth/contra-tracer\n\nlibrary\n  hs-source-dirs:      src\n  exposed-modules:     Control.Tracer\n                       Control.Tracer.Arrow\n\n  default-language:    Haskell2010\n  build-depends:       base < 5\n  if impl(ghc < 8.5)\n    build-depends:     contravariant\n";
  }