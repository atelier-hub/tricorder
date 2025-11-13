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
    flags = { use-pkg-config = false; };
    package = {
      specVersion = "2.4";
      identifier = { name = "postgresql-libpq"; version = "0.11.0.0"; };
      license = "BSD-3-Clause";
      copyright = "(c) 2010 Grant Monroe\n(c) 2011 Leon P Smith";
      maintainer = "Oleg Grenrus <oleg.grenrus@iki.fi>";
      author = "Grant Monroe, Leon P Smith, Joey Adams";
      homepage = "https://github.com/haskellari/postgresql-libpq";
      url = "";
      synopsis = "low-level binding to libpq";
      description = "This is a binding to libpq: the C application\nprogrammer's interface to PostgreSQL. libpq is a\nset of library functions that allow client\nprograms to pass queries to the PostgreSQL\nbackend server and to receive the results of\nthese queries.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = (([
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
        ] ++ pkgs.lib.optional (!system.isWindows) (hsPkgs."unix" or (errorHandler.buildDepError "unix"))) ++ pkgs.lib.optional (system.isWindows) (hsPkgs."Win32" or (errorHandler.buildDepError "Win32"))) ++ (if flags.use-pkg-config
          then [
            (hsPkgs."postgresql-libpq-pkgconfig" or (errorHandler.buildDepError "postgresql-libpq-pkgconfig"))
          ]
          else [
            (hsPkgs."postgresql-libpq-configure" or (errorHandler.buildDepError "postgresql-libpq-configure"))
          ]);
        build-tools = [
          (hsPkgs.pkgsBuildBuild.hsc2hs.components.exes.hsc2hs or (pkgs.pkgsBuildBuild.hsc2hs or (errorHandler.buildToolDepError "hsc2hs:hsc2hs")))
        ];
        buildable = true;
      };
      tests = {
        "smoke" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."postgresql-libpq" or (errorHandler.buildDepError "postgresql-libpq"))
            (hsPkgs."tasty" or (errorHandler.buildDepError "tasty"))
            (hsPkgs."tasty-hunit" or (errorHandler.buildDepError "tasty-hunit"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/postgresql-libpq-0.11.0.0.tar.gz";
      sha256 = "034ab1208fe6bb33009b3c7c75a06dfea5b306e289a013fff2e2e450d63ed2a3";
    });
  }) // {
    package-description-override = "cabal-version:      2.4\nname:               postgresql-libpq\nversion:            0.11.0.0\nx-revision:         1\nsynopsis:           low-level binding to libpq\ndescription:\n  This is a binding to libpq: the C application\n  programmer's interface to PostgreSQL. libpq is a\n  set of library functions that allow client\n  programs to pass queries to the PostgreSQL\n  backend server and to receive the results of\n  these queries.\n\nhomepage:           https://github.com/haskellari/postgresql-libpq\nbug-reports:        https://github.com/haskellari/postgresql-libpq/issues\nlicense:            BSD-3-Clause\nlicense-file:       LICENSE\nauthor:             Grant Monroe, Leon P Smith, Joey Adams\nmaintainer:         Oleg Grenrus <oleg.grenrus@iki.fi>\ncopyright:\n  (c) 2010 Grant Monroe\n  (c) 2011 Leon P Smith\n\ncategory:           Database\nbuild-type:         Simple\nextra-source-files: cbits/hs-libpq.h\ntested-with:\n  GHC ==8.6.5\n   || ==8.8.4\n   || ==8.10.7\n   || ==9.0.2\n   || ==9.2.8\n   || ==9.4.8\n   || ==9.6.6\n   || ==9.8.4\n   || ==9.10.1\n   || ==9.12.1\n\nextra-source-files: CHANGELOG.md\n\n-- If true,  use pkg-config,  otherwise use the pg_config based build\n-- configuration\nflag use-pkg-config\n  default: False\n  manual:  True\n\nlibrary\n  default-language:   Haskell2010\n  hs-source-dirs:     src\n  c-sources:          cbits/noticehandlers.c\n  include-dirs:       cbits\n  ghc-options:        -Wall\n  other-extensions:\n    BangPatterns\n    CApiFFI\n    DerivingStrategies\n    EmptyDataDecls\n    GeneralizedNewtypeDeriving\n    OverloadedStrings\n    ScopedTypeVariables\n\n  exposed-modules:\n    Database.PostgreSQL.LibPQ\n    Database.PostgreSQL.LibPQ.Internal\n\n  other-modules:\n    Database.PostgreSQL.LibPQ.Compat\n    Database.PostgreSQL.LibPQ.Enums\n    Database.PostgreSQL.LibPQ.FFI\n    Database.PostgreSQL.LibPQ.Marshal\n    Database.PostgreSQL.LibPQ.Notify\n    Database.PostgreSQL.LibPQ.Oid\n    Database.PostgreSQL.LibPQ.Ptr\n\n  build-depends:\n    , base        >=4.12.0.0 && <4.22\n    , bytestring  >=0.10.8.2 && <0.13\n\n  if !os(windows)\n    build-depends: unix >=2.7.2.2 && <2.9\n\n  if os(windows)\n    build-depends: Win32 >=2.2.0.2 && <2.15\n\n  if flag(use-pkg-config)\n    build-depends: postgresql-libpq-pkgconfig ^>=0.11\n\n  else\n    build-depends: postgresql-libpq-configure ^>=0.11\n\n  build-tool-depends: hsc2hs:hsc2hs >=0.68.5\n\ntest-suite smoke\n  default-language: Haskell2010\n  type:             exitcode-stdio-1.0\n  main-is:          Smoke.hs\n  hs-source-dirs:   test\n  build-depends:\n    , base\n    , bytestring\n    , postgresql-libpq\n    , tasty             ^>=1.5\n    , tasty-hunit       ^>=0.10.1\n\nsource-repository head\n  type:     git\n  location: https://github.com/haskellari/postgresql-libpq\n";
  }