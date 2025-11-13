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
      specVersion = "2.4";
      identifier = { name = "postgresql-libpq-configure"; version = "0.11"; };
      license = "BSD-3-Clause";
      copyright = "(c) 2024 Oleg Grenrus";
      maintainer = "Oleg Grenrus <oleg.grenrus@iki.fi>";
      author = "Grant Monroe, Leon P Smith, Joey Adams";
      homepage = "https://github.com/haskellari/postgresql-libpq";
      url = "";
      synopsis = "low-level binding to libpq: configure based provider";
      description = "This is a binding to libpq: the C application\nprogrammer's interface to PostgreSQL. libpq is a\nset of library functions that allow client\nprograms to pass queries to the PostgreSQL\nbackend server and to receive the results of\nthese queries.";
      buildType = "Configure";
    };
    components = {
      "library" = {
        depends = [ (hsPkgs."base" or (errorHandler.buildDepError "base")) ];
        buildable = true;
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/postgresql-libpq-configure-0.11.tar.gz";
      sha256 = "8d4fe34b5475dd0c8339b5c05506111a10214ea18a10cd366e5440eaac95b2d8";
    });
  }) // {
    package-description-override = "cabal-version:      2.4\nname:               postgresql-libpq-configure\nversion:            0.11\nsynopsis:           low-level binding to libpq: configure based provider\ndescription:\n  This is a binding to libpq: the C application\n  programmer's interface to PostgreSQL. libpq is a\n  set of library functions that allow client\n  programs to pass queries to the PostgreSQL\n  backend server and to receive the results of\n  these queries.\n\nhomepage:           https://github.com/haskellari/postgresql-libpq\nbug-reports:        https://github.com/haskellari/postgresql-libpq/issues\nlicense:            BSD-3-Clause\nlicense-file:       LICENSE\nauthor:             Grant Monroe, Leon P Smith, Joey Adams\nmaintainer:         Oleg Grenrus <oleg.grenrus@iki.fi>\ncopyright:          (c) 2024 Oleg Grenrus\ncategory:           Database\nextra-doc-files:    CHANGELOG.md\ntested-with:\n  GHC ==8.6.5\n   || ==8.8.4\n   || ==8.10.7\n   || ==9.0.2\n   || ==9.2.8\n   || ==9.4.8\n   || ==9.6.5\n   || ==9.8.2\n   || ==9.10.1\n\nbuild-type:         Configure\nextra-source-files:\n  configure\n  postgresql-libpq-configure.buildinfo.in\n\nlibrary\n  default-language: Haskell2010\n  build-depends:    base <5\n\nsource-repository head\n  type:     git\n  location: https://github.com/haskellari/postgresql-libpq\n  subdir:   postgresql-libpq-configure\n";
  }