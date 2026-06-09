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
    flags = { debug = false; };
    package = {
      specVersion = "1.12";
      identifier = { name = "thread-utils-context"; version = "0.3.0.4"; };
      license = "BSD-3-Clause";
      copyright = "2023 Ian Duncan";
      maintainer = "ian@iankduncan.com";
      author = "Ian Duncan";
      homepage = "https://github.com/iand675/thread-utils#readme";
      url = "";
      synopsis = "Garbage-collected thread local storage";
      description = "Please see the README on GitHub at <https://github.com/iand675/thread-utils-context#readme>";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
          (hsPkgs."ghc-prim" or (errorHandler.buildDepError "ghc-prim"))
          (hsPkgs."thread-utils-finalizers" or (errorHandler.buildDepError "thread-utils-finalizers"))
        ];
        buildable = true;
      };
      tests = {
        "thread-utils-context-test" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
            (hsPkgs."ghc-prim" or (errorHandler.buildDepError "ghc-prim"))
            (hsPkgs."hspec" or (errorHandler.buildDepError "hspec"))
            (hsPkgs."hspec-expectations" or (errorHandler.buildDepError "hspec-expectations"))
            (hsPkgs."thread-utils-context" or (errorHandler.buildDepError "thread-utils-context"))
            (hsPkgs."thread-utils-finalizers" or (errorHandler.buildDepError "thread-utils-finalizers"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/thread-utils-context-0.3.0.4.tar.gz";
      sha256 = "a6144f962b54b4e3afaf2a26987701967e526afa700d6188aed4474032c580fc";
    });
  }) // {
    package-description-override = "cabal-version: 1.12\n\n-- This file has been generated from package.yaml by hpack version 0.35.2.\n--\n-- see: https://github.com/sol/hpack\n\nname:           thread-utils-context\nversion:        0.3.0.4\nsynopsis:       Garbage-collected thread local storage\ndescription:    Please see the README on GitHub at <https://github.com/iand675/thread-utils-context#readme>\ncategory:       Concurrency\nhomepage:       https://github.com/iand675/thread-utils#readme\nbug-reports:    https://github.com/iand675/thread-utils/issues\nauthor:         Ian Duncan\nmaintainer:     ian@iankduncan.com\ncopyright:      2023 Ian Duncan\nlicense:        BSD3\nlicense-file:   LICENSE\nbuild-type:     Simple\nextra-source-files:\n    README.md\n    ChangeLog.md\n\nsource-repository head\n  type: git\n  location: https://github.com/iand675/thread-utils\n\nflag debug\n  description: Whether to enable some additional hooks to debug issues\n  manual: True\n  default: False\n\nlibrary\n  exposed-modules:\n      Control.Concurrent.Thread.Storage\n  other-modules:\n      Paths_thread_utils_context\n  hs-source-dirs:\n      src\n  build-depends:\n      base >=4.7 && <5\n    , containers\n    , ghc-prim\n    , thread-utils-finalizers\n  default-language: Haskell2010\n  if flag(debug)\n    cpp-options: -DDEBUG_HOOKS\n\ntest-suite thread-utils-context-test\n  type: exitcode-stdio-1.0\n  main-is: Spec.hs\n  other-modules:\n      Paths_thread_utils_context\n  hs-source-dirs:\n      test\n  ghc-options: -threaded -rtsopts -with-rtsopts=-N\n  build-depends:\n      base >=4.7 && <5\n    , containers\n    , ghc-prim\n    , hspec\n    , hspec-expectations\n    , thread-utils-context\n    , thread-utils-finalizers\n  default-language: Haskell2010\n";
  }