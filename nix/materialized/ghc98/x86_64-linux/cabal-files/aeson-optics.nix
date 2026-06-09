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
      specVersion = "1.24";
      identifier = { name = "aeson-optics"; version = "1.2.1"; };
      license = "MIT";
      copyright = "Copyright (C) 2012 Paul Wilson\nCopyright (C) 2013 Edward A. Kmett\nCopyright (C) 2019 Oleg Grenrus";
      maintainer = "Oleg Grenrus <oleg.grenrus@iki.fi>";
      author = "Edward A. Kmett, Oleg Grenrus";
      homepage = "http://github.com/phadej/aeson-optics";
      url = "";
      synopsis = "Law-abiding optics for aeson";
      description = "Law-abiding optics for aeson.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."aeson" or (errorHandler.buildDepError "aeson"))
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          (hsPkgs."optics-core" or (errorHandler.buildDepError "optics-core"))
          (hsPkgs."optics-extra" or (errorHandler.buildDepError "optics-extra"))
          (hsPkgs."scientific" or (errorHandler.buildDepError "scientific"))
          (hsPkgs."text" or (errorHandler.buildDepError "text"))
          (hsPkgs."text-short" or (errorHandler.buildDepError "text-short"))
          (hsPkgs."vector" or (errorHandler.buildDepError "vector"))
        ];
        buildable = true;
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/aeson-optics-1.2.1.tar.gz";
      sha256 = "4a9a2042c214b8deb9044e51d70f5c394ad2a7dd079544fee45ccaa36d297d69";
    });
  }) // {
    package-description-override = "version:            1.2.1\nx-revision:         1\nname:               aeson-optics\ncategory:           Data, JSON, Optics\nlicense:            MIT\ncabal-version:      1.24\nlicense-file:       LICENSE\nauthor:             Edward A. Kmett, Oleg Grenrus\nmaintainer:         Oleg Grenrus <oleg.grenrus@iki.fi>\nstability:          provisional\nhomepage:           http://github.com/phadej/aeson-optics\nbug-reports:        http://github.com/phadej/aeson-optics/issues\ncopyright:\n  Copyright (C) 2012 Paul Wilson\n  Copyright (C) 2013 Edward A. Kmett\n  Copyright (C) 2019 Oleg Grenrus\n\nbuild-type:         Simple\ntested-with:\n  GHC ==8.2.2\n   || ==8.4.4\n   || ==8.6.5\n   || ==8.8.4\n   || ==8.10.7\n   || ==9.0.2\n   || ==9.2.8\n   || ==9.4.8\n   || ==9.6.3\n   || ==9.8.1\n\nsynopsis:           Law-abiding optics for aeson\ndescription:        Law-abiding optics for aeson.\nextra-source-files:\n  AUTHORS.markdown\n  CHANGELOG.md\n  README.markdown\n\nsource-repository head\n  type:     git\n  location: https://github.com/phadej/aeson-optics\n\nlibrary\n  default-language: Haskell2010\n  build-depends:\n      aeson         >=2.0.3.0  && <2.3\n    , base          >=4.10     && <4.20\n    , bytestring    >=0.10.8.1 && <0.13\n    , optics-core   >=0.4.1    && <0.5\n    , optics-extra  >=0.4.1    && <0.5\n    , scientific    >=0.3.4.9  && <0.4\n    , text          >=1.2.2.0  && <1.3 || >=2.0 && <2.2\n    , text-short    >=0.1.5    && <0.2\n    , vector        >=0.11     && <0.14\n\n  exposed-modules:  Data.Aeson.Optics\n  ghc-options:      -Wall -fwarn-tabs -O2\n  hs-source-dirs:   src\n";
  }