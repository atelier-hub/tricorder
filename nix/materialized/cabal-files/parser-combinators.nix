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
    flags = { dev = false; };
    package = {
      specVersion = "1.18";
      identifier = { name = "parser-combinators"; version = "1.3.0"; };
      license = "BSD-3-Clause";
      copyright = "";
      maintainer = "Mark Karpov <markkarpov92@gmail.com>";
      author = "Mark Karpov <markkarpov92@gmail.com>\nAlex Washburn <github@recursion.ninja>";
      homepage = "https://github.com/mrkkrp/parser-combinators";
      url = "";
      synopsis = "Lightweight package providing commonly useful parser combinators";
      description = "Lightweight package providing commonly useful parser combinators.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [ (hsPkgs."base" or (errorHandler.buildDepError "base")) ];
        buildable = true;
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/parser-combinators-1.3.0.tar.gz";
      sha256 = "9310ef0d49f8a8922acda10b1cded9854cbee04dea717effc6ee5983072e4447";
    });
  }) // {
    package-description-override = "cabal-version:   1.18\r\nname:            parser-combinators\r\nversion:         1.3.0\r\nx-revision: 1\r\nlicense:         BSD3\r\nlicense-file:    LICENSE.md\r\nmaintainer:      Mark Karpov <markkarpov92@gmail.com>\r\nauthor:\r\n    Mark Karpov <markkarpov92@gmail.com>\r\n    Alex Washburn <github@recursion.ninja>\r\n\r\ntested-with:     ghc ==8.6.5 ghc ==8.8.4 ghc ==8.10.3\r\nhomepage:        https://github.com/mrkkrp/parser-combinators\r\nbug-reports:     https://github.com/mrkkrp/parser-combinators/issues\r\nsynopsis:\r\n    Lightweight package providing commonly useful parser combinators\r\n\r\ndescription:\r\n    Lightweight package providing commonly useful parser combinators.\r\n\r\ncategory:        Parsing\r\nbuild-type:      Simple\r\nextra-doc-files:\r\n    CHANGELOG.md\r\n    README.md\r\n\r\nsource-repository head\r\n    type:     git\r\n    location: https://github.com/mrkkrp/parser-combinators.git\r\n\r\nflag dev\r\n    description: Turn on development settings.\r\n    default:     False\r\n    manual:      True\r\n\r\nlibrary\r\n    exposed-modules:\r\n        Control.Applicative.Combinators\r\n        Control.Applicative.Combinators.NonEmpty\r\n        Control.Applicative.Permutations\r\n        Control.Monad.Combinators\r\n        Control.Monad.Combinators.Expr\r\n        Control.Monad.Combinators.NonEmpty\r\n        Control.Monad.Permutations\r\n\r\n    default-language: Haskell2010\r\n    build-depends:    base >=4.12 && <5\r\n\r\n    if flag(dev)\r\n        ghc-options: -Wall -Werror\r\n\r\n    else\r\n        ghc-options: -O2 -Wall\r\n\r\n    if flag(dev)\r\n        ghc-options:\r\n            -Wcompat -Wincomplete-record-updates -Wincomplete-uni-patterns\r\n            -Wnoncanonical-monad-instances\r\n";
  }