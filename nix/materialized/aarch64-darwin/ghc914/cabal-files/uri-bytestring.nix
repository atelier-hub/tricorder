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
    flags = { lib-werror = false; };
    package = {
      specVersion = "1.12";
      identifier = { name = "uri-bytestring"; version = "0.4.0.1"; };
      license = "BSD-3-Clause";
      copyright = "Soostone Inc.";
      maintainer = "Michael Xavier <michael.xavier@soostone.com>";
      author = "Doug Beardsley, Michael Xavier";
      homepage = "https://github.com/Soostone/uri-bytestring";
      url = "";
      synopsis = "Haskell URI parsing as ByteStrings";
      description = "uri-bytestring aims to be an RFC3986 compliant URI parser that uses efficient ByteStrings for parsing and representing the URI data.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."attoparsec" or (errorHandler.buildDepError "attoparsec"))
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          (hsPkgs."blaze-builder" or (errorHandler.buildDepError "blaze-builder"))
          (hsPkgs."template-haskell" or (errorHandler.buildDepError "template-haskell"))
          (hsPkgs."th-lift-instances" or (errorHandler.buildDepError "th-lift-instances"))
          (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
        ] ++ pkgs.lib.optionals (!(compiler.isGhc && compiler.version.ge "8")) [
          (hsPkgs."fail" or (errorHandler.buildDepError "fail"))
          (hsPkgs."th-lift" or (errorHandler.buildDepError "th-lift"))
          (hsPkgs."semigroups" or (errorHandler.buildDepError "semigroups"))
        ];
        buildable = true;
      };
      tests = {
        "test" = {
          depends = [
            (hsPkgs."uri-bytestring" or (errorHandler.buildDepError "uri-bytestring"))
            (hsPkgs."HUnit" or (errorHandler.buildDepError "HUnit"))
            (hsPkgs."tasty" or (errorHandler.buildDepError "tasty"))
            (hsPkgs."tasty-hunit" or (errorHandler.buildDepError "tasty-hunit"))
            (hsPkgs."hedgehog" or (errorHandler.buildDepError "hedgehog"))
            (hsPkgs."tasty-hedgehog" or (errorHandler.buildDepError "tasty-hedgehog"))
            (hsPkgs."attoparsec" or (errorHandler.buildDepError "attoparsec"))
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."base-compat" or (errorHandler.buildDepError "base-compat"))
            (hsPkgs."blaze-builder" or (errorHandler.buildDepError "blaze-builder"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."transformers" or (errorHandler.buildDepError "transformers"))
            (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
            (hsPkgs."safe" or (errorHandler.buildDepError "safe"))
          ] ++ pkgs.lib.optional (!(compiler.isGhc && compiler.version.ge "8")) (hsPkgs."semigroups" or (errorHandler.buildDepError "semigroups"));
          buildable = true;
        };
      };
      benchmarks = {
        "bench" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."uri-bytestring" or (errorHandler.buildDepError "uri-bytestring"))
            (hsPkgs."criterion" or (errorHandler.buildDepError "criterion"))
            (hsPkgs."deepseq" or (errorHandler.buildDepError "deepseq"))
            (hsPkgs."deepseq-generics" or (errorHandler.buildDepError "deepseq-generics"))
            (hsPkgs."network-uri" or (errorHandler.buildDepError "network-uri"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."blaze-builder" or (errorHandler.buildDepError "blaze-builder"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/uri-bytestring-0.4.0.1.tar.gz";
      sha256 = "223cfd93f497ad9edbbea4cdb4ac5b286a100ab7819dbf4e5640567db0a87975";
    });
  }) // {
    package-description-override = "name:                uri-bytestring\nversion:             0.4.0.1\nsynopsis:            Haskell URI parsing as ByteStrings\ndescription: uri-bytestring aims to be an RFC3986 compliant URI parser that uses efficient ByteStrings for parsing and representing the URI data.\nlicense:             BSD3\nlicense-files:       LICENSE\n                   , licenses/http-types/LICENSE\nauthor:              Doug Beardsley, Michael Xavier\nmaintainer:          Michael Xavier <michael.xavier@soostone.com>\ncopyright:           Soostone Inc.\ncategory:            Web\nbuild-type:          Simple\ncabal-version:       1.16\nhomepage:            https://github.com/Soostone/uri-bytestring\nbug-reports:         https://github.com/Soostone/uri-bytestring/issues\nTested-With:         GHC == 7.8.4\n                   , GHC == 7.10.1\n                   , GHC == 8.0.2\n                   , GHC == 8.2.1\n                   , GHC == 8.4.1\nextra-source-files:\n  README.md\n  CONTRIBUTING.md\n  changelog.md\n  bench/*.hs\n\nflag lib-Werror\n  default: False\n  manual: True\n\nlibrary\n  exposed-modules:\n    URI.ByteString\n    URI.ByteString.QQ\n  other-modules:\n    URI.ByteString.Lens\n    URI.ByteString.Types\n    URI.ByteString.Internal\n\n  build-depends:\n\n      attoparsec       >= 0.13.1.0\n    , base             >= 4.6     && < 5\n    , bytestring       >= 0.9.1\n    , blaze-builder    >= 0.3.0.0\n    , template-haskell >= 2.9\n    , th-lift-instances >= 0.1.8\n    , containers\n\n  hs-source-dirs:      src\n  default-language:    Haskell2010\n\n  if impl(ghc >= 7.8)\n    cpp-options: -DWITH_TYPEABLE\n\n  if !impl(ghc >= 8)\n    cpp-options: -DLIFT_COMPAT\n    build-depends:\n      fail >= 4.9 && < 5,\n      th-lift >= 0.7.5 && < 0.8,\n      semigroups >= 0.16.2.2 && <0.19\n\n  if flag(lib-Werror)\n    ghc-options: -Werror\n\n  ghc-options: -Wall\n\ntest-suite test\n  type: exitcode-stdio-1.0\n  main-is: Main.hs\n  other-modules:\n    URI.ByteString.Generators\n    URI.ByteStringTests\n    URI.ByteStringQQTests\n  hs-source-dirs: test\n  build-depends:\n      uri-bytestring\n    , HUnit\n    , tasty\n    , tasty-hunit\n    , hedgehog\n    , tasty-hedgehog\n    , attoparsec\n    , base\n    , base-compat >= 0.7.0\n    , blaze-builder\n    , bytestring\n    , transformers\n    , containers\n    , safe\n\n  if !impl(ghc >= 8)\n    build-depends: semigroups\n\n  default-language:    Haskell2010\n\n  if flag(lib-Werror)\n    ghc-options: -Werror\n\n  ghc-options: -Wall\n\n\nbenchmark bench\n  type: exitcode-stdio-1.0\n  main-is: Main.hs\n  hs-source-dirs: bench\n  default-language:    Haskell2010\n  build-depends:\n      base\n    , uri-bytestring\n    , criterion\n    , deepseq\n    , deepseq-generics\n    , network-uri >= 2.6.0.3\n    , bytestring\n    , blaze-builder\n\nsource-repository head\n  type:     git\n  location: git://github.com/Soostone/uri-bytestring.git\n";
  }