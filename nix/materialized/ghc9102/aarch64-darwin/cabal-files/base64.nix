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
      specVersion = "2.0";
      identifier = { name = "base64"; version = "1.0"; };
      license = "BSD-3-Clause";
      copyright = "(c) 2019-2023 Emily Pillmore";
      maintainer = "Emily Pillmore <emilypi@cohomolo.gy>\n, Sofia-m-a <https://github.com/sofia-m-a>";
      author = "Emily Pillmore";
      homepage = "https://github.com/emilypi/base64";
      url = "";
      synopsis = "A modern Base64 library";
      description = "A performant, featureful RFC 4648 and 7049-compliant Base64 implementation";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          (hsPkgs."deepseq" or (errorHandler.buildDepError "deepseq"))
          (hsPkgs."text" or (errorHandler.buildDepError "text"))
          (hsPkgs."text-short" or (errorHandler.buildDepError "text-short"))
        ];
        buildable = true;
      };
      tests = {
        "base64-tests" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."base64" or (errorHandler.buildDepError "base64"))
            (hsPkgs."base64-bytestring" or (errorHandler.buildDepError "base64-bytestring"))
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
            (hsPkgs."base64" or (errorHandler.buildDepError "base64"))
            (hsPkgs."base64-bytestring" or (errorHandler.buildDepError "base64-bytestring"))
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
      url = "http://hackage.haskell.org/package/base64-1.0.tar.gz";
      sha256 = "7942239f1804945fd6d319a953f26c53b64518076cd294141fda983f2ff1b2b6";
    });
  }) // {
    package-description-override = "cabal-version:   2.0\r\nx-revision: 2\r\nname:            base64\r\nversion:         1.0\r\nsynopsis:        A modern Base64 library\r\ndescription:\r\n  A performant, featureful RFC 4648 and 7049-compliant Base64 implementation\r\n\r\nhomepage:        https://github.com/emilypi/base64\r\nbug-reports:     https://github.com/emilypi/base64/issues\r\nlicense:         BSD3\r\nlicense-file:    LICENSE\r\nauthor:          Emily Pillmore\r\nmaintainer:      Emily Pillmore <emilypi@cohomolo.gy>\r\n               , Sofia-m-a <https://github.com/sofia-m-a>\r\ncopyright:       (c) 2019-2023 Emily Pillmore\r\ncategory:        Data\r\nbuild-type:      Simple\r\nextra-doc-files:\r\n  CHANGELOG.md\r\n  README.md\r\n  MIGRATION-1.0.md\r\n\r\ntested-with:     GHC ==8.10.7 || ==9.0.2 || ==9.2.8 || ==9.4.8 || ==9.6.5 || ==9.8.2 || ==9.10.1\r\n\r\nsource-repository head\r\n  type:     git\r\n  location: https://github.com/emilypi/base64.git\r\n\r\nlibrary\r\n  exposed-modules:\r\n    Data.Base64.Types\r\n    Data.ByteString.Base64\r\n    Data.ByteString.Base64.URL\r\n    Data.ByteString.Lazy.Base64\r\n    Data.ByteString.Lazy.Base64.URL\r\n    Data.ByteString.Short.Base64\r\n    Data.ByteString.Short.Base64.URL\r\n    Data.Text.Encoding.Base64\r\n    Data.Text.Encoding.Base64.Error\r\n    Data.Text.Encoding.Base64.URL\r\n    Data.Text.Lazy.Encoding.Base64\r\n    Data.Text.Lazy.Encoding.Base64.URL\r\n    Data.Text.Short.Encoding.Base64\r\n    Data.Text.Short.Encoding.Base64.URL\r\n\r\n  other-modules:\r\n    Data.Base64.Types.Internal\r\n    Data.ByteString.Base64.Internal\r\n    Data.ByteString.Base64.Internal.Head\r\n    Data.ByteString.Base64.Internal.Tables\r\n    Data.ByteString.Base64.Internal.Tail\r\n    Data.ByteString.Base64.Internal.Utils\r\n    Data.ByteString.Base64.Internal.W16.Loop\r\n    Data.ByteString.Base64.Internal.W64.Loop\r\n\r\n  build-depends:\r\n      base           >=4.14     && <4.22\r\n    , bytestring     >=0.10     && <0.13\r\n    , deepseq        >=1.4.4.0  && <1.6\r\n    , text           >=2.0      && <2.3\r\n    , text-short     ^>=0.1\r\n\r\n  hs-source-dirs:   src\r\n  default-language: Haskell2010\r\n  ghc-options:      -Wall\r\n\r\ntest-suite base64-tests\r\n  default-language: Haskell2010\r\n  type:             exitcode-stdio-1.0\r\n  hs-source-dirs:   test\r\n  other-modules:    Internal\r\n  main-is:          Main.hs\r\n  build-depends:\r\n      base               >=4.14 && <4.22\r\n    , base64\r\n    , base64-bytestring\r\n    , bytestring         >=0.10\r\n    , QuickCheck\r\n    , random-bytestring\r\n    , tasty\r\n    , tasty-hunit\r\n    , tasty-quickcheck\r\n    , text               >=2.0\r\n    , text-short\r\n\r\n  ghc-options:      -Wall -threaded -with-rtsopts=-N\r\n\r\nbenchmark bench\r\n  default-language: Haskell2010\r\n  type:             exitcode-stdio-1.0\r\n  hs-source-dirs:   benchmarks\r\n  main-is:          Base64Bench.hs\r\n  build-depends:\r\n      base               >=4.14 && <4.22\r\n    , base64\r\n    , base64-bytestring\r\n    , bytestring         >=0.10\r\n    , criterion\r\n    , deepseq\r\n    , random-bytestring\r\n    , text               >=2.0\r\n\r\n  ghc-options:      -Wall -rtsopts\r\n";
  }