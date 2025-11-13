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
      identifier = { name = "generically"; version = "0.1.1"; };
      license = "BSD-3-Clause";
      copyright = "2022 Oleg Grenrus";
      maintainer = "Oleg Grenrus <oleg.grenrus@iki.fi>";
      author = "Oleg Grenrus";
      homepage = "";
      url = "";
      synopsis = "Generically newtype to use with DerivingVia";
      description = "This is a compatibility package as @Generically@ and @Generically1@ newtypes\nare available since @base-4.17@ in 'GHC.Generics'.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
        ] ++ pkgs.lib.optional (compiler.isGhc && compiler.version.ge "9.4" && !(compiler.isGhc && compiler.version.ge "9.6")) (hsPkgs."base-orphans" or (errorHandler.buildDepError "base-orphans"));
        buildable = true;
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/generically-0.1.1.tar.gz";
      sha256 = "04c5a436bec4b041f71a733f56a1bd7f435f63dde8d3eb5c1f48d55b4dbc43cf";
    });
  }) // {
    package-description-override = "cabal-version:      1.12\r\nname:               generically\r\nversion:            0.1.1\r\nx-revision: 4\r\nsynopsis:           Generically newtype to use with DerivingVia\r\ndescription:\r\n  This is a compatibility package as @Generically@ and @Generically1@ newtypes\r\n  are available since @base-4.17@ in 'GHC.Generics'.\r\n\r\nbug-reports:        https://github.com/haskell-compat/generically/issues\r\nauthor:             Oleg Grenrus\r\nmaintainer:         Oleg Grenrus <oleg.grenrus@iki.fi>\r\ncopyright:          2022 Oleg Grenrus\r\nlicense:            BSD3\r\nlicense-file:       LICENSE\r\ncategory:           Generics\r\nbuild-type:         Simple\r\nextra-source-files: CHANGELOG.md\r\ntested-with:\r\n  GHC ==8.0.2\r\n   || ==8.2.2\r\n   || ==8.4.4\r\n   || ==8.6.5\r\n   || ==8.8.4\r\n   || ==8.10.7\r\n   || ==9.0.2\r\n   || ==9.2.8\r\n   || ==9.4.7\r\n   || ==9.6.3\r\n   || ==9.8.1\r\n\r\nsource-repository head\r\n  type:     git\r\n  location: https://github.com/haskell-compat/generically.git\r\n\r\nlibrary\r\n  default-language: Haskell2010\r\n  build-depends:    base >=4.9 && <4.22\r\n  if impl(ghc >= 9.4) && !impl(ghc >= 9.6)\r\n    build-depends:  base-orphans >=0.8.8 && <0.10\r\n  hs-source-dirs:   src\r\n  exposed-modules:  GHC.Generics.Generically\r\n";
  }