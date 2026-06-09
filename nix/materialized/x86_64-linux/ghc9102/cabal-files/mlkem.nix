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
    flags = { use_crypton = true; };
    package = {
      specVersion = "2.2";
      identifier = { name = "mlkem"; version = "0.2.1.0"; };
      license = "BSD-3-Clause";
      copyright = "2025 Olivier Chéron";
      maintainer = "olivier.cheron@gmail.com";
      author = "Olivier Chéron";
      homepage = "https://codeberg.org/ocheron/hs-mlkem#readme";
      url = "";
      synopsis = "Module-Lattice-based Key-Encapsulation Mechanism";
      description = "Module-Lattice-based Key-Encapsulation Mechanism (ML-KEM) implemented in\nHaskell.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."deepseq" or (errorHandler.buildDepError "deepseq"))
          (hsPkgs."primitive" or (errorHandler.buildDepError "primitive"))
        ] ++ (if flags.use_crypton
          then [
            (hsPkgs."crypton" or (errorHandler.buildDepError "crypton"))
            (hsPkgs."ram" or (errorHandler.buildDepError "ram"))
          ]
          else [
            (hsPkgs."cryptonite" or (errorHandler.buildDepError "cryptonite"))
            (hsPkgs."memory" or (errorHandler.buildDepError "memory"))
          ]);
        buildable = true;
      };
      tests = {
        "mlkem-test" = {
          depends = [
            (hsPkgs."aeson" or (errorHandler.buildDepError "aeson"))
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."deepseq" or (errorHandler.buildDepError "deepseq"))
            (hsPkgs."directory" or (errorHandler.buildDepError "directory"))
            (hsPkgs."mlkem" or (errorHandler.buildDepError "mlkem"))
            (hsPkgs."primitive" or (errorHandler.buildDepError "primitive"))
            (hsPkgs."process" or (errorHandler.buildDepError "process"))
            (hsPkgs."tasty" or (errorHandler.buildDepError "tasty"))
            (hsPkgs."tasty-hunit" or (errorHandler.buildDepError "tasty-hunit"))
            (hsPkgs."tasty-quickcheck" or (errorHandler.buildDepError "tasty-quickcheck"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
            (hsPkgs."zlib" or (errorHandler.buildDepError "zlib"))
          ] ++ (if flags.use_crypton
            then [
              (hsPkgs."crypton" or (errorHandler.buildDepError "crypton"))
              (hsPkgs."ram" or (errorHandler.buildDepError "ram"))
            ]
            else [
              (hsPkgs."cryptonite" or (errorHandler.buildDepError "cryptonite"))
              (hsPkgs."memory" or (errorHandler.buildDepError "memory"))
            ]);
          buildable = true;
        };
        "mlkem-test-full" = {
          depends = [
            (hsPkgs."aeson" or (errorHandler.buildDepError "aeson"))
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."deepseq" or (errorHandler.buildDepError "deepseq"))
            (hsPkgs."directory" or (errorHandler.buildDepError "directory"))
            (hsPkgs."primitive" or (errorHandler.buildDepError "primitive"))
            (hsPkgs."process" or (errorHandler.buildDepError "process"))
            (hsPkgs."tasty" or (errorHandler.buildDepError "tasty"))
            (hsPkgs."tasty-hunit" or (errorHandler.buildDepError "tasty-hunit"))
            (hsPkgs."tasty-quickcheck" or (errorHandler.buildDepError "tasty-quickcheck"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
            (hsPkgs."zlib" or (errorHandler.buildDepError "zlib"))
          ] ++ (if flags.use_crypton
            then [
              (hsPkgs."crypton" or (errorHandler.buildDepError "crypton"))
              (hsPkgs."ram" or (errorHandler.buildDepError "ram"))
            ]
            else [
              (hsPkgs."cryptonite" or (errorHandler.buildDepError "cryptonite"))
              (hsPkgs."memory" or (errorHandler.buildDepError "memory"))
            ]);
          buildable = true;
        };
      };
      benchmarks = {
        "mlkem-bench" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."criterion" or (errorHandler.buildDepError "criterion"))
            (hsPkgs."deepseq" or (errorHandler.buildDepError "deepseq"))
            (hsPkgs."mlkem" or (errorHandler.buildDepError "mlkem"))
            (hsPkgs."primitive" or (errorHandler.buildDepError "primitive"))
          ] ++ (if flags.use_crypton
            then [
              (hsPkgs."crypton" or (errorHandler.buildDepError "crypton"))
              (hsPkgs."ram" or (errorHandler.buildDepError "ram"))
            ]
            else [
              (hsPkgs."cryptonite" or (errorHandler.buildDepError "cryptonite"))
              (hsPkgs."memory" or (errorHandler.buildDepError "memory"))
            ]);
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/mlkem-0.2.1.0.tar.gz";
      sha256 = "6da2bc59835f0ddab892ede68ee1fd9d8230efd959462078c174866330068957";
    });
  }) // {
    package-description-override = "cabal-version: 2.2\n\n-- This file has been generated from package.yaml by hpack version 0.39.1.\n--\n-- see: https://github.com/sol/hpack\n\nname:           mlkem\nversion:        0.2.1.0\nsynopsis:       Module-Lattice-based Key-Encapsulation Mechanism\ndescription:    Module-Lattice-based Key-Encapsulation Mechanism (ML-KEM) implemented in\n                Haskell.\ncategory:       Crypto\nhomepage:       https://codeberg.org/ocheron/hs-mlkem#readme\nbug-reports:    https://codeberg.org/ocheron/hs-mlkem/issues\nauthor:         Olivier Chéron\nmaintainer:     olivier.cheron@gmail.com\ncopyright:      2025 Olivier Chéron\nlicense:        BSD-3-Clause\nlicense-file:   LICENSE\nbuild-type:     Simple\nextra-source-files:\n    README.md\n    tests/get-vectors.sh\nextra-doc-files:\n    CHANGELOG.md\n\nsource-repository head\n  type: git\n  location: https://codeberg.org/ocheron/hs-mlkem\n\nflag use_crypton\n  description: Use crypton instead of cryptonite\n  manual: True\n  default: True\n\nlibrary\n  exposed-modules:\n      Crypto.PubKey.ML_KEM\n  other-modules:\n      Auxiliary\n      Base\n      Block\n      BlockN\n      Builder\n      ByteArrayST\n      Crypto\n      Equality\n      Fusion\n      Internal\n      Iterate\n      K_PKE\n      Machine\n      Marking\n      Math\n      Matrix\n      ScrubbedBlock\n      SecureBlock\n      SecureBytes\n      Vector\n      Paths_mlkem\n  autogen-modules:\n      Paths_mlkem\n  hs-source-dirs:\n      src\n  ghc-options: -Wall -Wcompat -Widentities -Wincomplete-record-updates -Wincomplete-uni-patterns -Wmissing-export-lists -Wmissing-home-modules -Wpartial-fields -Wredundant-constraints -Wno-unticked-promoted-constructors -O2\n  build-depends:\n      base >=4.7 && <5\n    , deepseq\n    , primitive >=0.7.2\n  default-language: Haskell2010\n  if flag(use_crypton)\n    build-depends:\n        crypton >=1.1.1\n      , ram\n  else\n    build-depends:\n        cryptonite >=0.26\n      , memory\n\ntest-suite mlkem-test\n  type: exitcode-stdio-1.0\n  main-is: Tests.hs\n  other-modules:\n      EncapDecap\n      KeyGen\n      Util\n      Vectors\n      Paths_mlkem\n  autogen-modules:\n      Paths_mlkem\n  hs-source-dirs:\n      tests\n  ghc-options: -Wall -Wcompat -Widentities -Wincomplete-record-updates -Wincomplete-uni-patterns -Wmissing-export-lists -Wmissing-home-modules -Wpartial-fields -Wredundant-constraints -Wno-unticked-promoted-constructors -threaded -rtsopts -with-rtsopts=-N\n  build-depends:\n      aeson\n    , base >=4.7 && <5\n    , bytestring\n    , deepseq\n    , directory\n    , mlkem\n    , primitive >=0.7.2\n    , process\n    , tasty\n    , tasty-hunit\n    , tasty-quickcheck\n    , text\n    , zlib\n  default-language: Haskell2010\n  if flag(use_crypton)\n    build-depends:\n        crypton >=1.1.1\n      , ram\n  else\n    build-depends:\n        cryptonite >=0.26\n      , memory\n\ntest-suite mlkem-test-full\n  type: exitcode-stdio-1.0\n  main-is: Tests.hs\n  other-modules:\n      Auxiliary\n      Base\n      Block\n      BlockN\n      Builder\n      ByteArrayST\n      Crypto\n      Crypto.PubKey.ML_KEM\n      Equality\n      Fusion\n      Internal\n      Iterate\n      K_PKE\n      Machine\n      Marking\n      Math\n      Matrix\n      ScrubbedBlock\n      SecureBlock\n      SecureBytes\n      Vector\n      EncapDecap\n      KeyGen\n      Util\n      Vectors\n      Paths_mlkem\n  autogen-modules:\n      Paths_mlkem\n  hs-source-dirs:\n      src\n      tests\n  ghc-options: -Wall -Wcompat -Widentities -Wincomplete-record-updates -Wincomplete-uni-patterns -Wmissing-export-lists -Wmissing-home-modules -Wpartial-fields -Wredundant-constraints -Wno-unticked-promoted-constructors -fno-ignore-asserts -threaded -rtsopts -with-rtsopts=-N\n  cpp-options: -DML_KEM_TESTING\n  build-depends:\n      aeson\n    , base >=4.7 && <5\n    , bytestring\n    , deepseq\n    , directory\n    , primitive >=0.7.2\n    , process\n    , tasty\n    , tasty-hunit\n    , tasty-quickcheck\n    , text\n    , zlib\n  default-language: Haskell2010\n  if flag(use_crypton)\n    build-depends:\n        crypton >=1.1.1\n      , ram\n  else\n    build-depends:\n        cryptonite >=0.26\n      , memory\n\nbenchmark mlkem-bench\n  type: exitcode-stdio-1.0\n  main-is: Bench.hs\n  other-modules:\n      Paths_mlkem\n  autogen-modules:\n      Paths_mlkem\n  hs-source-dirs:\n      benchs\n  ghc-options: -Wall -Wcompat -Widentities -Wincomplete-record-updates -Wincomplete-uni-patterns -Wmissing-export-lists -Wmissing-home-modules -Wpartial-fields -Wredundant-constraints -Wno-unticked-promoted-constructors -threaded -rtsopts -with-rtsopts=-N -with-rtsopts=-A48m\n  build-depends:\n      base >=4.7 && <5\n    , criterion\n    , deepseq\n    , mlkem\n    , primitive >=0.7.2\n  default-language: Haskell2010\n  if flag(use_crypton)\n    build-depends:\n        crypton >=1.1.1\n      , ram\n  else\n    build-depends:\n        cryptonite >=0.26\n      , memory\n";
  }