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
      identifier = { name = "thread-utils-finalizers"; version = "0.1.1.0"; };
      license = "BSD-3-Clause";
      copyright = "2021 Ian Duncan";
      maintainer = "ian@iankduncan.com";
      author = "Ian Duncan";
      homepage = "https://github.com/iand675/thread-utils#readme";
      url = "";
      synopsis = "Perform finalization for threads.";
      description = "Please see the README on GitHub at <https://github.com/iand675/thread-finalizers#readme>";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."ghc-prim" or (errorHandler.buildDepError "ghc-prim"))
        ];
        buildable = true;
      };
      tests = {
        "thread-finalizers-test" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."ghc-prim" or (errorHandler.buildDepError "ghc-prim"))
            (hsPkgs."thread-utils-finalizers" or (errorHandler.buildDepError "thread-utils-finalizers"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/thread-utils-finalizers-0.1.1.0.tar.gz";
      sha256 = "032b5bd4ef6f96beea81e1d3fc674662977740db3986394fe4bd96758e0fd92b";
    });
  }) // {
    package-description-override = "cabal-version: 1.12\n\n-- This file has been generated from package.yaml by hpack version 0.35.2.\n--\n-- see: https://github.com/sol/hpack\n\nname:           thread-utils-finalizers\nversion:        0.1.1.0\nsynopsis:       Perform finalization for threads.\ndescription:    Please see the README on GitHub at <https://github.com/iand675/thread-finalizers#readme>\ncategory:       Concurrency\nhomepage:       https://github.com/iand675/thread-utils#readme\nbug-reports:    https://github.com/iand675/thread-utils/issues\nauthor:         Ian Duncan\nmaintainer:     ian@iankduncan.com\ncopyright:      2021 Ian Duncan\nlicense:        BSD3\nlicense-file:   LICENSE\nbuild-type:     Simple\nextra-source-files:\n    README.md\n    ChangeLog.md\n\nsource-repository head\n  type: git\n  location: https://github.com/iand675/thread-utils\n\nlibrary\n  exposed-modules:\n      Control.Concurrent.Thread.Finalizers\n  other-modules:\n      Paths_thread_utils_finalizers\n  hs-source-dirs:\n      src\n  build-depends:\n      base >=4.7 && <5\n    , ghc-prim\n  default-language: Haskell2010\n\ntest-suite thread-finalizers-test\n  type: exitcode-stdio-1.0\n  main-is: Spec.hs\n  other-modules:\n      Paths_thread_utils_finalizers\n  hs-source-dirs:\n      test\n  ghc-options: -threaded -rtsopts -with-rtsopts=-N\n  build-depends:\n      base >=4.7 && <5\n    , ghc-prim\n    , thread-utils-finalizers\n  default-language: Haskell2010\n";
  }