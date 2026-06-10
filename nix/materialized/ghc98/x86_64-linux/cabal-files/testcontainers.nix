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
      identifier = { name = "testcontainers"; version = "0.5.2.0"; };
      license = "MIT";
      copyright = "2023 Alex Biehl";
      maintainer = "alex.biehl@gmail.com";
      author = "Alex Biehl";
      homepage = "";
      url = "";
      synopsis = "Docker containers for your integration tests.";
      description = "testcontainers is a Haskell library that provides a friendly API to\nrun Docker containers. It is designed to create a runtime environment\nto use during your integration tests";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."aeson" or (errorHandler.buildDepError "aeson"))
          (hsPkgs."aeson-optics" or (errorHandler.buildDepError "aeson-optics"))
          (hsPkgs."async" or (errorHandler.buildDepError "async"))
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          (hsPkgs."directory" or (errorHandler.buildDepError "directory"))
          (hsPkgs."exceptions" or (errorHandler.buildDepError "exceptions"))
          (hsPkgs."http-client" or (errorHandler.buildDepError "http-client"))
          (hsPkgs."http-types" or (errorHandler.buildDepError "http-types"))
          (hsPkgs."mtl" or (errorHandler.buildDepError "mtl"))
          (hsPkgs."network" or (errorHandler.buildDepError "network"))
          (hsPkgs."optics-core" or (errorHandler.buildDepError "optics-core"))
          (hsPkgs."process" or (errorHandler.buildDepError "process"))
          (hsPkgs."random" or (errorHandler.buildDepError "random"))
          (hsPkgs."resourcet" or (errorHandler.buildDepError "resourcet"))
          (hsPkgs."tasty" or (errorHandler.buildDepError "tasty"))
          (hsPkgs."text" or (errorHandler.buildDepError "text"))
          (hsPkgs."unliftio-core" or (errorHandler.buildDepError "unliftio-core"))
        ];
        buildable = true;
      };
      tests = {
        "tests" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."hspec" or (errorHandler.buildDepError "hspec"))
            (hsPkgs."tasty" or (errorHandler.buildDepError "tasty"))
            (hsPkgs."tasty-discover" or (errorHandler.buildDepError "tasty-discover"))
            (hsPkgs."tasty-hspec" or (errorHandler.buildDepError "tasty-hspec"))
            (hsPkgs."tasty-hunit" or (errorHandler.buildDepError "tasty-hunit"))
            (hsPkgs."testcontainers" or (errorHandler.buildDepError "testcontainers"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
          ];
          build-tools = [
            (hsPkgs.pkgsBuildBuild.hspec-discover.components.exes.hspec-discover or (pkgs.pkgsBuildBuild.hspec-discover or (errorHandler.buildToolDepError "hspec-discover:hspec-discover")))
            (hsPkgs.pkgsBuildBuild.tasty-discover.components.exes.tasty-discover or (pkgs.pkgsBuildBuild.tasty-discover or (errorHandler.buildToolDepError "tasty-discover:tasty-discover")))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/testcontainers-0.5.2.0.tar.gz";
      sha256 = "cdae02610e64efd7f13c048fb9efb09dac04fb5681eba96de33ad6fbceb97f37";
    });
  }) // {
    package-description-override = "cabal-version:      >=1.10\nname:               testcontainers\nversion:            0.5.2.0\nsynopsis:           Docker containers for your integration tests.\ndescription:\n  testcontainers is a Haskell library that provides a friendly API to\n  run Docker containers. It is designed to create a runtime environment\n  to use during your integration tests\n\n-- bug-reports:\nlicense:            MIT\nlicense-file:       LICENSE\nauthor:             Alex Biehl\nmaintainer:         alex.biehl@gmail.com\ncopyright:          2023 Alex Biehl\ncategory:           Development\nbuild-type:         Simple\nextra-source-files:\n  CHANGELOG.md\n  README.md\n  test/data/init-script.sql\n\ntested-with:\n  GHC ==8.8.4 || ==8.10.7 || ==9.0.2 || ==9.2.4 || ==9.4.2 || ==9.8.2\n\nsource-repository head\n  type:     git\n  location: https://github.com/testcontainers/testcontainers-hs\n\nlibrary\n  exposed-modules:\n    TestContainers\n    TestContainers.Config\n    TestContainers.Docker\n    TestContainers.Docker.Internal\n    TestContainers.Docker.Network\n    TestContainers.Docker.Reaper\n    TestContainers.Docker.State\n    TestContainers.Hspec\n    TestContainers.Image\n    TestContainers.Monad\n    TestContainers.Tasty\n    TestContainers.Trace\n\n  -- other-modules:\n  -- other-extensions:\n  build-depends:\n      aeson          >=1.4.6   && <3\n    , aeson-optics   >=1.1     && <2\n    , async\n    , base           >=4.12    && <5\n    , bytestring     >=0.10.8  && <0.13\n    , directory      >=1.3.6   && <2\n    , exceptions     >=0.10.4  && <0.11\n    , http-client    >=0.5.14  && <1\n    , http-types     >=0.12.3  && <1\n    , mtl            >=2.2.2   && <3\n    , network        >=2.8.0   && <3.3\n    , optics-core    >=0.1     && <0.5\n    , process        >=1.6.5   && <1.7\n    , random         >=1.2     && <2\n    , resourcet      >=1.2.4   && <1.4\n    , tasty          >=1.0     && <1.6\n    , text           >=1.2.3   && <3\n    , unliftio-core  >=0.1.0   && <0.3\n\n  hs-source-dirs:   src\n  default-language: Haskell2010\n  ghc-options:      -Wall\n\ntest-suite tests\n  hs-source-dirs:     test\n  default-language:   Haskell2010\n  ghc-options:        -Wall\n  type:               exitcode-stdio-1.0\n  main-is:            Driver.hs\n  other-modules:\n    TestContainers.HspecSpec\n    TestContainers.TastySpec\n\n  build-tool-depends:\n    hspec-discover:hspec-discover, tasty-discover:tasty-discover\n\n  build-depends:\n      base\n    , hspec           >=2.0   && <3.0\n    , tasty\n    , tasty-discover  >=4.2.1 && <6\n    , tasty-hspec\n    , tasty-hunit\n    , testcontainers\n    , text\n";
  }