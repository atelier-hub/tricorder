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
      specVersion = "3.0";
      identifier = { name = "data-default"; version = "0.8.0.1"; };
      license = "BSD-3-Clause";
      copyright = "(c) 2013 Lukas Mai";
      maintainer = "<lukasmai.403+hackage@gmail.com>";
      author = "Lukas Mai";
      homepage = "";
      url = "";
      synopsis = "A class for types with a default value";
      description = "This module defines a class for types with a default value. Instances are\nprovided for @()@, 'Data.Set.Set', 'Data.Map.Map', 'Int', 'Integer',\n'Float', 'Double', and many others.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
        ];
        buildable = true;
      };
      tests = {
        "test" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
            (hsPkgs."data-default" or (errorHandler.buildDepError "data-default"))
            (hsPkgs."mtl" or (errorHandler.buildDepError "mtl"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/data-default-0.8.0.1.tar.gz";
      sha256 = "ce085de8ec2196f0c1d30af0ad8a517d5737c9edfd4ebfbb49e8687dfc40b6ca";
    });
  }) // {
    package-description-override = "cabal-version:   3.0\nname:            data-default\nversion:         0.8.0.1\ncategory:        Data\nsynopsis:        A class for types with a default value\ndescription:\n    This module defines a class for types with a default value. Instances are\n    provided for @()@, 'Data.Set.Set', 'Data.Map.Map', 'Int', 'Integer',\n    'Float', 'Double', and many others.\nbuild-type:      Simple\nlicense:         BSD-3-Clause\nlicense-file:    LICENSE\ncopyright:       (c) 2013 Lukas Mai\nauthor:          Lukas Mai\nmaintainer:      <lukasmai.403+hackage@gmail.com>\nbug-reports:     https://codeberg.org/mauke/data-default/issues\nextra-doc-files: Changes.md\n\nsource-repository head\n    type: git\n    location: https://codeberg.org/mauke/data-default\n\nlibrary\n    build-depends:     base >=4.8 && <5, containers >=0.1 && <0.8\n    exposed-modules:   Data.Default, Data.Default.Internal\n    default-language:  Haskell98\n\ntest-suite test\n    type:              exitcode-stdio-1.0\n    main-is:           basics.hs\n    build-depends:     base, containers, data-default, mtl\n    hs-source-dirs:    t\n    default-language:  Haskell98\n";
  }