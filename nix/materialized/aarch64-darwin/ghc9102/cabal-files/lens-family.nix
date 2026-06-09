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
      identifier = { name = "lens-family"; version = "2.1.3"; };
      license = "BSD-3-Clause";
      copyright = "Copyright (C) 2012,2013,2014,2017,2018,2019 Russell O'Connor";
      maintainer = "Russell O'Connor <roconnor@r6.ca>";
      author = "Russell O'Connor";
      homepage = "";
      url = "";
      synopsis = "Lens Families";
      description = "This package provides first class functional references in Van Laarhoven style supporting the following optics:\n\n* Lenses (view, over)\n\n* Traversals (toListOf, matching, over)\n\n* Setters (over)\n\n* Grates (zipWithOf, under, review)\n\n* Resetters (under)\n\n* Adapters (view, review)\n\n* Grids (toListOf, over / under, review)\n\n* Prisms (matching, over / under, review)\n\n* Getters (view)\n\n* Folders (toListOf)\n\n* Reviewers (review)";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
          (hsPkgs."transformers" or (errorHandler.buildDepError "transformers"))
          (hsPkgs."mtl" or (errorHandler.buildDepError "mtl"))
          (hsPkgs."lens-family-core" or (errorHandler.buildDepError "lens-family-core"))
        ];
        buildable = true;
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/lens-family-2.1.3.tar.gz";
      sha256 = "1801b4c233538cbfe67c2f62827ef965f6f60aaebc270dd9b07f0f7f3deb2513";
    });
  }) // {
    package-description-override = "name:               lens-family\ncategory:           Data, Lenses\nversion:            2.1.3\nlicense:            BSD3\ncabal-version:      >= 1.10\nlicense-file:       LICENSE\nauthor:             Russell O'Connor\nmaintainer:         Russell O'Connor <roconnor@r6.ca>\nstability:          experimental\ncopyright:          Copyright (C) 2012,2013,2014,2017,2018,2019 Russell O'Connor\nsynopsis:           Lens Families\nbuild-type:         Simple\nextra-source-files: CHANGELOG\ndescription:        This package provides first class functional references in Van Laarhoven style supporting the following optics:\n                    .\n                    * Lenses (view, over)\n                    .\n                    * Traversals (toListOf, matching, over)\n                    .\n                    * Setters (over)\n                    .\n                    * Grates (zipWithOf, under, review)\n                    .\n                    * Resetters (under)\n                    .\n                    * Adapters (view, review)\n                    .\n                    * Grids (toListOf, over / under, review)\n                    .\n                    * Prisms (matching, over / under, review)\n                    .\n                    * Getters (view)\n                    .\n                    * Folders (toListOf)\n                    .\n                    * Reviewers (review)\n\nsource-repository head\n  type:     darcs\n  location: https://hub.darcs.net/roconnor/lens-family\n\nlibrary\n  default-language:   Haskell2010\n  other-extensions:   Rank2Types\n  build-depends:\n    base                 >= 4.11    && < 5,\n    containers           >= 0.5.8   && < 0.8,\n    transformers         >= 0.3.0   && < 0.7,\n    mtl                  >= 2.2     && < 2.4,\n    lens-family-core     >= 2.1.0   && < 2.2\n\n  exposed-modules:\n    Lens.Family2.Unchecked\n    Lens.Family2\n    Lens.Family2.Stock\n    Lens.Family2.State.Lazy\n    Lens.Family2.State.Strict\n    Lens.Family2.State\n\n  ghc-options:      -Wall\n\n  hs-source-dirs:\n                    src\n\n";
  }