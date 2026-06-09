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
    flags = { safe = false; };
    package = {
      specVersion = "1.10";
      identifier = { name = "void"; version = "0.7.4"; };
      license = "BSD-3-Clause";
      copyright = "Copyright (C) 2008-2015 Edward A. Kmett";
      maintainer = "Edward A. Kmett <ekmett@gmail.com>";
      author = "Edward A. Kmett";
      homepage = "http://github.com/ekmett/void";
      url = "";
      synopsis = "A Haskell 98 logically uninhabited data type";
      description = "A Haskell 98 logically uninhabited data type, used to indicate that a given term should not exist.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [ (hsPkgs."base" or (errorHandler.buildDepError "base")) ];
        buildable = true;
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/void-0.7.4.tar.gz";
      sha256 = "61ff790961edb34fd653e62f9f37020792f416f329b12e87549169e7f624fdf9";
    });
  }) // {
    package-description-override = "name:          void\ncategory:      Data Structures\nversion:       0.7.4\nlicense:       BSD3\ncabal-version: >= 1.10\nlicense-file:  LICENSE\nauthor:        Edward A. Kmett\nmaintainer:    Edward A. Kmett <ekmett@gmail.com>\nstability:     portable\nhomepage:      http://github.com/ekmett/void\nbug-reports:   http://github.com/ekmett/void/issues\ncopyright:     Copyright (C) 2008-2015 Edward A. Kmett\nsynopsis:      A Haskell 98 logically uninhabited data type\ndescription:   A Haskell 98 logically uninhabited data type, used to indicate that a given term should not exist.\nbuild-type:    Simple\ntested-with:   GHC==9.12.2\n             , GHC==9.10.3\n             , GHC==9.8.4\n             , GHC==9.6.6\n             , GHC==9.4.8\n             , GHC==9.2.8\n             , GHC==9.0.2\n             , GHC==8.10.7\n             , GHC==8.8.4\n             , GHC==8.6.5\n             , GHC==8.4.4\n             , GHC==8.2.2\n             , GHC==8.0.2\n\nextra-source-files:\n  .ghci\n  .gitignore\n  .vim.custom\n  CHANGELOG.markdown\n  README.markdown\n\nsource-repository head\n  type: git\n  location: https://github.com/ekmett/void.git\n\nflag safe\n  manual: True\n  default: False\n\nlibrary\n  default-language: Haskell98\n  hs-source-dirs: src\n  exposed-modules:\n    Data.Void.Unsafe\n\n  build-depends: base >= 3 && < 10\n\n  ghc-options: -Wall\n\n  if flag(safe)\n    cpp-options: -DSAFE\n";
  }