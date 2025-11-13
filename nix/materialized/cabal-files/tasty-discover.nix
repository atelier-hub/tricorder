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
      specVersion = "3.0";
      identifier = { name = "tasty-discover"; version = "5.1.0"; };
      license = "MIT";
      copyright = "2016 Luke Murphy\n2020-2025 John Ky";
      maintainer = "John Ky <newhoggy@gmail.com>";
      author = "Luke Murphy";
      homepage = "https://github.com/haskell-works/tasty-discover";
      url = "";
      synopsis = "Test discovery for the tasty framework.";
      description = "Automatic test discovery and runner for the tasty framework.\n\nPrefix your test case names and tasty-discover will discover, collect and run them.\n\nAll popular test libraries are covered. Configure once and then just write your tests.\nAvoid forgetting to add test modules to your Cabal/Hpack files.\n\nTasty ingredients are included along with various configuration options for different\nuse cases.\n\nPlease see the `README.md` below for how to get started.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
          (hsPkgs."directory" or (errorHandler.buildDepError "directory"))
          (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
          (hsPkgs."Glob" or (errorHandler.buildDepError "Glob"))
          (hsPkgs."tasty" or (errorHandler.buildDepError "tasty"))
        ];
        buildable = true;
      };
      exes = {
        "tasty-discover" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
            (hsPkgs."tasty-discover" or (errorHandler.buildDepError "tasty-discover"))
          ];
          buildable = true;
        };
      };
      tests = {
        "tasty-discover-test" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."ansi-terminal" or (errorHandler.buildDepError "ansi-terminal"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
            (hsPkgs."directory" or (errorHandler.buildDepError "directory"))
            (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
            (hsPkgs."hedgehog" or (errorHandler.buildDepError "hedgehog"))
            (hsPkgs."hspec" or (errorHandler.buildDepError "hspec"))
            (hsPkgs."hspec-core" or (errorHandler.buildDepError "hspec-core"))
            (hsPkgs."process" or (errorHandler.buildDepError "process"))
            (hsPkgs."tasty" or (errorHandler.buildDepError "tasty"))
            (hsPkgs."tasty-expected-failure" or (errorHandler.buildDepError "tasty-expected-failure"))
            (hsPkgs."tasty-golden" or (errorHandler.buildDepError "tasty-golden"))
            (hsPkgs."tasty-hedgehog" or (errorHandler.buildDepError "tasty-hedgehog"))
            (hsPkgs."tasty-hspec" or (errorHandler.buildDepError "tasty-hspec"))
            (hsPkgs."tasty-hunit" or (errorHandler.buildDepError "tasty-hunit"))
            (hsPkgs."tasty-quickcheck" or (errorHandler.buildDepError "tasty-quickcheck"))
            (hsPkgs."tasty-smallcheck" or (errorHandler.buildDepError "tasty-smallcheck"))
            (hsPkgs."temporary" or (errorHandler.buildDepError "temporary"))
            (hsPkgs."tasty-discover" or (errorHandler.buildDepError "tasty-discover"))
          ];
          build-tools = [
            (hsPkgs.pkgsBuildBuild.tasty-discover.components.exes.tasty-discover or (pkgs.pkgsBuildBuild.tasty-discover or (errorHandler.buildToolDepError "tasty-discover:tasty-discover")))
          ];
          buildable = true;
        };
        "no-main-test" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."tasty" or (errorHandler.buildDepError "tasty"))
            (hsPkgs."tasty-hunit" or (errorHandler.buildDepError "tasty-hunit"))
            (hsPkgs."tasty-quickcheck" or (errorHandler.buildDepError "tasty-quickcheck"))
            (hsPkgs."tasty-discover" or (errorHandler.buildDepError "tasty-discover"))
          ];
          build-tools = [
            (hsPkgs.pkgsBuildBuild.tasty-discover.components.exes.tasty-discover or (pkgs.pkgsBuildBuild.tasty-discover or (errorHandler.buildToolDepError "tasty-discover:tasty-discover")))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/tasty-discover-5.1.0.tar.gz";
      sha256 = "2ee6ab127e0457be1ead3fde35267d7af141199e960d03f2deb8c56128f1d778";
    });
  }) // {
    package-description-override = "cabal-version: 3.0\r\n\r\nname:                   tasty-discover\r\nversion:                5.1.0\r\nx-revision: 1\r\nsynopsis:               Test discovery for the tasty framework.\r\ndescription:            Automatic test discovery and runner for the tasty framework.\r\n                      \r\n                        Prefix your test case names and tasty-discover will discover, collect and run them.\r\n                      \r\n                        All popular test libraries are covered. Configure once and then just write your tests.\r\n                        Avoid forgetting to add test modules to your Cabal/Hpack files.\r\n                      \r\n                        Tasty ingredients are included along with various configuration options for different\r\n                        use cases.\r\n                      \r\n                        Please see the `README.md` below for how to get started.\r\ncategory:               Testing\r\nstability:              Experimental\r\nhomepage:               https://github.com/haskell-works/tasty-discover\r\nbug-reports:            https://github.com/haskell-works/tasty-discover/issues\r\nauthor:                 Luke Murphy\r\nmaintainer:             John Ky <newhoggy@gmail.com>\r\ncopyright:              2016 Luke Murphy\r\n                        2020-2025 John Ky\r\nlicense:                MIT\r\nlicense-file:           LICENSE\r\ntested-with:            GHC == 9.12.2, GHC == 9.10.2, GHC == 9.8.4, GHC == 9.6.7\r\nbuild-type:             Simple\r\nextra-source-files:     CHANGELOG.md\r\n                        README.md\r\n\r\nsource-repository head\r\n  type: git\r\n  location: https://github.com/haskell-works/tasty-discover\r\n\r\nflag dev\r\n  description: Enable development mode\r\n  manual: True\r\n  default: False\r\n\r\ncommon base                       { build-depends: base                       >= 4.11       && < 5      }\r\n\r\ncommon ansi-terminal              { build-depends: ansi-terminal              >= 1.0      && < 2.0      }\r\ncommon bytestring                 { build-depends: bytestring                 >= 0.9      && < 1.0      }\r\ncommon containers                 { build-depends: containers                 >= 0.4      && < 1.0      }\r\ncommon directory                  { build-depends: directory                  >= 1.1      && < 2.0      }\r\ncommon filepath                   { build-depends: filepath                   >= 1.3      && < 2.0      }\r\ncommon Glob                       { build-depends: Glob                       >= 0.8      && < 1.0      }\r\ncommon hedgehog                   { build-depends: hedgehog                   >= 1.0      && < 2.0      }\r\ncommon hspec                      { build-depends: hspec                      >= 2.7      && < 2.12     }\r\ncommon hspec-core                 { build-depends: hspec-core                 >= 2.7.10   && < 2.12     }\r\ncommon tasty                      { build-depends: tasty                      >= 1.3      && < 2.0      }\r\ncommon tasty-golden               { build-depends: tasty-golden               >= 2.0      && < 3.0      }\r\ncommon tasty-hedgehog             { build-depends: tasty-hedgehog             >= 1.2      && < 2.0      }\r\ncommon tasty-hspec                { build-depends: tasty-hspec                >= 1.1      && < 1.3      }\r\ncommon tasty-hunit                { build-depends: tasty-hunit                >= 0.10     && < 0.11     }\r\ncommon tasty-quickcheck           { build-depends: tasty-quickcheck           >= 0.10     && < 0.12     }\r\ncommon tasty-smallcheck           { build-depends: tasty-smallcheck           >= 0.8      && < 1.0      }\r\ncommon tasty-expected-failure     { build-depends: tasty-expected-failure     >= 0.12     && < 0.13     }\r\ncommon process                    { build-depends: process                    >= 1.6      && < 2.0      }\r\ncommon temporary                  { build-depends: temporary                  >= 1.3      && < 1.4      }\r\n\r\ncommon project-config\r\n  default-extensions:   DeriveGeneric\r\n                        DerivingStrategies\r\n  if (impl(ghc >= 9.2.1))\r\n    default-extensions: OverloadedRecordDot\r\n  ghc-options:          -Wall\r\n                        -Widentities\r\n                        -Wincomplete-uni-patterns\r\n                        -Wmissing-deriving-strategies\r\n                        -Wredundant-constraints\r\n                        -Wunused-packages\r\n  default-language:     Haskell2010\r\n  if (flag(dev))\r\n    ghc-options:        -Werror\r\n\r\ncommon tasty-discover\r\n  build-depends: tasty-discover\r\n\r\nlibrary\r\n  import:               base, project-config\r\n                      , containers\r\n                      , directory\r\n                      , filepath\r\n                      , Glob\r\n                      , tasty\r\n  exposed-modules:      Test.Tasty.Discover\r\n                        Test.Tasty.Discover.Internal.Config\r\n                        Test.Tasty.Discover.Internal.Driver\r\n                        Test.Tasty.Discover.Internal.Generator\r\n                        Test.Tasty.Discover.Internal.Unsafe\r\n                        Test.Tasty.Discover.TastyInfo\r\n                        Test.Tasty.Discover.Version\r\n  other-modules:        Paths_tasty_discover\r\n  autogen-modules:      Paths_tasty_discover\r\n  hs-source-dirs:       src\r\n  default-language:     Haskell2010\r\n\r\nexecutable tasty-discover\r\n  import:               base, project-config\r\n                      , filepath\r\n  main-is:              app/Main.hs\r\n  autogen-modules:      Paths_tasty_discover\r\n  other-modules:        Paths_tasty_discover\r\n  build-depends:        tasty-discover\r\n  default-language:     Haskell2010\r\n\r\ntest-suite tasty-discover-test\r\n  import:               base, project-config\r\n                      , ansi-terminal\r\n                      , bytestring\r\n                      , containers\r\n                      , directory\r\n                      , filepath\r\n                      , hedgehog\r\n                      , hspec\r\n                      , hspec-core\r\n                      , process\r\n                      , tasty\r\n                      , tasty-expected-failure\r\n                      , tasty-golden\r\n                      , tasty-hedgehog\r\n                      , tasty-hspec\r\n                      , tasty-hunit\r\n                      , tasty-quickcheck\r\n                      , tasty-smallcheck\r\n                      , temporary\r\n  type:                 exitcode-stdio-1.0\r\n  main-is:              Driver.hs\r\n  ghc-options:          -threaded -rtsopts -with-rtsopts=-N\r\n  other-modules:        BackupFiles.ValidTest\r\n                        ConfigTest\r\n                        DiscoverTest\r\n                        ModulesGlob.Sub.OneTest\r\n                        ModulesGlob.TwoTest\r\n                        SubMod.FooBaz\r\n                        SubMod.PropTest\r\n                        SubMod.SubSubMod.PropTest\r\n  other-modules:        Paths_tasty_discover\r\n  autogen-modules:      Paths_tasty_discover\r\n  hs-source-dirs:       test\r\n  build-depends:        tasty-discover\r\n  default-language:     Haskell2010\r\n  build-tool-depends:   tasty-discover:tasty-discover\r\n\r\ntest-suite no-main-test\r\n  import:               base, project-config\r\n                      , tasty\r\n                      , tasty-hunit\r\n                      , tasty-quickcheck\r\n  type:                 exitcode-stdio-1.0\r\n  main-is:              Main.hs\r\n  ghc-options:          -threaded -rtsopts -with-rtsopts=-N\r\n  other-modules:        Tests\r\n                        Tests.Simple\r\n  other-modules:        Paths_tasty_discover\r\n  autogen-modules:      Paths_tasty_discover\r\n  hs-source-dirs:       test-no-main\r\n  build-depends:        tasty-discover\r\n  default-language:     Haskell2010\r\n  build-tool-depends:   tasty-discover:tasty-discover\r\n";
  }