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
      identifier = { name = "half"; version = "0.3.3"; };
      license = "BSD-3-Clause";
      copyright = "Copyright (C) 2014 Edward A. Kmett";
      maintainer = "Edward A. Kmett <ekmett@gmail.com>";
      author = "Edward A. Kmett";
      homepage = "http://github.com/ekmett/half";
      url = "";
      synopsis = "Half-precision floating-point";
      description = "Half-precision floating-point.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."binary" or (errorHandler.buildDepError "binary"))
          (hsPkgs."deepseq" or (errorHandler.buildDepError "deepseq"))
          (hsPkgs."template-haskell" or (errorHandler.buildDepError "template-haskell"))
        ];
        buildable = true;
      };
      tests = {
        "spec" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."binary" or (errorHandler.buildDepError "binary"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."half" or (errorHandler.buildDepError "half"))
            (hsPkgs."QuickCheck" or (errorHandler.buildDepError "QuickCheck"))
            (hsPkgs."tasty" or (errorHandler.buildDepError "tasty"))
            (hsPkgs."tasty-quickcheck" or (errorHandler.buildDepError "tasty-quickcheck"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/half-0.3.3.tar.gz";
      sha256 = "f476049628d6ff79722fb073c01e85f2a11b2ef3835fdc3fc21a61f05d17ab02";
    });
  }) // {
    package-description-override = "cabal-version: >=1.10\r\nname: half\r\nversion: 0.3.3\r\nx-revision: 1\r\nlicense: BSD3\r\nlicense-file: LICENSE\r\ncopyright: Copyright (C) 2014 Edward A. Kmett\r\nmaintainer: Edward A. Kmett <ekmett@gmail.com>\r\nauthor: Edward A. Kmett\r\nstability: provisional\r\nhomepage: http://github.com/ekmett/half\r\nbug-reports: http://github.com/ekmett/half/issues\r\nsynopsis: Half-precision floating-point\r\ndescription:\r\n    Half-precision floating-point.\r\ncategory: Numeric\r\nbuild-type: Simple\r\nextra-source-files:\r\n    .gitignore\r\n    README.markdown\r\n    CHANGELOG.markdown\r\n\r\ntested-with:   GHC == 8.0.2\r\n             , GHC == 8.2.2\r\n             , GHC == 8.4.4\r\n             , GHC == 8.6.5\r\n             , GHC == 8.8.4\r\n             , GHC == 8.10.7\r\n             , GHC == 9.0.2\r\n             , GHC == 9.2.8\r\n             , GHC == 9.4.8\r\n             , GHC == 9.6.6\r\n             , GHC == 9.8.4\r\n             , GHC == 9.10.1\r\n             , GHC == 9.12.1\r\n\r\nsource-repository head\r\n    type: git\r\n    location: https://github.com/ekmett/half.git\r\n\r\nlibrary\r\n    default-language: Haskell2010\r\n    exposed-modules:\r\n        Numeric.Half\r\n        Numeric.Half.Internal\r\n    hs-source-dirs: src\r\n    other-extensions: BangPatterns CPP DeriveDataTypeable DeriveGeneric\r\n                      DeriveLift ForeignFunctionInterface PatternSynonyms\r\n                      StandaloneDeriving\r\n    ghc-options: -Wall -Wtabs -O2 -Wno-missing-pattern-synonym-signatures\r\n    build-depends:\r\n        base >=4.9 && <5,\r\n        binary >=0.5.1.0 && <0.9,\r\n        deepseq >=1.4.2.0 && <1.6,\r\n        template-haskell >=2.11\r\n\r\n    if !impl(ghcjs)\r\n      c-sources:\r\n        cbits/half.c\r\n\r\ntest-suite spec\r\n    default-language: Haskell2010\r\n    type: exitcode-stdio-1.0\r\n    main-is: Spec.hs\r\n    hs-source-dirs: test\r\n    ghc-options: -Wall\r\n\r\n    build-depends:\r\n        base,\r\n        binary,\r\n        bytestring,\r\n        half,\r\n        QuickCheck >=2.14.1 && <2.18,\r\n        tasty >= 1.4 && < 1.6,\r\n        tasty-quickcheck >= 0.10 && < 0.12\r\n";
  }