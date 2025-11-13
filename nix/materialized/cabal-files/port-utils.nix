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
      identifier = { name = "port-utils"; version = "0.2.1.0"; };
      license = "BSD-3-Clause";
      copyright = "2018 Jonathan Fischoff";
      maintainer = "jonathangfischoff@gmail.com";
      author = "Jonathan Fischoff";
      homepage = "https://github.com/jfischoff/port-utils#readme";
      url = "";
      synopsis = "Utilities for creating and waiting on ports";
      description = "Utilities for creating and waiting on ports. . @openFreePort@ will create a socket bound to a random port (like @warp@'s @openFreePort@). . @wait@ will attempt to connect to given host and port repeatedly until successful. .";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."network" or (errorHandler.buildDepError "network"))
        ];
        buildable = true;
      };
      tests = {
        "unit-test" = {
          depends = [
            (hsPkgs."async" or (errorHandler.buildDepError "async"))
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."hspec" or (errorHandler.buildDepError "hspec"))
            (hsPkgs."network" or (errorHandler.buildDepError "network"))
            (hsPkgs."port-utils" or (errorHandler.buildDepError "port-utils"))
            (hsPkgs."stm" or (errorHandler.buildDepError "stm"))
            (hsPkgs."transformers" or (errorHandler.buildDepError "transformers"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/port-utils-0.2.1.0.tar.gz";
      sha256 = "b6f830946a9daa829bb14dc7f105f28ae2cfa2ee8540af8550e3c975ac7117de";
    });
  }) // {
    package-description-override = "cabal-version: 1.12\n\n-- This file has been generated from package.yaml by hpack version 0.31.1.\n--\n-- see: https://github.com/sol/hpack\n--\n-- hash: ea761433564c3d41b9bd1c895dc3c46f05ee75b16c4e1868c6bdade55f4afaee\n\nname:           port-utils\nversion:        0.2.1.0\nsynopsis:       Utilities for creating and waiting on ports\ndescription:    Utilities for creating and waiting on ports. . @openFreePort@ will create a socket bound to a random port (like @warp@'s @openFreePort@). . @wait@ will attempt to connect to given host and port repeatedly until successful. .\nhomepage:       https://github.com/jfischoff/port-utils#readme\nbug-reports:    https://github.com/jfischoff/port-utils/issues\nauthor:         Jonathan Fischoff\nmaintainer:     jonathangfischoff@gmail.com\ncopyright:      2018 Jonathan Fischoff\nlicense:        BSD3\nlicense-file:   LICENSE\nbuild-type:     Simple\nextra-source-files:\n    README.md\n    ChangeLog.md\n\nsource-repository head\n  type: git\n  location: https://github.com/jfischoff/port-utils\n\nlibrary\n  exposed-modules:\n      Network.Socket.Free\n      Network.Socket.Wait\n      Network.Socket.Wait.Internal\n  other-modules:\n      Paths_port_utils\n  hs-source-dirs:\n      src\n  default-extensions: ScopedTypeVariables RecordWildCards LambdaCase UndecidableInstances TypeSynonymInstances FlexibleInstances\n  ghc-options: -Wall\n  build-depends:\n      base >=4.7 && <5\n    , network\n  default-language: Haskell2010\n\ntest-suite unit-test\n  type: exitcode-stdio-1.0\n  main-is: Spec.hs\n  other-modules:\n      Tests.Network.Socket.WaitSpec\n      Paths_port_utils\n  hs-source-dirs:\n      test\n  default-extensions: ScopedTypeVariables RecordWildCards LambdaCase UndecidableInstances TypeSynonymInstances FlexibleInstances\n  ghc-options: -threaded -rtsopts -with-rtsopts=-N\n  build-depends:\n      async\n    , base >=4.7 && <5\n    , hspec\n    , network\n    , port-utils\n    , stm\n    , transformers\n  default-language: Haskell2010\n";
  }