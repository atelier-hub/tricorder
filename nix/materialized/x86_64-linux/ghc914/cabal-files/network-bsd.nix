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
      identifier = { name = "network-bsd"; version = "2.8.1.0"; };
      license = "BSD-3-Clause";
      copyright = "";
      maintainer = "Kazu Yamamoto, Herbert Valerio Riedel";
      author = "";
      homepage = "https://github.com/haskell/network-bsd";
      url = "";
      synopsis = "POSIX network database (<netdb.h>) API";
      description = "This package provides Haskell bindings to the\nthe [POSIX network database (netdb.h) API](http://pubs.opengroup.org/onlinepubs/009696699/basedefs/netdb.h.html).\n\n=== Relationship to the @network@ package\n\nThe @network@ package version 2.* series provides \"Network.BSD\" but\nit is removed starting with @network@ version 3.0.\n\nThis package provides the \"Network.BSD\" module split off from the\n<https://hackage.haskell.org/package/network network package>.\n\nIf in addition to the @network@'s modules also \"Network.BSD\" is\nnecessary, add @network-bsd@ to your dependencies like so:\n\n> library\n>     build-depends: network     >= 2.7 && < 3.2\n>                  , network-bsd >= 2.7 && < 2.9\n\nI.e. you can control the version of the @network@ package\nindependently.\n\n__NOTE__: Starting with @network-bsd-2.8.1.0@ the APIs of @network@\nand @network-bsd@ evolve differently, and consequently the\nversioning doesn't match up anymore! Moreover, also starting with\nversion @network-bsd-2.8.1.0@ this package requires @network >= 3@\nin order to avoid module name clashes with @network < 3@'s\n\"Network.BSD\" module.\n\nHowever, @network-bsd-2.7.0.0@ and @network-bsd-2.8.0.0@ passes thru\nthe \"Network.BSD\" module from @network-2.7.*@ and @network-2.8.*@\nrespectively in a non-clashing way via Cabal's\n<https://www.haskell.org/cabal/users-guide/developing-packages.html#pkg-field-library-reexported-modules reexported-modules>\nfeature while ensuring a well-defined\n<https://pvp.haskell.org/ API versioning> of the observable API of\n@network-bsd@. This is why the example above supporting a wide range\nof @network@ versions works by including version 2.7.0.0 in the\nrequired version range of @network-bsd@.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."deepseq" or (errorHandler.buildDepError "deepseq"))
          (hsPkgs."network" or (errorHandler.buildDepError "network"))
        ];
        build-tools = [
          (hsPkgs.pkgsBuildBuild.hsc2hs.components.exes.hsc2hs or (pkgs.pkgsBuildBuild.hsc2hs or (errorHandler.buildToolDepError "hsc2hs:hsc2hs")))
        ];
        buildable = true;
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/network-bsd-2.8.1.0.tar.gz";
      sha256 = "d94961ca15c42c798d19cde540ec12b25cc43435fb95e682399d6c1a02022d4e";
    });
  }) // {
    package-description-override = "cabal-version:  1.12\r\nname:           network-bsd\r\nversion:        2.8.1.0\r\nx-revision:     6\r\nlicense:        BSD3\r\nlicense-file:   LICENSE\r\nmaintainer:     Kazu Yamamoto, Herbert Valerio Riedel\r\nsynopsis:       POSIX network database (<netdb.h>) API\r\ndescription:\r\n  This package provides Haskell bindings to the\r\n  the [POSIX network database (netdb.h) API](http://pubs.opengroup.org/onlinepubs/009696699/basedefs/netdb.h.html).\r\n  .\r\n  === Relationship to the @network@ package\r\n  .\r\n  The @network@ package version 2.* series provides \"Network.BSD\" but\r\n  it is removed starting with @network@ version 3.0.\r\n  .\r\n  This package provides the \"Network.BSD\" module split off from the\r\n  <https://hackage.haskell.org/package/network network package>.\r\n  .\r\n  If in addition to the @network@'s modules also \"Network.BSD\" is\r\n  necessary, add @network-bsd@ to your dependencies like so:\r\n  .\r\n  > library\r\n  >     build-depends: network     >= 2.7 && < 3.2\r\n  >                  , network-bsd >= 2.7 && < 2.9\r\n  .\r\n  I.e. you can control the version of the @network@ package\r\n  independently.\r\n  .\r\n  __NOTE__: Starting with @network-bsd-2.8.1.0@ the APIs of @network@\r\n  and @network-bsd@ evolve differently, and consequently the\r\n  versioning doesn't match up anymore! Moreover, also starting with\r\n  version @network-bsd-2.8.1.0@ this package requires @network >= 3@\r\n  in order to avoid module name clashes with @network < 3@'s\r\n  \"Network.BSD\" module.\r\n  .\r\n  However, @network-bsd-2.7.0.0@ and @network-bsd-2.8.0.0@ passes thru\r\n  the \"Network.BSD\" module from @network-2.7.*@ and @network-2.8.*@\r\n  respectively in a non-clashing way via Cabal's\r\n  <https://www.haskell.org/cabal/users-guide/developing-packages.html#pkg-field-library-reexported-modules reexported-modules>\r\n  feature while ensuring a well-defined\r\n  <https://pvp.haskell.org/ API versioning> of the observable API of\r\n  @network-bsd@. This is why the example above supporting a wide range\r\n  of @network@ versions works by including version 2.7.0.0 in the\r\n  required version range of @network-bsd@.\r\n\r\ncategory:       Network\r\nbuild-type:     Simple\r\nhomepage:       https://github.com/haskell/network-bsd\r\nbug-reports:    https://github.com/haskell/network-bsd/issues\r\n\r\ntested-with:\r\n  GHC == 9.6.2\r\n  GHC == 9.4.5\r\n  GHC == 9.2.8\r\n  GHC == 9.0.2\r\n  GHC == 8.10.7\r\n  GHC == 8.8.4\r\n  GHC == 8.6.5\r\n  GHC == 8.4.4\r\n  GHC == 8.2.2\r\n  GHC == 8.0.2\r\n  GHC == 7.10.3\r\n  GHC == 7.8.4\r\n\r\nextra-source-files: CHANGELOG.md\r\n\r\nlibrary\r\n  default-language: Haskell2010\r\n  other-extensions: CPP, NondecreasingIndentation\r\n  exposed-modules: Network.BSD\r\n  build-depends: base    >= 4.7 && < 5\r\n               , deepseq >= 1.3.0.0 && < 1.6\r\n               -- NOTES on `network` depdendency\r\n               --\r\n               -- `network-bsd` heavily relies on `network`'s\r\n               -- exported CPP headers!  make sure that `network`\r\n               -- doesn't inadvertently break/change its CPP\r\n               -- headers before advertising support for new\r\n               -- versions of `network`.\r\n               --\r\n               -- Moreover, `network-bsd` reexports entities from\r\n               -- `network` so we need to be very conservative\r\n               -- with the bounds to avoid leaking through API\r\n               -- changes that aren't reflected in `network-bsd`'s\r\n               -- API version.\r\n               , network (>= 3.0.0.0 && < 3.0.2)\r\n                      || (>= 3.1.0.0 && < 3.3)\r\n  build-tools: hsc2hs >= 0.67 && < 0.69\r\n  ghc-options: -Wall\r\n\r\n  if os(windows) && impl(ghc >= 7.10)\r\n    -- See https://github.com/haskell/network/pull/362\r\n    cpp-options: -D_WIN32_WINNT=0x0600\r\n\r\nsource-repository head\r\n  type:     git\r\n  location: https://github.com/haskell/network-bsd.git\r\n";
  }