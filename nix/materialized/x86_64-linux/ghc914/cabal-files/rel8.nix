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
      identifier = { name = "rel8"; version = "1.7.0.0"; };
      license = "BSD-3-Clause";
      copyright = "";
      maintainer = "ollie@ocharles.org.uk";
      author = "Oliver Charles";
      homepage = "https://github.com/circuithub/rel8";
      url = "";
      synopsis = "Hey! Hey! Can u rel8?";
      description = "";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."aeson" or (errorHandler.buildDepError "aeson"))
          (hsPkgs."attoparsec" or (errorHandler.buildDepError "attoparsec"))
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."base16" or (errorHandler.buildDepError "base16"))
          (hsPkgs."base-compat" or (errorHandler.buildDepError "base-compat"))
          (hsPkgs."bifunctors" or (errorHandler.buildDepError "bifunctors"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          (hsPkgs."case-insensitive" or (errorHandler.buildDepError "case-insensitive"))
          (hsPkgs."comonad" or (errorHandler.buildDepError "comonad"))
          (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
          (hsPkgs."contravariant" or (errorHandler.buildDepError "contravariant"))
          (hsPkgs."hasql" or (errorHandler.buildDepError "hasql"))
          (hsPkgs."iproute" or (errorHandler.buildDepError "iproute"))
          (hsPkgs."opaleye" or (errorHandler.buildDepError "opaleye"))
          (hsPkgs."pretty" or (errorHandler.buildDepError "pretty"))
          (hsPkgs."profunctors" or (errorHandler.buildDepError "profunctors"))
          (hsPkgs."product-profunctors" or (errorHandler.buildDepError "product-profunctors"))
          (hsPkgs."scientific" or (errorHandler.buildDepError "scientific"))
          (hsPkgs."semialign" or (errorHandler.buildDepError "semialign"))
          (hsPkgs."semigroupoids" or (errorHandler.buildDepError "semigroupoids"))
          (hsPkgs."text" or (errorHandler.buildDepError "text"))
          (hsPkgs."these" or (errorHandler.buildDepError "these"))
          (hsPkgs."time" or (errorHandler.buildDepError "time"))
          (hsPkgs."transformers" or (errorHandler.buildDepError "transformers"))
          (hsPkgs."utf8-string" or (errorHandler.buildDepError "utf8-string"))
          (hsPkgs."uuid" or (errorHandler.buildDepError "uuid"))
          (hsPkgs."vector" or (errorHandler.buildDepError "vector"))
        ];
        buildable = true;
      };
      tests = {
        "tests" = {
          depends = [
            (hsPkgs."aeson" or (errorHandler.buildDepError "aeson"))
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."case-insensitive" or (errorHandler.buildDepError "case-insensitive"))
            (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
            (hsPkgs."hasql" or (errorHandler.buildDepError "hasql"))
            (hsPkgs."hasql-transaction" or (errorHandler.buildDepError "hasql-transaction"))
            (hsPkgs."hedgehog" or (errorHandler.buildDepError "hedgehog"))
            (hsPkgs."mmorph" or (errorHandler.buildDepError "mmorph"))
            (hsPkgs."iproute" or (errorHandler.buildDepError "iproute"))
            (hsPkgs."rel8" or (errorHandler.buildDepError "rel8"))
            (hsPkgs."scientific" or (errorHandler.buildDepError "scientific"))
            (hsPkgs."tasty" or (errorHandler.buildDepError "tasty"))
            (hsPkgs."tasty-hedgehog" or (errorHandler.buildDepError "tasty-hedgehog"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
            (hsPkgs."these" or (errorHandler.buildDepError "these"))
            (hsPkgs."time" or (errorHandler.buildDepError "time"))
            (hsPkgs."tmp-postgres" or (errorHandler.buildDepError "tmp-postgres"))
            (hsPkgs."transformers" or (errorHandler.buildDepError "transformers"))
            (hsPkgs."uuid" or (errorHandler.buildDepError "uuid"))
            (hsPkgs."vector" or (errorHandler.buildDepError "vector"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/rel8-1.7.0.0.tar.gz";
      sha256 = "2990bf8e9848eace4d96b306fb6c9241185f7a6be4680f316438d1bd7ae5b9f1";
    });
  }) // {
    package-description-override = "cabal-version:       2.0\nname:                rel8\nversion:             1.7.0.0\nsynopsis:            Hey! Hey! Can u rel8?\nlicense:             BSD3\nlicense-file:        LICENSE\nauthor:              Oliver Charles\nmaintainer:          ollie@ocharles.org.uk\nhomepage:            https://github.com/circuithub/rel8\nbug-reports:         https://github.com/circuithub/rel8/issues\nbuild-type:          Simple\nextra-doc-files:\n    README.md\n    Changelog.md\n\nsource-repository head\n    type: git\n    location: https://github.com/circuithub/rel8\n\nlibrary\n  build-depends:\n      aeson\n    , attoparsec\n    , base >= 4.16 && < 4.22\n    , base16 >= 1.0\n    , base-compat >= 0.11 && < 0.15\n    , bifunctors\n    , bytestring\n    , case-insensitive\n    , comonad\n    , containers\n    , contravariant\n    , hasql >= 1.8 && < 1.10\n    , iproute ^>= 1.7\n    , opaleye ^>= 0.10.2.1\n    , pretty\n    , profunctors\n    , product-profunctors\n    , scientific\n    , semialign\n    , semigroupoids\n    , text\n    , these\n    , time\n    , transformers\n    , utf8-string\n    , uuid\n    , vector\n\n  default-language:\n    Haskell2010\n  ghc-options:\n    -Werror=missing-methods -Werror=incomplete-patterns -Werror=missing-fields\n    -Weverything -Wno-unsafe -Wno-safe -Wno-missing-safe-haskell-mode\n    -Wno-missing-import-lists -Wno-prepositive-qualified-module\n    -Wno-monomorphism-restriction\n    -Wno-missing-local-signatures\n    -Wno-missing-kind-signatures\n    -Wno-missing-role-annotations\n    -Wno-missing-deriving-strategies\n    -Wno-term-variable-capture\n\n  hs-source-dirs:\n    src\n  exposed-modules:\n    Rel8\n    Rel8.Array\n    Rel8.Decoder\n    Rel8.Encoder\n    Rel8.Expr.Num\n    Rel8.Expr.Text\n    Rel8.Expr.Time\n    Rel8.Table.Verify\n    Rel8.Tabulate\n\n  other-modules:\n    Rel8.Aggregate\n    Rel8.Aggregate.Fold\n    Rel8.Aggregate.Function\n\n    Rel8.Column\n    Rel8.Column.ADT\n    Rel8.Column.Either\n    Rel8.Column.Lift\n    Rel8.Column.List\n    Rel8.Column.Maybe\n    Rel8.Column.NonEmpty\n    Rel8.Column.Null\n    Rel8.Column.These\n\n    Rel8.Expr\n    Rel8.Expr.Aggregate\n    Rel8.Expr.Array\n    Rel8.Expr.Bool\n    Rel8.Expr.Default\n    Rel8.Expr.Eq\n    Rel8.Expr.Function\n    Rel8.Expr.List\n    Rel8.Expr.NonEmpty\n    Rel8.Expr.Null\n    Rel8.Expr.Opaleye\n    Rel8.Expr.Ord\n    Rel8.Expr.Order\n    Rel8.Expr.Read\n    Rel8.Expr.Sequence\n    Rel8.Expr.Serialize\n    Rel8.Expr.Show\n    Rel8.Expr.Subscript\n    Rel8.Expr.Window\n\n    Rel8.FCF\n\n    Rel8.Kind.Algebra\n    Rel8.Kind.Context\n\n    Rel8.Generic.Construction\n    Rel8.Generic.Construction.ADT\n    Rel8.Generic.Construction.Record\n    Rel8.Generic.Map\n    Rel8.Generic.Record\n    Rel8.Generic.Rel8able\n    Rel8.Generic.Table\n    Rel8.Generic.Table.ADT\n    Rel8.Generic.Table.Record\n\n    Rel8.Order\n\n    Rel8.Query\n    Rel8.Query.Aggregate\n    Rel8.Query.Distinct\n    Rel8.Query.Each\n    Rel8.Query.Either\n    Rel8.Query.Evaluate\n    Rel8.Query.Exists\n    Rel8.Query.Filter\n    Rel8.Query.Function\n    Rel8.Query.Indexed\n    Rel8.Query.Limit\n    Rel8.Query.List\n    Rel8.Query.Loop\n    Rel8.Query.Materialize\n    Rel8.Query.Maybe\n    Rel8.Query.Null\n    Rel8.Query.Opaleye\n    Rel8.Query.Order\n    Rel8.Query.Rebind\n    Rel8.Query.Set\n    Rel8.Query.SQL\n    Rel8.Query.These\n    Rel8.Query.Values\n    Rel8.Query.Window\n\n    Rel8.Schema.Context.Nullify\n    Rel8.Schema.Dict\n    Rel8.Schema.Escape\n    Rel8.Schema.Field\n    Rel8.Schema.HTable\n    Rel8.Schema.HTable.Either\n    Rel8.Schema.HTable.Identity\n    Rel8.Schema.HTable.Label\n    Rel8.Schema.HTable.List\n    Rel8.Schema.HTable.MapTable\n    Rel8.Schema.HTable.Maybe\n    Rel8.Schema.HTable.NonEmpty\n    Rel8.Schema.HTable.Nullify\n    Rel8.Schema.HTable.Product\n    Rel8.Schema.HTable.These\n    Rel8.Schema.HTable.Vectorize\n    Rel8.Schema.Kind\n    Rel8.Schema.Name\n    Rel8.Schema.Null\n    Rel8.Schema.QualifiedName\n    Rel8.Schema.Result\n    Rel8.Schema.Spec\n    Rel8.Schema.Table\n\n    Rel8.Statement\n    Rel8.Statement.Delete\n    Rel8.Statement.Insert\n    Rel8.Statement.OnConflict\n    Rel8.Statement.Prepared\n    Rel8.Statement.Returning\n    Rel8.Statement.Rows\n    Rel8.Statement.Run\n    Rel8.Statement.Select\n    Rel8.Statement.Set\n    Rel8.Statement.SQL\n    Rel8.Statement.Update\n    Rel8.Statement.Using\n    Rel8.Statement.View\n    Rel8.Statement.Where\n\n    Rel8.Table\n    Rel8.Table.ADT\n    Rel8.Table.Aggregate\n    Rel8.Table.Aggregate.Maybe\n    Rel8.Table.Alternative\n    Rel8.Table.Bool\n    Rel8.Table.Cols\n    Rel8.Table.Either\n    Rel8.Table.Eq\n    Rel8.Table.HKD\n    Rel8.Table.List\n    Rel8.Table.Maybe\n    Rel8.Table.Name\n    Rel8.Table.NonEmpty\n    Rel8.Table.Null\n    Rel8.Table.Nullify\n    Rel8.Table.Opaleye\n    Rel8.Table.Ord\n    Rel8.Table.Order\n    Rel8.Table.Projection\n    Rel8.Table.Rel8able\n    Rel8.Table.Serialize\n    Rel8.Table.These\n    Rel8.Table.Transpose\n    Rel8.Table.Undefined\n    Rel8.Table.Window\n\n    Rel8.Type\n    Rel8.Type.Array\n    Rel8.Type.Builder.ByteString\n    Rel8.Type.Builder.Fold\n    Rel8.Type.Builder.Time\n    Rel8.Type.Composite\n    Rel8.Type.Decimal\n    Rel8.Type.Decoder\n    Rel8.Type.Eq\n    Rel8.Type.Encoder\n    Rel8.Type.Enum\n    Rel8.Type.Information\n    Rel8.Type.JSONEncoded\n    Rel8.Type.JSONBEncoded\n    Rel8.Type.Monoid\n    Rel8.Type.Name\n    Rel8.Type.Nullable\n    Rel8.Type.Num\n    Rel8.Type.Ord\n    Rel8.Type.Parser\n    Rel8.Type.Parser.ByteString\n    Rel8.Type.Parser.Time\n    Rel8.Type.ReadShow\n    Rel8.Type.Semigroup\n    Rel8.Type.String\n    Rel8.Type.Sum\n    Rel8.Type.Tag\n\n    Rel8.Window\n\n\ntest-suite tests\n  type:             exitcode-stdio-1.0\n  build-depends:\n      aeson\n    , base\n    , bytestring\n    , case-insensitive\n    , containers\n    , hasql\n    , hasql-transaction\n    , hedgehog          >= 1.0 && < 1.6\n    , mmorph\n    , iproute\n    , rel8\n    , scientific\n    , tasty\n    , tasty-hedgehog\n    , text\n    , these\n    , time\n    , tmp-postgres >=1.34 && <1.36\n    , transformers\n    , uuid\n    , vector\n\n  other-modules:\n    Rel8.Generic.Rel8able.Test\n\n  main-is:          Main.hs\n  hs-source-dirs:   tests\n  default-language: Haskell2010\n  ghc-options:\n    -Weverything -Wno-unsafe -Wno-safe -Wno-missing-safe-haskell-mode\n    -Wno-missing-import-lists -Wno-prepositive-qualified-module\n    -Wno-deprecations -Wno-monomorphism-restriction\n    -Wno-missing-local-signatures -Wno-implicit-prelude\n    -Wno-missing-kind-signatures\n    -Wno-missing-role-annotations\n";
  }