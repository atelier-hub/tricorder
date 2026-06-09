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
      specVersion = "2.2";
      identifier = { name = "attoparsec-aeson"; version = "2.2.2.0"; };
      license = "BSD-3-Clause";
      copyright = "(c) 2011-2016 Bryan O'Sullivan\n(c) 2011 MailRank, Inc.";
      maintainer = "Oleg Grenrus <oleg.grenrus@iki.fi>";
      author = "Bryan O'Sullivan <bos@serpentine.com>";
      homepage = "https://github.com/haskell/aeson";
      url = "";
      synopsis = "Parsing of aeson's Value with attoparsec";
      description = "Parsing of aeson's Value with attoparsec, originally from aeson.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."aeson" or (errorHandler.buildDepError "aeson"))
          (hsPkgs."attoparsec" or (errorHandler.buildDepError "attoparsec"))
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          (hsPkgs."character-ps" or (errorHandler.buildDepError "character-ps"))
          (hsPkgs."integer-conversion" or (errorHandler.buildDepError "integer-conversion"))
          (hsPkgs."primitive" or (errorHandler.buildDepError "primitive"))
          (hsPkgs."scientific" or (errorHandler.buildDepError "scientific"))
          (hsPkgs."text" or (errorHandler.buildDepError "text"))
          (hsPkgs."vector" or (errorHandler.buildDepError "vector"))
        ];
        buildable = true;
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/attoparsec-aeson-2.2.2.0.tar.gz";
      sha256 = "fe9b2c23a16fe1ff8f41c329940cccc80aca7ac6a9ea314f7a77cf142d8f9edd";
    });
  }) // {
    package-description-override = "cabal-version: 2.2\nname:          attoparsec-aeson\nversion:       2.2.2.0\nsynopsis:      Parsing of aeson's Value with attoparsec\ndescription:\n  Parsing of aeson's Value with attoparsec, originally from aeson.\n\nlicense:       BSD-3-Clause\nlicense-file:  LICENSE\ncategory:      Parsing\ncopyright:\n  (c) 2011-2016 Bryan O'Sullivan\n  (c) 2011 MailRank, Inc.\n\nauthor:        Bryan O'Sullivan <bos@serpentine.com>\nmaintainer:    Oleg Grenrus <oleg.grenrus@iki.fi>\nstability:     experimental\nhomepage:      https://github.com/haskell/aeson\nbug-reports:   https://github.com/haskell/aeson/issues\nbuild-type:    Simple\ntested-with:\n  GHC ==8.6.5\n   || ==8.8.4\n   || ==8.10.7\n   || ==9.0.2\n   || ==9.2.8\n   || ==9.4.8\n   || ==9.6.5\n   || ==9.8.2\n   || ==9.10.1\n\nlibrary\n  hs-source-dirs:   src\n  default-language: Haskell2010\n  ghc-options:      -Wall\n  exposed-modules:\n    Data.Aeson.Parser\n    Data.Aeson.Parser.Internal\n\n  other-modules:\n    Data.Aeson.Internal.ByteString\n    Data.Aeson.Internal.Text\n\n  build-depends:\n    , aeson               >=2.2.2.0  && <2.3\n    , attoparsec          >=0.14.2   && <0.15\n    , base                >=4.12.0.0 && <5\n    , bytestring          >=0.10.8.2 && <0.13\n    , character-ps        ^>=0.1\n    , integer-conversion  >=0.1      && <0.2\n    , primitive           >=0.8.0.0  && <0.10\n    , scientific          >=0.3.7.0  && <0.4\n    , text                >=1.2.3.0  && <1.3  || >=2.0 && <2.2\n    , vector              >=0.12.0.1 && <0.14\n\nsource-repository head\n  type:     git\n  location: git://github.com/haskell/aeson.git\n  subdir:   attoparsec-aeson\n";
  }