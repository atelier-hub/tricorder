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
      identifier = { name = "proto-lens"; version = "0.7.1.6"; };
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
      url = "http://hackage.haskell.org/package/proto-lens-0.7.1.6.tar.gz";
      sha256 = "bd1daee1e6e3981e9bc6de63260c6a20cb22cf22e893f58a2cd803693dce5c8e";
    });
  }) // {
    package-description-override = "cabal-version: 1.12\r\n\r\n-- This file has been generated from package.yaml by hpack version 0.39.3.\r\n--\r\n-- see: https://github.com/sol/hpack\r\n\r\nname:           proto-lens\r\nversion:        0.7.1.6\r\nx-revision:     1\r\nsynopsis:       A lens-based implementation of protocol buffers in Haskell.\r\ndescription:    The proto-lens library provides an API for protocol buffers using modern Haskell language and library patterns.  Specifically, it provides:\r\n                .\r\n                * Composable field accessors via lenses\r\n                .\r\n                * Simple field name resolution/overloading via type-level literals\r\n                .\r\n                * Type-safe reflection and encoding/decoding of messages via GADTs\r\ncategory:       Data\r\nhomepage:       https://github.com/google/proto-lens#readme\r\nbug-reports:    https://github.com/google/proto-lens/issues\r\nauthor:         Judah Jacobson\r\nmaintainer:     proto-lens@googlegroups.com\r\ncopyright:      Google Inc.\r\nlicense:        BSD3\r\nlicense-file:   LICENSE\r\nbuild-type:     Simple\r\nextra-source-files:\r\n    Changelog.md\r\ndata-files:\r\n    proto-lens-imports/google/protobuf/descriptor.proto\r\n    proto-lens-imports/google/protobuf/compiler/plugin.proto\r\n\r\nsource-repository head\r\n  type: git\r\n  location: https://github.com/google/proto-lens\r\n  subdir: proto-lens\r\n\r\nlibrary\r\n  exposed-modules:\r\n      Data.ProtoLens\r\n      Data.ProtoLens.Combinators\r\n      Data.ProtoLens.Default\r\n      Data.ProtoLens.Encoding\r\n      Data.ProtoLens.Encoding.Bytes\r\n      Data.ProtoLens.Encoding.Growing\r\n      Data.ProtoLens.Encoding.Parser\r\n      Data.ProtoLens.Encoding.Parser.Unsafe\r\n      Data.ProtoLens.Encoding.Wire\r\n      Data.ProtoLens.Field\r\n      Data.ProtoLens.Labels\r\n      Data.ProtoLens.Message\r\n      Data.ProtoLens.Message.Enum\r\n      Data.ProtoLens.Prism\r\n      Data.ProtoLens.Service.Types\r\n      Data.ProtoLens.TextFormat\r\n  other-modules:\r\n      Data.ProtoLens.Encoding.Parser.Internal\r\n      Data.ProtoLens.TextFormat.Parser\r\n  hs-source-dirs:\r\n      src\r\n  build-depends:\r\n      base >=4.10 && <4.23\r\n    , bytestring >=0.10 && <0.13\r\n    , containers >=0.5 && <0.9\r\n    , deepseq >=1.4 && <1.6\r\n    , ghc-prim >=0.4 && <0.14\r\n    , lens-family >=1.2 && <2.2\r\n    , parsec ==3.1.*\r\n    , pretty ==1.1.*\r\n    , primitive >=0.6 && <0.10\r\n    , profunctors >=5.2 && <6.0\r\n    , tagged ==0.8.*\r\n    , text >=1.2 && <2.2\r\n    , transformers >=0.4 && <0.7\r\n    , vector >=0.11 && <0.14\r\n  default-language: Haskell2010\r\n\r\ntest-suite growing_test\r\n  type: exitcode-stdio-1.0\r\n  main-is: growing_test.hs\r\n  other-modules:\r\n      Paths_proto_lens\r\n  hs-source-dirs:\r\n      tests\r\n  build-depends:\r\n      QuickCheck\r\n    , base\r\n    , proto-lens\r\n    , tasty\r\n    , tasty-quickcheck\r\n    , vector\r\n  default-language: Haskell2010\r\n\r\ntest-suite parser_test\r\n  type: exitcode-stdio-1.0\r\n  main-is: parser_test.hs\r\n  other-modules:\r\n      Paths_proto_lens\r\n  hs-source-dirs:\r\n      tests\r\n  build-depends:\r\n      QuickCheck\r\n    , base\r\n    , bytestring\r\n    , proto-lens\r\n    , tasty\r\n    , tasty-quickcheck\r\n  default-language: Haskell2010\r\n";
  }