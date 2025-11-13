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
      specVersion = "1.18";
      identifier = { name = "opaleye"; version = "0.10.7.0"; };
      license = "BSD-3-Clause";
      copyright = "Copyright (c) 2014-2018 Purely Agile Limited; 2019-2025 Tom Ellis";
      maintainer = "Tom Ellis";
      author = "";
      homepage = "https://github.com/tomjaguarpaw/haskell-opaleye";
      url = "";
      synopsis = "An SQL-generating DSL targeting PostgreSQL";
      description = "An SQL-generating DSL targeting PostgreSQL.  Allows\nPostgres queries to be written within Haskell in a\ntypesafe and composable fashion.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."aeson" or (errorHandler.buildDepError "aeson"))
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."base16-bytestring" or (errorHandler.buildDepError "base16-bytestring"))
          (hsPkgs."case-insensitive" or (errorHandler.buildDepError "case-insensitive"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          (hsPkgs."contravariant" or (errorHandler.buildDepError "contravariant"))
          (hsPkgs."postgresql-simple" or (errorHandler.buildDepError "postgresql-simple"))
          (hsPkgs."pretty" or (errorHandler.buildDepError "pretty"))
          (hsPkgs."product-profunctors" or (errorHandler.buildDepError "product-profunctors"))
          (hsPkgs."profunctors" or (errorHandler.buildDepError "profunctors"))
          (hsPkgs."scientific" or (errorHandler.buildDepError "scientific"))
          (hsPkgs."semigroups" or (errorHandler.buildDepError "semigroups"))
          (hsPkgs."text" or (errorHandler.buildDepError "text"))
          (hsPkgs."transformers" or (errorHandler.buildDepError "transformers"))
          (hsPkgs."time-compat" or (errorHandler.buildDepError "time-compat"))
          (hsPkgs."time-locale-compat" or (errorHandler.buildDepError "time-locale-compat"))
          (hsPkgs."uuid-types" or (errorHandler.buildDepError "uuid-types"))
          (hsPkgs."void" or (errorHandler.buildDepError "void"))
        ];
        buildable = true;
      };
      tests = {
        "test" = {
          depends = [
            (hsPkgs."aeson" or (errorHandler.buildDepError "aeson"))
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
            (hsPkgs."contravariant" or (errorHandler.buildDepError "contravariant"))
            (hsPkgs."dotenv" or (errorHandler.buildDepError "dotenv"))
            (hsPkgs."multiset" or (errorHandler.buildDepError "multiset"))
            (hsPkgs."postgresql-simple" or (errorHandler.buildDepError "postgresql-simple"))
            (hsPkgs."profunctors" or (errorHandler.buildDepError "profunctors"))
            (hsPkgs."product-profunctors" or (errorHandler.buildDepError "product-profunctors"))
            (hsPkgs."QuickCheck" or (errorHandler.buildDepError "QuickCheck"))
            (hsPkgs."semigroups" or (errorHandler.buildDepError "semigroups"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
            (hsPkgs."time-compat" or (errorHandler.buildDepError "time-compat"))
            (hsPkgs."transformers" or (errorHandler.buildDepError "transformers"))
            (hsPkgs."hspec" or (errorHandler.buildDepError "hspec"))
            (hsPkgs."hspec-discover" or (errorHandler.buildDepError "hspec-discover"))
            (hsPkgs."opaleye" or (errorHandler.buildDepError "opaleye"))
          ];
          buildable = true;
        };
        "tutorial" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."postgresql-simple" or (errorHandler.buildDepError "postgresql-simple"))
            (hsPkgs."profunctors" or (errorHandler.buildDepError "profunctors"))
            (hsPkgs."product-profunctors" or (errorHandler.buildDepError "product-profunctors"))
            (hsPkgs."time" or (errorHandler.buildDepError "time"))
            (hsPkgs."opaleye" or (errorHandler.buildDepError "opaleye"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/opaleye-0.10.7.0.tar.gz";
      sha256 = "0ba1e1fc1e3cb54c9b1ca858b58b4debae4d1a7ec0f5cf30866e6b5acc0b3e3e";
    });
  }) // {
    package-description-override = "name:            opaleye\r\ncopyright:       Copyright (c) 2014-2018 Purely Agile Limited; 2019-2025 Tom Ellis\r\nversion:         0.10.7.0\r\nx-revision: 1\r\nsynopsis:        An SQL-generating DSL targeting PostgreSQL\r\ndescription:     An SQL-generating DSL targeting PostgreSQL.  Allows\r\n                 Postgres queries to be written within Haskell in a\r\n                 typesafe and composable fashion.\r\nhomepage:        https://github.com/tomjaguarpaw/haskell-opaleye\r\nbug-reports:     https://github.com/tomjaguarpaw/haskell-opaleye/issues\r\nlicense:         BSD3\r\nlicense-file:    LICENSE\r\nmaintainer:      Tom Ellis\r\ncategory:        Database\r\nbuild-type:      Simple\r\ncabal-version:   1.18\r\nextra-doc-files: README.md\r\n                 CHANGELOG.md\r\n                 *.md\r\ntested-with:     GHC==9.10, GHC==9.8, GHC==9.6, GHC==9.4, GHC==9.2, GHC==9.0, GHC==8.10, GHC==8.8\r\n\r\nsource-repository head\r\n  type:     git\r\n  location: https://github.com/tomjaguarpaw/haskell-opaleye.git\r\n\r\nlibrary\r\n  default-language: Haskell2010\r\n  default-extensions: MultiParamTypeClasses,\r\n                      FlexibleContexts,\r\n                      FlexibleInstances\r\n  hs-source-dirs: src\r\n  build-depends:\r\n      aeson               >= 0.6     && < 2.3\r\n    , base                >= 4.9     && < 4.22\r\n    , base16-bytestring   >= 0.1.1.6 && < 1.1\r\n    , case-insensitive    >= 1.2     && < 1.3\r\n    , bytestring          >= 0.10    && < 0.13\r\n    , contravariant       >= 1.2     && < 1.6\r\n    , postgresql-simple   >= 0.6     && < 0.8\r\n    , pretty              >= 1.1.1.0 && < 1.2\r\n    , product-profunctors >= 0.11.0.3 && < 0.12\r\n    , profunctors         >= 4.0     && < 5.7\r\n    , scientific          >= 0.3     && < 0.4\r\n    , semigroups          >= 0.13    && < 0.21\r\n    , text                >= 0.11    && < 2.2\r\n    , transformers        >= 0.3     && < 0.7\r\n    , time-compat         >= 1.9.5   && < 1.12\r\n    , time-locale-compat  >= 0.1     && < 0.2\r\n    , uuid-types          >= 1.0.5   && < 1.1\r\n    , void                >= 0.4     && < 0.8\r\n  exposed-modules: Opaleye,\r\n                   Opaleye.Adaptors,\r\n                   Opaleye.Aggregate,\r\n                   Opaleye.Binary,\r\n                   Opaleye.Column,\r\n                   Opaleye.Distinct,\r\n                   Opaleye.Experimental.Enum,\r\n                   Opaleye.Exists,\r\n                   Opaleye.Field,\r\n                   Opaleye.FunctionalJoin,\r\n                   Opaleye.Inferrable,\r\n                   Opaleye.Join,\r\n                   Opaleye.Label,\r\n                   Opaleye.Lateral,\r\n                   Opaleye.Manipulation,\r\n                   Opaleye.MaybeFields,\r\n                   Opaleye.Operators,\r\n                   Opaleye.Order,\r\n                   Opaleye.RunSelect,\r\n                   Opaleye.Select,\r\n                   Opaleye.Sql,\r\n                   Opaleye.SqlTypes,\r\n                   Opaleye.Table,\r\n                   Opaleye.ToFields,\r\n                   Opaleye.TypeFamilies,\r\n                   Opaleye.Values,\r\n                   Opaleye.With,\r\n                   Opaleye.Window,\r\n                   Opaleye.Internal.Aggregate,\r\n                   Opaleye.Internal.Binary,\r\n                   Opaleye.Internal.Constant,\r\n                   Opaleye.Internal.Column,\r\n                   Opaleye.Internal.Distinct,\r\n                   Opaleye.Internal.Locking,\r\n                   Opaleye.Internal.Helpers,\r\n                   Opaleye.Internal.Inferrable,\r\n                   Opaleye.Internal.Join,\r\n                   Opaleye.Internal.JSONBuildObjectFields,\r\n                   Opaleye.Internal.Lateral,\r\n                   Opaleye.Internal.Map,\r\n                   Opaleye.Internal.Manipulation,\r\n                   Opaleye.Internal.MaybeFields,\r\n                   Opaleye.Internal.Order,\r\n                   Opaleye.Internal.Operators,\r\n                   Opaleye.Internal.Optimize,\r\n                   Opaleye.Internal.PackMap,\r\n                   Opaleye.Internal.PGTypes,\r\n                   Opaleye.Internal.PGTypesExternal,\r\n                   Opaleye.Internal.PrimQuery,\r\n                   Opaleye.Internal.Print,\r\n                   Opaleye.Internal.QueryArr,\r\n                   Opaleye.Internal.Rebind,\r\n                   Opaleye.Internal.RunQuery,\r\n                   Opaleye.Internal.RunQueryExternal,\r\n                   Opaleye.Internal.Sql,\r\n                   Opaleye.Internal.Table,\r\n                   Opaleye.Internal.Tag,\r\n                   Opaleye.Internal.TypeFamilies,\r\n                   Opaleye.Internal.Unpackspec,\r\n                   Opaleye.Internal.Values,\r\n                   Opaleye.Internal.Window,\r\n                   Opaleye.Internal.HaskellDB.PrimQuery,\r\n                   Opaleye.Internal.HaskellDB.Sql,\r\n                   Opaleye.Internal.HaskellDB.Sql.Default,\r\n                   Opaleye.Internal.HaskellDB.Sql.Generate,\r\n                   Opaleye.Internal.HaskellDB.Sql.Print\r\n  ghc-options:     -Wall -Wcompat -Wno-unticked-promoted-constructors\r\n\r\ntest-suite test\r\n  default-language: Haskell2010\r\n  type: exitcode-stdio-1.0\r\n  main-is: Test.hs\r\n  other-modules: Connection,\r\n                 Opaleye.Test.Arbitrary,\r\n                 Opaleye.Test.Fields,\r\n                 Opaleye.Test.TraverseA,\r\n                 QuickCheck,\r\n                 TypeFamilies,\r\n                 Wrapped\r\n  hs-source-dirs: Test\r\n  build-depends:\r\n    aeson,\r\n    base >= 4 && < 5,\r\n    bytestring,\r\n    containers,\r\n    contravariant,\r\n    dotenv >= 0.3.1,\r\n    multiset,\r\n    postgresql-simple,\r\n    profunctors,\r\n    product-profunctors,\r\n    QuickCheck,\r\n    semigroups,\r\n    text >= 0.11 && < 2.2,\r\n    time-compat,\r\n    transformers,\r\n    hspec,\r\n    hspec-discover,\r\n    opaleye\r\n  ghc-options: -Wall\r\n\r\ntest-suite tutorial\r\n  default-language: Haskell2010\r\n  type: exitcode-stdio-1.0\r\n  main-is: Main.hs\r\n  other-modules: TutorialAdvanced,\r\n                 TutorialBasic,\r\n                 TutorialManipulation,\r\n                 TutorialBasicMonomorphic,\r\n                 DefaultExplanation\r\n  hs-source-dirs: Doc/Tutorial\r\n  build-depends:\r\n    base >= 4 && < 5,\r\n    postgresql-simple,\r\n    profunctors,\r\n    product-profunctors >= 0.6,\r\n    time,\r\n    opaleye\r\n  ghc-options: -Wall\r\n";
  }