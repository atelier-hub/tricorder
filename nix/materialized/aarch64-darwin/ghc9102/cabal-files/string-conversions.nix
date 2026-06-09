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
      identifier = { name = "string-conversions"; version = "0.4.0.1"; };
      license = "BSD-3-Clause";
      copyright = "";
      maintainer = "soenkehahn@gmail.com";
      author = "Sönke Hahn";
      homepage = "https://github.com/soenkehahn/string-conversions#readme";
      url = "";
      synopsis = "Simplifies dealing with different types for strings";
      description = "Provides a simple type class for converting values of different string types into values of other string types.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          (hsPkgs."text" or (errorHandler.buildDepError "text"))
          (hsPkgs."utf8-string" or (errorHandler.buildDepError "utf8-string"))
        ];
        buildable = true;
      };
      tests = {
        "spec" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
            (hsPkgs."utf8-string" or (errorHandler.buildDepError "utf8-string"))
            (hsPkgs."hspec" or (errorHandler.buildDepError "hspec"))
            (hsPkgs."quickcheck-instances" or (errorHandler.buildDepError "quickcheck-instances"))
            (hsPkgs."deepseq" or (errorHandler.buildDepError "deepseq"))
            (hsPkgs."QuickCheck" or (errorHandler.buildDepError "QuickCheck"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/string-conversions-0.4.0.1.tar.gz";
      sha256 = "46bcce6d9ce62c558b7658a75d9c6a62f7259d6b0473d011d8078234ad6a1994";
    });
  }) // {
    package-description-override = "-- This file has been generated from package.yaml by hpack version 0.15.0.\r\n--\r\n-- see: https://github.com/sol/hpack\r\n\r\nname:                string-conversions\r\nversion:             0.4.0.1\r\nx-revision: 1\r\nsynopsis:            Simplifies dealing with different types for strings\r\ndescription:         Provides a simple type class for converting values of different string types into values of other string types.\r\nlicense:             BSD3\r\nlicense-file:        LICENSE\r\ntested-with:         GHC == 7.6.3, GHC == 7.8.4, GHC == 7.10.1, GHC == 8.0.1\r\nauthor:              Sönke Hahn\r\nmaintainer:          soenkehahn@gmail.com\r\ncategory:            Data\r\nhomepage:            https://github.com/soenkehahn/string-conversions#readme\r\nbug-reports:         https://github.com/soenkehahn/string-conversions/issues\r\nbuild-type:          Simple\r\ncabal-version:       >= 1.10\r\n\r\nsource-repository head\r\n  type: git\r\n  location: https://github.com/soenkehahn/string-conversions\r\n\r\nlibrary\r\n  hs-source-dirs:\r\n    src\r\n  default-language: Haskell2010\r\n  build-depends:\r\n    base == 4.*,\r\n    bytestring >= 0.9,\r\n    text >= 0.11,\r\n    utf8-string >= 0.3.1\r\n  exposed-modules:\r\n    Data.String.Conversions\r\n    Data.String.Conversions.Monomorphic\r\n  ghc-options: -Wall\r\n\r\ntest-suite spec\r\n  type: exitcode-stdio-1.0\r\n  main-is: Spec.hs\r\n  hs-source-dirs:\r\n    test,\r\n    src\r\n  build-depends:\r\n    base == 4.*,\r\n    bytestring >= 0.9,\r\n    text >= 0.11,\r\n    utf8-string >= 0.3.1,\r\n    hspec,\r\n    quickcheck-instances,\r\n    deepseq,\r\n    QuickCheck\r\n  other-modules:\r\n    Data.String.ConversionsSpec\r\n    Data.String.Conversions\r\n    Data.String.Conversions.Monomorphic\r\n  default-language: Haskell2010\r\n";
  }