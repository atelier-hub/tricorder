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
      identifier = { name = "base16"; version = "1.0"; };
      license = "BSD-3-Clause";
      copyright = "(c) 2020-2023 Emily Pillmore";
      maintainer = "emilypi@cohomolo.gy";
      author = "Emily Pillmore";
      homepage = "https://github.com/emilypi/base16";
      url = "";
      synopsis = "Fast RFC 4648-compliant Base16 encoding";
      description = "RFC 4648-compliant Base16 encodings and decodings.\nThis library provides performant encoding and decoding primitives, as well as support for textual values.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          (hsPkgs."deepseq" or (errorHandler.buildDepError "deepseq"))
          (hsPkgs."primitive" or (errorHandler.buildDepError "primitive"))
          (hsPkgs."text" or (errorHandler.buildDepError "text"))
          (hsPkgs."text-short" or (errorHandler.buildDepError "text-short"))
        ];
        buildable = true;
      };
      tests = {
        "base16-tests" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."base16" or (errorHandler.buildDepError "base16"))
            (hsPkgs."base16-bytestring" or (errorHandler.buildDepError "base16-bytestring"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."QuickCheck" or (errorHandler.buildDepError "QuickCheck"))
            (hsPkgs."random-bytestring" or (errorHandler.buildDepError "random-bytestring"))
            (hsPkgs."tasty" or (errorHandler.buildDepError "tasty"))
            (hsPkgs."tasty-hunit" or (errorHandler.buildDepError "tasty-hunit"))
            (hsPkgs."tasty-quickcheck" or (errorHandler.buildDepError "tasty-quickcheck"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
            (hsPkgs."text-short" or (errorHandler.buildDepError "text-short"))
          ];
          buildable = true;
        };
      };
      benchmarks = {
        "bench" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."base16" or (errorHandler.buildDepError "base16"))
            (hsPkgs."base16-bytestring" or (errorHandler.buildDepError "base16-bytestring"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."criterion" or (errorHandler.buildDepError "criterion"))
            (hsPkgs."deepseq" or (errorHandler.buildDepError "deepseq"))
            (hsPkgs."random-bytestring" or (errorHandler.buildDepError "random-bytestring"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/base16-1.0.tar.gz";
      sha256 = "86366364910b78609677817cf3f987bf1690e1f75bba04bc91a5ed993d619cde";
    });
  }) // {
    package-description-override = "cabal-version:   3.0\r\nname:            base16\r\nx-revision: 3\r\nversion:         1.0\r\nsynopsis:        Fast RFC 4648-compliant Base16 encoding\r\ndescription:\r\n  RFC 4648-compliant Base16 encodings and decodings.\r\n  This library provides performant encoding and decoding primitives, as well as support for textual values.\r\n\r\nhomepage:        https://github.com/emilypi/base16\r\nbug-reports:     https://github.com/emilypi/base16/issues\r\nlicense:         BSD-3-Clause\r\nlicense-file:    LICENSE\r\nauthor:          Emily Pillmore\r\nmaintainer:      emilypi@cohomolo.gy\r\ncopyright:       (c) 2020-2023 Emily Pillmore\r\ncategory:        Data\r\nbuild-type:      Simple\r\nextra-doc-files:\r\n  CHANGELOG.md\r\n  README.md\r\n  MIGRATION-1.0.md\r\n\r\ntested-with:\r\n  GHC ==8.10.7\r\n   || ==9.0.2\r\n   || ==9.2.5\r\n   || ==9.4.5\r\n   || ==9.6.4\r\n   || ==9.8.1\r\n   || ==9.10.1\r\n   || ==9.12.1\r\n\r\nsource-repository head\r\n  type:     git\r\n  location: https://github.com/emilypi/base16.git\r\n\r\nlibrary\r\n  exposed-modules:\r\n    Data.Base16.Types\r\n    Data.ByteString.Base16\r\n    Data.ByteString.Lazy.Base16\r\n    Data.ByteString.Short.Base16\r\n    Data.Text.Encoding.Base16\r\n    Data.Text.Encoding.Base16.Error\r\n    Data.Text.Lazy.Encoding.Base16\r\n    Data.Text.Short.Encoding.Base16\r\n\r\n  other-modules:\r\n    Data.Base16.Types.Internal\r\n    Data.ByteString.Base16.Internal.Head\r\n    Data.ByteString.Base16.Internal.Utils\r\n    Data.ByteString.Base16.Internal.W16.Loop\r\n    Data.ByteString.Base16.Internal.W16.ShortLoop\r\n\r\n  build-depends:\r\n      base        >=4.14 && <4.22\r\n    , bytestring  >=0.11 && <0.13\r\n    , deepseq     >=1.4.4.0 && <1.6\r\n    , primitive   >=0.6  && <0.10\r\n    , text        >= 2.0 && <2.2\r\n    , text-short  ^>=0.1\r\n\r\n  hs-source-dirs:   src\r\n  default-language: Haskell2010\r\n  ghc-options:      -Wall\r\n\r\ntest-suite base16-tests\r\n  other-modules:    Internal\r\n  default-language: Haskell2010\r\n  type:             exitcode-stdio-1.0\r\n  hs-source-dirs:   test\r\n  main-is:          Main.hs\r\n  build-depends:\r\n      base               >=4.14 && <4.22\r\n    , base16\r\n    , base16-bytestring  >=1.0\r\n    , bytestring         >=0.11\r\n    , QuickCheck\r\n    , random-bytestring\r\n    , tasty\r\n    , tasty-hunit\r\n    , tasty-quickcheck\r\n    , text               >=2.0\r\n    , text-short\r\n\r\nbenchmark bench\r\n  default-language: Haskell2010\r\n  type:             exitcode-stdio-1.0\r\n  hs-source-dirs:   benchmarks\r\n  main-is:          Base16Bench.hs\r\n  build-depends:\r\n      base               >=4.14 && <4.22\r\n    , base16\r\n    , base16-bytestring  >=1.0\r\n    , bytestring         >=0.11\r\n    , criterion\r\n    , deepseq\r\n    , random-bytestring\r\n    , text               >=2.0\r\n";
  }