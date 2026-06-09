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
      identifier = { name = "proto-lens"; version = "0.7.1.7"; };
      license = "BSD-3-Clause";
      copyright = "Google Inc.";
      maintainer = "proto-lens@googlegroups.com";
      author = "Judah Jacobson";
      homepage = "https://github.com/google/proto-lens#readme";
      url = "";
      synopsis = "A lens-based implementation of protocol buffers in Haskell.";
      description = "The proto-lens library provides an API for protocol buffers using modern Haskell language and library patterns.  Specifically, it provides:\n\n* Composable field accessors via lenses\n\n* Simple field name resolution/overloading via type-level literals\n\n* Type-safe reflection and encoding/decoding of messages via GADTs";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
          (hsPkgs."deepseq" or (errorHandler.buildDepError "deepseq"))
          (hsPkgs."ghc-prim" or (errorHandler.buildDepError "ghc-prim"))
          (hsPkgs."lens-family" or (errorHandler.buildDepError "lens-family"))
          (hsPkgs."parsec" or (errorHandler.buildDepError "parsec"))
          (hsPkgs."pretty" or (errorHandler.buildDepError "pretty"))
          (hsPkgs."primitive" or (errorHandler.buildDepError "primitive"))
          (hsPkgs."profunctors" or (errorHandler.buildDepError "profunctors"))
          (hsPkgs."tagged" or (errorHandler.buildDepError "tagged"))
          (hsPkgs."text" or (errorHandler.buildDepError "text"))
          (hsPkgs."transformers" or (errorHandler.buildDepError "transformers"))
          (hsPkgs."vector" or (errorHandler.buildDepError "vector"))
        ];
        buildable = true;
      };
      tests = {
        "growing_test" = {
          depends = [
            (hsPkgs."QuickCheck" or (errorHandler.buildDepError "QuickCheck"))
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."proto-lens" or (errorHandler.buildDepError "proto-lens"))
            (hsPkgs."tasty" or (errorHandler.buildDepError "tasty"))
            (hsPkgs."tasty-quickcheck" or (errorHandler.buildDepError "tasty-quickcheck"))
            (hsPkgs."vector" or (errorHandler.buildDepError "vector"))
          ];
          buildable = true;
        };
        "parser_test" = {
          depends = [
            (hsPkgs."QuickCheck" or (errorHandler.buildDepError "QuickCheck"))
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."proto-lens" or (errorHandler.buildDepError "proto-lens"))
            (hsPkgs."tasty" or (errorHandler.buildDepError "tasty"))
            (hsPkgs."tasty-quickcheck" or (errorHandler.buildDepError "tasty-quickcheck"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/proto-lens-0.7.1.7.tar.gz";
      sha256 = "5c9826a4b90d07f06470e058ef3fe63ee3123614b4705509ddbf2d5e55e7153a";
    });
  }) // {
    package-description-override = "cabal-version: 1.12\n\n-- This file has been generated from package.yaml by hpack version 0.39.1.\n--\n-- see: https://github.com/sol/hpack\n\nname:           proto-lens\nversion:        0.7.1.7\nsynopsis:       A lens-based implementation of protocol buffers in Haskell.\ndescription:    The proto-lens library provides an API for protocol buffers using modern Haskell language and library patterns.  Specifically, it provides:\n                .\n                * Composable field accessors via lenses\n                .\n                * Simple field name resolution/overloading via type-level literals\n                .\n                * Type-safe reflection and encoding/decoding of messages via GADTs\ncategory:       Data\nhomepage:       https://github.com/google/proto-lens#readme\nbug-reports:    https://github.com/google/proto-lens/issues\nauthor:         Judah Jacobson\nmaintainer:     proto-lens@googlegroups.com\ncopyright:      Google Inc.\nlicense:        BSD3\nlicense-file:   LICENSE\nbuild-type:     Simple\nextra-source-files:\n    Changelog.md\ndata-files:\n    proto-lens-imports/google/protobuf/descriptor.proto\n    proto-lens-imports/google/protobuf/compiler/plugin.proto\n\nsource-repository head\n  type: git\n  location: https://github.com/google/proto-lens\n  subdir: proto-lens\n\nlibrary\n  exposed-modules:\n      Data.ProtoLens\n      Data.ProtoLens.Combinators\n      Data.ProtoLens.Default\n      Data.ProtoLens.Encoding\n      Data.ProtoLens.Encoding.Bytes\n      Data.ProtoLens.Encoding.Growing\n      Data.ProtoLens.Encoding.Parser\n      Data.ProtoLens.Encoding.Parser.Unsafe\n      Data.ProtoLens.Encoding.Wire\n      Data.ProtoLens.Field\n      Data.ProtoLens.Labels\n      Data.ProtoLens.Message\n      Data.ProtoLens.Message.Enum\n      Data.ProtoLens.Prism\n      Data.ProtoLens.Service.Types\n      Data.ProtoLens.TextFormat\n  other-modules:\n      Data.ProtoLens.Encoding.Parser.Internal\n      Data.ProtoLens.TextFormat.Parser\n  hs-source-dirs:\n      src\n  build-depends:\n      base >=4.10 && <4.23\n    , bytestring >=0.10 && <0.14\n    , containers >=0.5 && <0.9\n    , deepseq >=1.4 && <1.6\n    , ghc-prim >=0.4 && <0.14\n    , lens-family >=1.2 && <2.2\n    , parsec ==3.1.*\n    , pretty ==1.1.*\n    , primitive >=0.6 && <0.10\n    , profunctors >=5.2 && <6.0\n    , tagged ==0.8.*\n    , text >=1.2 && <2.2\n    , transformers >=0.4 && <0.7\n    , vector >=0.11 && <0.14\n  default-language: Haskell2010\n\ntest-suite growing_test\n  type: exitcode-stdio-1.0\n  main-is: growing_test.hs\n  other-modules:\n      Paths_proto_lens\n  hs-source-dirs:\n      tests\n  build-depends:\n      QuickCheck\n    , base\n    , proto-lens\n    , tasty\n    , tasty-quickcheck\n    , vector\n  default-language: Haskell2010\n\ntest-suite parser_test\n  type: exitcode-stdio-1.0\n  main-is: parser_test.hs\n  other-modules:\n      Paths_proto_lens\n  hs-source-dirs:\n      tests\n  build-depends:\n      QuickCheck\n    , base\n    , bytestring\n    , proto-lens\n    , tasty\n    , tasty-quickcheck\n  default-language: Haskell2010\n";
  }