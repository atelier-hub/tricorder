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
      identifier = { name = "postgresql-simple"; version = "0.7.0.1"; };
      license = "BSD-3-Clause";
      copyright = "(c) 2011 MailRank, Inc.\n(c) 2011-2018 Leon P Smith\n(c) 2018-2020 Oleg Grenrus";
      maintainer = "Oleg Grenrus <oleg.grenrus@iki.fi>";
      author = "Bryan O'Sullivan, Leon P Smith";
      homepage = "";
      url = "";
      synopsis = "Mid-Level PostgreSQL client library";
      description = "Mid-Level PostgreSQL client library, forked from mysql-simple.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
          (hsPkgs."template-haskell" or (errorHandler.buildDepError "template-haskell"))
          (hsPkgs."text" or (errorHandler.buildDepError "text"))
          (hsPkgs."time-compat" or (errorHandler.buildDepError "time-compat"))
          (hsPkgs."transformers" or (errorHandler.buildDepError "transformers"))
          (hsPkgs."aeson" or (errorHandler.buildDepError "aeson"))
          (hsPkgs."attoparsec" or (errorHandler.buildDepError "attoparsec"))
          (hsPkgs."case-insensitive" or (errorHandler.buildDepError "case-insensitive"))
          (hsPkgs."hashable" or (errorHandler.buildDepError "hashable"))
          (hsPkgs."Only" or (errorHandler.buildDepError "Only"))
          (hsPkgs."postgresql-libpq" or (errorHandler.buildDepError "postgresql-libpq"))
          (hsPkgs."scientific" or (errorHandler.buildDepError "scientific"))
          (hsPkgs."uuid-types" or (errorHandler.buildDepError "uuid-types"))
          (hsPkgs."vector" or (errorHandler.buildDepError "vector"))
        ];
        buildable = true;
      };
      tests = {
        "inspection" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."inspection-testing" or (errorHandler.buildDepError "inspection-testing"))
            (hsPkgs."postgresql-libpq" or (errorHandler.buildDepError "postgresql-libpq"))
            (hsPkgs."postgresql-simple" or (errorHandler.buildDepError "postgresql-simple"))
            (hsPkgs."tasty" or (errorHandler.buildDepError "tasty"))
            (hsPkgs."tasty-hunit" or (errorHandler.buildDepError "tasty-hunit"))
          ];
          buildable = true;
        };
        "test" = {
          depends = [
            (hsPkgs."aeson" or (errorHandler.buildDepError "aeson"))
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."base16-bytestring" or (errorHandler.buildDepError "base16-bytestring"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."case-insensitive" or (errorHandler.buildDepError "case-insensitive"))
            (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
            (hsPkgs."cryptohash-md5" or (errorHandler.buildDepError "cryptohash-md5"))
            (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
            (hsPkgs."postgresql-simple" or (errorHandler.buildDepError "postgresql-simple"))
            (hsPkgs."tasty" or (errorHandler.buildDepError "tasty"))
            (hsPkgs."tasty-golden" or (errorHandler.buildDepError "tasty-golden"))
            (hsPkgs."tasty-hunit" or (errorHandler.buildDepError "tasty-hunit"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
            (hsPkgs."time-compat" or (errorHandler.buildDepError "time-compat"))
            (hsPkgs."vector" or (errorHandler.buildDepError "vector"))
          ];
          buildable = true;
        };
      };
      benchmarks = {
        "select" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."postgresql-simple" or (errorHandler.buildDepError "postgresql-simple"))
            (hsPkgs."vector" or (errorHandler.buildDepError "vector"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/postgresql-simple-0.7.0.1.tar.gz";
      sha256 = "597cf320650318d6033ee538b19eb28e43f02b88590baae7272bc21275f3ab99";
    });
  }) // {
    package-description-override = "cabal-version:      1.12\nname:               postgresql-simple\nversion:            0.7.0.1\nsynopsis:           Mid-Level PostgreSQL client library\ndescription:\n  Mid-Level PostgreSQL client library, forked from mysql-simple.\n\nlicense:            BSD3\nlicense-file:       LICENSE\nauthor:             Bryan O'Sullivan, Leon P Smith\nmaintainer:         Oleg Grenrus <oleg.grenrus@iki.fi>\ncopyright:\n  (c) 2011 MailRank, Inc.\n  (c) 2011-2018 Leon P Smith\n  (c) 2018-2020 Oleg Grenrus\n\ncategory:           Database\nbuild-type:         Simple\nextra-source-files:\n  CHANGES.md\n  CONTRIBUTORS\n  test/results/malformed-input.expected\n  test/results/unique-constraint-violation.expected\n\ntested-with:\n  GHC ==8.6.5\n   || ==8.8.4\n   || ==8.10.7\n   || ==9.0.2\n   || ==9.2.8\n   || ==9.4.8\n   || ==9.6.7\n   || ==9.8.4\n   || ==9.10.2\n   || ==9.12.2\n\nlibrary\n  default-language:   Haskell2010\n  hs-source-dirs:     src\n  exposed-modules:\n    Database.PostgreSQL.Simple\n    Database.PostgreSQL.Simple.Arrays\n    Database.PostgreSQL.Simple.Copy\n    Database.PostgreSQL.Simple.Cursor\n    Database.PostgreSQL.Simple.Errors\n    Database.PostgreSQL.Simple.FromField\n    Database.PostgreSQL.Simple.FromRow\n    Database.PostgreSQL.Simple.HStore\n    Database.PostgreSQL.Simple.HStore.Internal\n    Database.PostgreSQL.Simple.Internal\n    Database.PostgreSQL.Simple.LargeObjects\n    Database.PostgreSQL.Simple.Newtypes\n    Database.PostgreSQL.Simple.Notification\n    Database.PostgreSQL.Simple.Ok\n    Database.PostgreSQL.Simple.Range\n    Database.PostgreSQL.Simple.SqlQQ\n    Database.PostgreSQL.Simple.Time\n    Database.PostgreSQL.Simple.Time.Internal\n    Database.PostgreSQL.Simple.ToField\n    Database.PostgreSQL.Simple.ToRow\n    Database.PostgreSQL.Simple.Transaction\n    Database.PostgreSQL.Simple.TypeInfo\n    Database.PostgreSQL.Simple.TypeInfo.Macro\n    Database.PostgreSQL.Simple.TypeInfo.Static\n    Database.PostgreSQL.Simple.Types\n    Database.PostgreSQL.Simple.Vector\n    Database.PostgreSQL.Simple.Vector.Unboxed\n\n  -- Other-modules:\n  other-modules:\n    Database.PostgreSQL.Simple.Compat\n    Database.PostgreSQL.Simple.HStore.Implementation\n    Database.PostgreSQL.Simple.Internal.PQResultUtils\n    Database.PostgreSQL.Simple.Time.Implementation\n    Database.PostgreSQL.Simple.Time.Internal.Parser\n    Database.PostgreSQL.Simple.Time.Internal.Printer\n    Database.PostgreSQL.Simple.TypeInfo.Types\n\n  -- GHC bundled libs\n  build-depends:\n      base              >=4.12.0.0 && <4.22\n    , bytestring        >=0.10.8.2 && <0.13\n    , containers        >=0.6.0.1  && <0.8\n    , template-haskell  >=2.14.0.0 && <2.24\n    , text              >=1.2.3.0  && <1.3  || >=2.0 && <2.2\n    , time-compat       >=1.9.5    && <1.12\n    , transformers      >=0.5.6.2  && <0.7\n\n  -- Other dependencies\n  build-depends:\n      aeson             >=2.1.2.1  && <2.3\n    , attoparsec        >=0.14.4   && <0.15\n    , case-insensitive  >=1.2.1.0  && <1.3\n    , hashable          >=1.4.3.0  && <1.6\n    , Only              >=0.1      && <0.1.1\n    , postgresql-libpq  >=0.10.0.0 && <0.12\n    , scientific        >=0.3.7.0  && <0.4\n    , uuid-types        >=1.0.5    && <1.1\n    , vector            >=0.13.0.0 && <0.14\n\n  default-extensions:\n    BangPatterns\n    DoAndIfThenElse\n    OverloadedStrings\n    TypeOperators\n    ViewPatterns\n\n  ghc-options:        -Wall -fno-warn-name-shadowing\n\nsource-repository head\n  type:     git\n  location: http://github.com/haskellari/postgresql-simple\n\ntest-suite inspection\n  default-language: Haskell2010\n  type:             exitcode-stdio-1.0\n  hs-source-dirs:   test\n  main-is:          Inspection.hs\n  build-depends:\n      base\n    , inspection-testing  >=0.4.1.1 && <0.7\n    , postgresql-libpq\n    , postgresql-simple\n    , tasty\n    , tasty-hunit\n\ntest-suite test\n  default-language:   Haskell2010\n  type:               exitcode-stdio-1.0\n  hs-source-dirs:     test\n  main-is:            Main.hs\n  other-modules:\n    Common\n    Exception\n    Interval\n    Notify\n    Serializable\n    Time\n\n  ghc-options:        -threaded\n  ghc-options:        -Wall -fno-warn-name-shadowing -fno-warn-unused-do-bind\n  default-extensions:\n    NamedFieldPuns\n    OverloadedStrings\n    PatternGuards\n    Rank2Types\n    RecordWildCards\n    ScopedTypeVariables\n\n  build-depends:\n      aeson\n    , base\n    , base16-bytestring\n    , bytestring\n    , case-insensitive\n    , containers\n    , cryptohash-md5     >=0.11.100.1 && <0.12\n    , filepath\n    , postgresql-simple\n    , tasty\n    , tasty-golden\n    , tasty-hunit\n    , text\n    , time-compat\n    , vector\n\nbenchmark select\n  default-language: Haskell2010\n  type:             exitcode-stdio-1.0\n  hs-source-dirs:   bench\n  main-is:          Select.hs\n  build-depends:\n      base\n    , postgresql-simple\n    , vector\n";
  }