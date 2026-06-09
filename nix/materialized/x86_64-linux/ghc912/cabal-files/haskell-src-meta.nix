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
      identifier = { name = "haskell-src-meta"; version = "0.8.15"; };
      license = "BSD-3-Clause";
      copyright = "(c) Matt Morrow";
      maintainer = "danburton.email@gmail.com";
      author = "Matt Morrow";
      homepage = "";
      url = "";
      synopsis = "Parse source to template-haskell abstract syntax.";
      description = "The translation from haskell-src-exts abstract syntax\nto template-haskell abstract syntax isn't 100% complete yet.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."haskell-src-exts" or (errorHandler.buildDepError "haskell-src-exts"))
          (hsPkgs."pretty" or (errorHandler.buildDepError "pretty"))
          (hsPkgs."syb" or (errorHandler.buildDepError "syb"))
          (hsPkgs."template-haskell" or (errorHandler.buildDepError "template-haskell"))
          (hsPkgs."th-orphans" or (errorHandler.buildDepError "th-orphans"))
        ];
        buildable = true;
      };
      tests = {
        "unit" = {
          depends = [
            (hsPkgs."HUnit" or (errorHandler.buildDepError "HUnit"))
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."haskell-src-exts" or (errorHandler.buildDepError "haskell-src-exts"))
            (hsPkgs."haskell-src-meta" or (errorHandler.buildDepError "haskell-src-meta"))
            (hsPkgs."pretty" or (errorHandler.buildDepError "pretty"))
            (hsPkgs."template-haskell" or (errorHandler.buildDepError "template-haskell"))
            (hsPkgs."tasty" or (errorHandler.buildDepError "tasty"))
            (hsPkgs."tasty-hunit" or (errorHandler.buildDepError "tasty-hunit"))
          ];
          buildable = true;
        };
        "splices" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."haskell-src-exts" or (errorHandler.buildDepError "haskell-src-exts"))
            (hsPkgs."haskell-src-meta" or (errorHandler.buildDepError "haskell-src-meta"))
            (hsPkgs."template-haskell" or (errorHandler.buildDepError "template-haskell"))
          ];
          buildable = true;
        };
        "examples" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
            (hsPkgs."haskell-src-meta" or (errorHandler.buildDepError "haskell-src-meta"))
            (hsPkgs."pretty" or (errorHandler.buildDepError "pretty"))
            (hsPkgs."syb" or (errorHandler.buildDepError "syb"))
            (hsPkgs."template-haskell" or (errorHandler.buildDepError "template-haskell"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/haskell-src-meta-0.8.15.tar.gz";
      sha256 = "26eab63199d5f112748ec7700173cf2157e18f766ac5e78ee2986c98576b0dbe";
    });
  }) // {
    package-description-override = "name:               haskell-src-meta\r\nversion:            0.8.15\r\nx-revision: 1\r\ncabal-version:      >= 1.10\r\nbuild-type:         Simple\r\nlicense:            BSD3\r\nlicense-file:       LICENSE\r\ncategory:           Language, Template Haskell\r\nauthor:             Matt Morrow\r\ncopyright:          (c) Matt Morrow\r\nmaintainer:         danburton.email@gmail.com\r\nbug-reports:        https://github.com/haskell-party/haskell-src-meta/issues\r\ntested-with:        GHC == 8.2.2, GHC == 8.4.4, GHC == 8.6.5, GHC == 8.8.4, GHC == 8.10.7, GHC == 9.0.2, GHC == 9.2.2, GHC == 9.4.1, GHC == 9.6.1, GHC == 9.8.1, GHC == 9.10.1, GHC == 9.12.1\r\nsynopsis:           Parse source to template-haskell abstract syntax.\r\ndescription:        The translation from haskell-src-exts abstract syntax\r\n                    to template-haskell abstract syntax isn't 100% complete yet.\r\n\r\nextra-source-files: ChangeLog README.md\r\n\r\nlibrary\r\n  default-language: Haskell2010\r\n  build-depends:   base >= 4.10 && < 5,\r\n                   haskell-src-exts >= 1.21 && < 1.24,\r\n                   pretty >= 1.0 && < 1.2,\r\n                   syb >= 0.1 && < 0.8,\r\n                   template-haskell >= 2.12 && < 2.25,\r\n                   th-orphans >= 0.12 && < 0.14\r\n\r\n  hs-source-dirs:  src\r\n  exposed-modules: Language.Haskell.Meta\r\n                   Language.Haskell.Meta.Extensions\r\n                   Language.Haskell.Meta.Parse\r\n                   Language.Haskell.Meta.Syntax.Translate\r\n                   Language.Haskell.Meta.Utils\r\n  other-modules:   Language.Haskell.Meta.THCompat\r\n\r\ntest-suite unit\r\n  default-language: Haskell2010\r\n  type:             exitcode-stdio-1.0\r\n  hs-source-dirs:   tests\r\n  main-is:          Main.hs\r\n\r\n  build-depends:\r\n    HUnit                >= 1.2,\r\n    base                 >= 4.10,\r\n    haskell-src-exts     >= 1.21,\r\n    haskell-src-meta,\r\n    pretty               >= 1.0,\r\n    template-haskell     >= 2.12,\r\n    tasty,\r\n    tasty-hunit\r\n\r\n\r\ntest-suite splices\r\n  default-language: Haskell2010\r\n  type:             exitcode-stdio-1.0\r\n  hs-source-dirs:   tests\r\n  main-is:          Splices.hs\r\n\r\n  build-depends:\r\n    base,\r\n    haskell-src-exts,\r\n    haskell-src-meta,\r\n    template-haskell\r\n\r\ntest-suite examples\r\n  default-language: Haskell2010\r\n  type:             exitcode-stdio-1.0\r\n  hs-source-dirs:   examples, tests\r\n  main-is:          TestExamples.hs\r\n\r\n  build-depends:\r\n    base,\r\n    containers,\r\n    haskell-src-meta,\r\n    pretty,\r\n    syb,\r\n    template-haskell\r\n\r\n\r\n  other-modules:\r\n    BF,\r\n    Hs,\r\n    HsHere,\r\n    SKI\r\n\r\nsource-repository head\r\n  type:     git\r\n  location: git://github.com/haskell-party/haskell-src-meta.git\r\n";
  }