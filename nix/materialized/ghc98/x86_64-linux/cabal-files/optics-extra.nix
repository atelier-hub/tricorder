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
      identifier = { name = "optics-extra"; version = "0.4.2.1"; };
      license = "BSD-3-Clause";
      copyright = "";
      maintainer = "optics@well-typed.com";
      author = "Andrzej Rybczak";
      homepage = "";
      url = "";
      synopsis = "Extra utilities and instances for optics-core";
      description = "This package provides extra definitions and instances that extend the\n@<https://hackage.haskell.org/package/optics-core optics-core>@ package,\nwithout incurring too many dependencies.  See the\n@<https://hackage.haskell.org/package/optics optics>@ package for more\ndocumentation.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."array" or (errorHandler.buildDepError "array"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
          (hsPkgs."hashable" or (errorHandler.buildDepError "hashable"))
          (hsPkgs."indexed-profunctors" or (errorHandler.buildDepError "indexed-profunctors"))
          (hsPkgs."mtl" or (errorHandler.buildDepError "mtl"))
          (hsPkgs."optics-core" or (errorHandler.buildDepError "optics-core"))
          (hsPkgs."text" or (errorHandler.buildDepError "text"))
          (hsPkgs."transformers" or (errorHandler.buildDepError "transformers"))
          (hsPkgs."unordered-containers" or (errorHandler.buildDepError "unordered-containers"))
          (hsPkgs."vector" or (errorHandler.buildDepError "vector"))
          (hsPkgs."indexed-traversable-instances" or (errorHandler.buildDepError "indexed-traversable-instances"))
        ];
        buildable = true;
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/optics-extra-0.4.2.1.tar.gz";
      sha256 = "7e23a7a325e3448354614d3d958279c9ac2fdd0831ceee2808830e7a962fca41";
    });
  }) // {
    package-description-override = "cabal-version: 2.2\r\nname:          optics-extra\r\nversion:       0.4.2.1\r\nx-revision: 5\r\nlicense:       BSD-3-Clause\r\nlicense-file:  LICENSE\r\nbuild-type:    Simple\r\nmaintainer:    optics@well-typed.com\r\nauthor:        Andrzej Rybczak\r\ntested-with:   GHC ==8.2.2 || ==8.4.4 || ==8.6.5 || ==8.8.4 || ==8.10.7\r\n                || ==9.0.2 || ==9.2.8 || ==9.4.8 || ==9.6.5 || ==9.8.2\r\n                || ==9.10.1,\r\n               GHCJS ==8.4\r\nsynopsis:      Extra utilities and instances for optics-core\r\ncategory:      Data, Optics, Lenses\r\ndescription:\r\n  This package provides extra definitions and instances that extend the\r\n  @<https://hackage.haskell.org/package/optics-core optics-core>@ package,\r\n  without incurring too many dependencies.  See the\r\n  @<https://hackage.haskell.org/package/optics optics>@ package for more\r\n  documentation.\r\n\r\nextra-doc-files:\r\n  CHANGELOG.md\r\n\r\nbug-reports:   https://github.com/well-typed/optics/issues\r\nsource-repository head\r\n  type:     git\r\n  location: https://github.com/well-typed/optics.git\r\n  subdir:   optics-extra\r\n\r\ncommon language\r\n    ghc-options:        -Wall -Wcompat\r\n\r\n    default-language:   Haskell2010\r\n\r\n    default-extensions: BangPatterns\r\n                        ConstraintKinds\r\n                        DefaultSignatures\r\n                        DeriveFoldable\r\n                        DeriveFunctor\r\n                        DeriveGeneric\r\n                        DeriveTraversable\r\n                        EmptyCase\r\n                        FlexibleContexts\r\n                        FlexibleInstances\r\n                        FunctionalDependencies\r\n                        GADTs\r\n                        GeneralizedNewtypeDeriving\r\n                        InstanceSigs\r\n                        KindSignatures\r\n                        LambdaCase\r\n                        OverloadedLabels\r\n                        PatternSynonyms\r\n                        RankNTypes\r\n                        ScopedTypeVariables\r\n                        TupleSections\r\n                        TypeApplications\r\n                        TypeFamilies\r\n                        TypeOperators\r\n                        ViewPatterns\r\n\r\nlibrary\r\n  import:           language\r\n  hs-source-dirs:   src\r\n\r\n  build-depends: base                   >= 4.10      && <5\r\n               , array                  >= 0.5.2.0   && <0.6\r\n               , bytestring             >= 0.10.8    && <0.13\r\n               , containers             >= 0.5.10.2  && <0.9\r\n               , hashable               >= 1.1.1     && <1.6\r\n               , indexed-profunctors    >= 0.1       && <0.2\r\n               , mtl                    >= 2.2.2     && <2.4\r\n               , optics-core            >= 0.4.1     && <0.4.3\r\n               , text                   >= 1.2       && <1.3 || >=2.0 && <2.2\r\n               , transformers           >= 0.5       && <0.7\r\n               , unordered-containers   >= 0.2.6     && <0.3\r\n               , vector                 >= 0.11      && <0.14\r\n               , indexed-traversable-instances >=0.1 && <0.2\r\n\r\n  exposed-modules: Optics.Extra\r\n\r\n                   -- optic utilities\r\n                   Optics.At\r\n                   Optics.Cons\r\n                   Optics.Each\r\n                   Optics.Empty\r\n                   Optics.Indexed\r\n                   Optics.Passthrough\r\n                   Optics.State\r\n                   Optics.State.Operators\r\n                   Optics.View\r\n                   Optics.Zoom\r\n\r\n                   -- optics for data types\r\n                   Data.ByteString.Lazy.Optics\r\n                   Data.ByteString.Optics\r\n                   Data.ByteString.Strict.Optics\r\n                   Data.HashMap.Optics\r\n                   Data.HashSet.Optics\r\n                   Data.Text.Lazy.Optics\r\n                   Data.Text.Optics\r\n                   Data.Text.Strict.Optics\r\n                   Data.Vector.Generic.Optics\r\n                   Data.Vector.Optics\r\n\r\n                   -- internal modules\r\n                   Optics.Extra.Internal.ByteString\r\n                   Optics.Extra.Internal.Vector\r\n                   Optics.Extra.Internal.Zoom\r\n";
  }