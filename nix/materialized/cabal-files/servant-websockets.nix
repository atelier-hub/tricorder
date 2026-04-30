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
      identifier = { name = "servant-websockets"; version = "2.0.0"; };
      license = "BSD-3-Clause";
      copyright = "2017 Lorenz Moesenlechner";
      maintainer = "moesenle@gmail.com";
      author = "Lorenz Moesenlechner";
      homepage = "https://github.com/moesenle/servant-websockets#readme";
      url = "";
      synopsis = "Small library providing WebSocket endpoints for servant.";
      description = "Small library providing WebSocket endpoints for servant.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."aeson" or (errorHandler.buildDepError "aeson"))
          (hsPkgs."async" or (errorHandler.buildDepError "async"))
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          (hsPkgs."conduit" or (errorHandler.buildDepError "conduit"))
          (hsPkgs."exceptions" or (errorHandler.buildDepError "exceptions"))
          (hsPkgs."resourcet" or (errorHandler.buildDepError "resourcet"))
          (hsPkgs."monad-control" or (errorHandler.buildDepError "monad-control"))
          (hsPkgs."servant-server" or (errorHandler.buildDepError "servant-server"))
          (hsPkgs."text" or (errorHandler.buildDepError "text"))
          (hsPkgs."wai" or (errorHandler.buildDepError "wai"))
          (hsPkgs."wai-websockets" or (errorHandler.buildDepError "wai-websockets"))
          (hsPkgs."warp" or (errorHandler.buildDepError "warp"))
          (hsPkgs."websockets" or (errorHandler.buildDepError "websockets"))
        ];
        buildable = true;
      };
      exes = {
        "websocket-echo" = {
          depends = [
            (hsPkgs."aeson" or (errorHandler.buildDepError "aeson"))
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."conduit" or (errorHandler.buildDepError "conduit"))
            (hsPkgs."servant-server" or (errorHandler.buildDepError "servant-server"))
            (hsPkgs."servant-websockets" or (errorHandler.buildDepError "servant-websockets"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
            (hsPkgs."wai" or (errorHandler.buildDepError "wai"))
            (hsPkgs."warp" or (errorHandler.buildDepError "warp"))
          ];
          buildable = true;
        };
        "websocket-stream" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."conduit" or (errorHandler.buildDepError "conduit"))
            (hsPkgs."servant-server" or (errorHandler.buildDepError "servant-server"))
            (hsPkgs."servant-websockets" or (errorHandler.buildDepError "servant-websockets"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
            (hsPkgs."wai" or (errorHandler.buildDepError "wai"))
            (hsPkgs."warp" or (errorHandler.buildDepError "warp"))
            (hsPkgs."websockets" or (errorHandler.buildDepError "websockets"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/servant-websockets-2.0.0.tar.gz";
      sha256 = "c4262b5d5a01a692d8d9ca4abd735abe1ce7288ac456f5e819b5c358adbe43f7";
    });
  }) // {
    package-description-override = "name:                servant-websockets\nversion:             2.0.0\nhomepage:            https://github.com/moesenle/servant-websockets#readme\nsynopsis:            Small library providing WebSocket endpoints for servant.\ndescription:         Small library providing WebSocket endpoints for servant.\nlicense:             BSD3\nlicense-file:        LICENSE\nauthor:              Lorenz Moesenlechner\nmaintainer:          moesenle@gmail.com\ncopyright:           2017 Lorenz Moesenlechner\ncategory:            Servant, Web\nbuild-type:          Simple\nextra-source-files:  README.md CHANGELOG.md\ncabal-version:       >=1.10\n\nlibrary\n  hs-source-dirs:      src\n  exposed-modules:     Servant.API.WebSocket\n                     , Servant.API.WebSocketConduit\n  build-depends:       aeson\n                     , async\n                     , base >= 4.7 && < 5\n                     , bytestring\n                     , conduit\n                     , exceptions\n                     , resourcet\n                     , monad-control\n                     , servant-server\n                     , text\n                     , wai\n                     , wai-websockets\n                     , warp\n                     , websockets\n  ghc-options:         -Wall\n  default-language:    Haskell2010\n\nexecutable websocket-echo\n  hs-source-dirs:      examples\n  main-is:             Echo.hs\n  ghc-options:         -threaded -rtsopts -with-rtsopts=-N\n  build-depends:       aeson\n                     , base\n                     , conduit\n                     , servant-server\n                     , servant-websockets\n                     , text\n                     , wai\n                     , warp\n  default-language:    Haskell2010\n\nexecutable websocket-stream\n  hs-source-dirs:      examples\n  main-is:             Stream.hs\n  ghc-options:         -threaded -rtsopts -with-rtsopts=-N\n  build-depends:       base\n                     , conduit\n                     , servant-server\n                     , servant-websockets\n                     , text\n                     , wai\n                     , warp\n                     , websockets\n  default-language:    Haskell2010\n\nsource-repository head\n  type:     git\n  location: https://github.com/moesenle/servant-websockets\n";
  }