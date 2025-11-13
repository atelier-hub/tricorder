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
      identifier = { name = "th-expand-syns"; version = "0.4.12.0"; };
      license = "BSD-3-Clause";
      copyright = "";
      maintainer = "Ryan Scott <ryan.gl.scott@gmail.com>";
      author = "Daniel Schüssler";
      homepage = "https://github.com/DanielSchuessler/th-expand-syns";
      url = "";
      synopsis = "Expands type synonyms in Template Haskell ASTs";
      description = "Expands type synonyms in Template Haskell ASTs.\n\nAs of version @0.4.9.0@, this library is a small shim on\ntop of the @applySubstitution@/@resolveTypeSynonyms@\nfunctions from @th-abstraction@, so you may want to\nconsider using @th-abstraction@ instead.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
          (hsPkgs."syb" or (errorHandler.buildDepError "syb"))
          (hsPkgs."th-abstraction" or (errorHandler.buildDepError "th-abstraction"))
          (hsPkgs."template-haskell" or (errorHandler.buildDepError "template-haskell"))
        ];
        buildable = true;
      };
      tests = {
        "test-th-expand-syns" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."template-haskell" or (errorHandler.buildDepError "template-haskell"))
            (hsPkgs."th-abstraction" or (errorHandler.buildDepError "th-abstraction"))
            (hsPkgs."th-expand-syns" or (errorHandler.buildDepError "th-expand-syns"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/th-expand-syns-0.4.12.0.tar.gz";
      sha256 = "18e19967329c89f376cfc9ec04bd7871854ce0c70f803a1af15532be00c6ef0f";
    });
  }) // {
    package-description-override = "name:                th-expand-syns\nversion:             0.4.12.0\nsynopsis:            Expands type synonyms in Template Haskell ASTs\ndescription:         Expands type synonyms in Template Haskell ASTs.\n                     .\n                     As of version @0.4.9.0@, this library is a small shim on\n                     top of the @applySubstitution@/@resolveTypeSynonyms@\n                     functions from @th-abstraction@, so you may want to\n                     consider using @th-abstraction@ instead.\ncategory:            Template Haskell\nlicense:             BSD3\nlicense-file:        LICENSE\nauthor:              Daniel Schüssler\nmaintainer:          Ryan Scott <ryan.gl.scott@gmail.com>\ncabal-version:       >= 1.10\nbuild-type:          Simple\nextra-source-files:  changelog.markdown\nhomepage:            https://github.com/DanielSchuessler/th-expand-syns\ntested-with:\n    GHC == 8.0.2\n    GHC == 8.2.2\n    GHC == 8.4.4\n    GHC == 8.6.5\n    GHC == 8.8.4\n    GHC == 8.10.7\n    GHC == 9.0.2\n    GHC == 9.2.8\n    GHC == 9.4.8\n    GHC == 9.6.6\n    GHC == 9.8.4\n    GHC == 9.10.1\n    GHC == 9.12.1\n\nsource-repository head\n type: git\n location: https://github.com/DanielSchuessler/th-expand-syns.git\n\nLibrary\n    build-depends:       base             >= 4.9   && < 5\n                       , containers\n                       , syb\n                       , th-abstraction   >= 0.4.3 && < 0.8\n                       , template-haskell >= 2.11  && < 2.24\n    ghc-options:         -Wall\n    exposed-modules:     Language.Haskell.TH.ExpandSyns\n    default-language:    Haskell2010\n\nTest-Suite test-th-expand-syns\n    type:               exitcode-stdio-1.0\n    hs-source-dirs:     testing\n    main-is:            Main.hs\n    other-modules:      Util, Types\n    build-depends:      base\n                      , template-haskell\n                      , th-abstraction\n                      , th-expand-syns\n    ghc-options:        -Wall\n    if impl(ghc >= 8.6)\n      ghc-options:      -Wno-star-is-type\n    default-language:   Haskell2010\n";
  }