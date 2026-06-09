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
    flags = { deepseq = true; template-haskell = true; };
    package = {
      specVersion = "1.10";
      identifier = { name = "tagged"; version = "0.8.10"; };
      license = "BSD-3-Clause";
      copyright = "2009-2015 Edward A. Kmett";
      maintainer = "Edward A. Kmett <ekmett@gmail.com>";
      author = "Edward A. Kmett";
      homepage = "http://github.com/ekmett/tagged";
      url = "";
      synopsis = "Haskell 98 phantom types to avoid unsafely passing dummy arguments";
      description = "Haskell 98 phantom types to avoid unsafely passing dummy arguments.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = ([
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
        ] ++ pkgs.lib.optional (flags.deepseq) (hsPkgs."deepseq" or (errorHandler.buildDepError "deepseq"))) ++ pkgs.lib.optional (flags.template-haskell && (compiler.isGhc && true)) (hsPkgs."template-haskell" or (errorHandler.buildDepError "template-haskell"));
        buildable = true;
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/tagged-0.8.10.tar.gz";
      sha256 = "17ef791eb4caf314a3b4b158827a0f1f4b695c2a24af0875f09e3d8c10f56c5d";
    });
  }) // {
    package-description-override = "name:           tagged\r\nversion:        0.8.10\r\nx-revision: 1\r\nlicense:        BSD3\r\nlicense-file:   LICENSE\r\nauthor:         Edward A. Kmett\r\nmaintainer:     Edward A. Kmett <ekmett@gmail.com>\r\nstability:      experimental\r\ncategory:       Data, Phantom Types\r\nsynopsis:       Haskell 98 phantom types to avoid unsafely passing dummy arguments\r\nhomepage:       http://github.com/ekmett/tagged\r\nbug-reports:    http://github.com/ekmett/tagged/issues\r\ncopyright:      2009-2015 Edward A. Kmett\r\ndescription:    Haskell 98 phantom types to avoid unsafely passing dummy arguments.\r\nbuild-type:     Simple\r\ncabal-version:  >= 1.10\r\nextra-source-files: .hlint.yaml CHANGELOG.markdown README.markdown\r\ntested-with:\r\n  GHC == 8.0.2\r\n  GHC == 8.2.2\r\n  GHC == 8.4.4\r\n  GHC == 8.6.5\r\n  GHC == 8.8.4\r\n  GHC == 8.10.7\r\n  GHC == 9.0.2\r\n  GHC == 9.2.8\r\n  GHC == 9.4.8\r\n  GHC == 9.6.6\r\n  GHC == 9.8.4\r\n  GHC == 9.10.1\r\n  GHC == 9.12.1\r\n\r\nsource-repository head\r\n  type: git\r\n  location: https://github.com/ekmett/tagged.git\r\n\r\nflag deepseq\r\n  description:\r\n    You can disable the use of the `deepseq` package using `-f-deepseq`.\r\n    .\r\n    Disabing this is an unsupported configuration, but it may be useful for accelerating builds in sandboxes for expert users.\r\n  default: True\r\n  manual: True\r\n\r\nflag template-haskell\r\n  description:\r\n    You can disable the use of the `template-haskell` package using `-f-template-haskell`.\r\n    .\r\n    Disabling this is an unsupported configuration, but it may be useful for accelerating builds in sandboxes for expert users.\r\n  default: True\r\n  manual: True\r\n\r\nlibrary\r\n  default-language: Haskell98\r\n  other-extensions: CPP\r\n  build-depends:\r\n    base >= 4.9 && < 5\r\n  ghc-options: -Wall\r\n  hs-source-dirs: src\r\n  exposed-modules:\r\n    Data.Tagged\r\n\r\n  if impl(ghc >= 9.0)\r\n    -- these flags may abort compilation with GHC-8.10\r\n    -- https://gitlab.haskell.org/ghc/ghc/-/merge_requests/3295\r\n    ghc-options: -Winferred-safe-imports -Wmissing-safe-haskell-mode\r\n\r\n  if flag(deepseq)\r\n    build-depends: deepseq >= 1.1 && < 1.6\r\n\r\n  if flag(template-haskell) && impl(ghc)\r\n    build-depends: template-haskell >= 2.11 && < 2.25\r\n    exposed-modules:\r\n      Data.Proxy.TH\r\n";
  }