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
      identifier = { name = "old-time"; version = "1.1.0.4"; };
      license = "BSD-3-Clause";
      copyright = "";
      maintainer = "https://github.com/haskell/old-time";
      author = "";
      homepage = "";
      url = "";
      synopsis = "Time library";
      description = "This package provides the old time library.\n\nFor new projects, the newer\n<http://hackage.haskell.org/package/time time library>\nis recommended.";
      buildType = "Configure";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."old-locale" or (errorHandler.buildDepError "old-locale"))
        ];
        build-tools = [
          (hsPkgs.pkgsBuildBuild.hsc2hs.components.exes.hsc2hs or (pkgs.pkgsBuildBuild.hsc2hs or (errorHandler.buildToolDepError "hsc2hs:hsc2hs")))
        ];
        buildable = true;
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/old-time-1.1.0.4.tar.gz";
      sha256 = "1e22eb7f7b924a676f52e317917b3b5eeceee11c74ef4bc609c0bcec624c166f";
    });
  }) // {
    package-description-override = "cabal-version:  >=1.10\nname:           old-time\nversion:        1.1.0.4\n-- NOTE: Don't forget to update ./changelog.md\nlicense:        BSD3\nlicense-file:   LICENSE\nmaintainer:     https://github.com/haskell/old-time\nbug-reports:    https://github.com/haskell/old-time/issues\nsynopsis:       Time library\ncategory:       System\nbuild-type:     Configure\ndescription:\n    This package provides the old time library.\n    .\n    For new projects, the newer\n    <http://hackage.haskell.org/package/time time library>\n    is recommended.\n\ntested-with:\n  GHC == 9.6.2\n  GHC == 9.4.5\n  GHC == 9.2.8\n  GHC == 9.0.2\n  GHC == 8.10.7\n  GHC == 8.8.4\n  GHC == 8.6.5\n  GHC == 8.4.4\n  GHC == 8.2.2\n  GHC == 8.0.2\n  GHC == 7.10.3\n  GHC == 7.8.4\n\nextra-source-files:\n    aclocal.m4\n    changelog.md\n    config.guess\n    config.sub\n    configure\n    configure.ac\n    include/HsTimeConfig.h.in\n    install-sh\n    old-time.buildinfo\n\nextra-tmp-files:\n    autom4te.cache\n    config.log\n    config.status\n    include/HsTimeConfig.h\n\nsource-repository head\n    type:     git\n    location: https://github.com/haskell/old-time.git\n\nLibrary\n    default-language: Haskell2010\n    other-extensions: Trustworthy\n\n    exposed-modules:\n        System.Time\n\n    c-sources:\n        cbits/timeUtils.c\n\n    include-dirs: include\n    includes:     HsTime.h\n    install-includes:\n        HsTime.h\n\n    build-depends:\n        base       >= 4.7 && < 5,\n        old-locale == 1.0.*\n\n    build-tools: hsc2hs\n\n    ghc-options: -Wall\n";
  }