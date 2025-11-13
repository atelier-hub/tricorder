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
    flags = { simd = true; };
    package = {
      specVersion = "2.0";
      identifier = { name = "bitvec"; version = "1.1.5.0"; };
      license = "BSD-3-Clause";
      copyright = "2019-2022 Andrew Lelechenko, 2012-2016 James Cook";
      maintainer = "Andrew Lelechenko <andrew.lelechenko@gmail.com>";
      author = "Andrew Lelechenko <andrew.lelechenko@gmail.com>,\nJames Cook <mokus@deepbondi.net>";
      homepage = "https://github.com/Bodigrim/bitvec";
      url = "";
      synopsis = "Space-efficient bit vectors";
      description = "A newtype over 'Bool' with a better 'Vector' instance: 8x less memory, up to 3500x faster.\n\nThe <https://hackage.haskell.org/package/vector vector>\npackage represents unboxed arrays of 'Bool's\nspending 1 byte (8 bits) per boolean.\nThis library provides a newtype wrapper 'Bit' and a custom instance\nof an unboxed 'Vector', which packs bits densely,\nachieving an __8x smaller memory footprint.__\nThe performance stays mostly the same;\nthe most significant degradation happens for random writes\n(up to 10% slower).\nOn the other hand, for certain bulk bit operations\n'Vector' 'Bit' is up to 3500x faster than 'Vector' 'Bool'.\n\n=== Thread safety\n\n* \"Data.Bit\" is faster, but writes and flips are not thread-safe.\nThis is because naive updates are not atomic:\nthey read the whole word from memory,\nthen modify a bit, then write the whole word back.\nConcurrently modifying non-intersecting slices of the same underlying array\nmay also lead to unexpected results, since they can share a word in memory.\n* \"Data.Bit.ThreadSafe\" is slower (usually 10-20%),\nbut writes and flips are thread-safe.\nAdditionally, concurrently modifying non-intersecting slices of the same underlying array\nworks as expected. However, operations that affect multiple elements are not\nguaranteed to be atomic.\n\n=== Similar packages\n\n* <https://hackage.haskell.org/package/bv bv> and\n<https://hackage.haskell.org/package/bv-little bv-little>\ndo not offer mutable vectors.\n\n* <https://hackage.haskell.org/package/array array>\nis memory-efficient for 'Bool', but lacks\na handy 'Vector' interface and is not thread-safe.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          (hsPkgs."deepseq" or (errorHandler.buildDepError "deepseq"))
          (hsPkgs."primitive" or (errorHandler.buildDepError "primitive"))
          (hsPkgs."vector" or (errorHandler.buildDepError "vector"))
        ] ++ (if compiler.isGhc && compiler.version.lt "9.0"
          then [
            (hsPkgs."integer-gmp" or (errorHandler.buildDepError "integer-gmp"))
          ]
          else [
            (hsPkgs."ghc-bignum" or (errorHandler.buildDepError "ghc-bignum"))
          ]);
        buildable = true;
      };
      tests = {
        "bitvec-tests" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."bitvec" or (errorHandler.buildDepError "bitvec"))
            (hsPkgs."primitive" or (errorHandler.buildDepError "primitive"))
            (hsPkgs."quickcheck-classes-base" or (errorHandler.buildDepError "quickcheck-classes-base"))
            (hsPkgs."quickcheck-classes" or (errorHandler.buildDepError "quickcheck-classes"))
            (hsPkgs."vector" or (errorHandler.buildDepError "vector"))
            (hsPkgs."tasty" or (errorHandler.buildDepError "tasty"))
            (hsPkgs."tasty-quickcheck" or (errorHandler.buildDepError "tasty-quickcheck"))
          ] ++ (if compiler.isGhc && compiler.version.lt "9.0"
            then [
              (hsPkgs."integer-gmp" or (errorHandler.buildDepError "integer-gmp"))
            ]
            else [
              (hsPkgs."ghc-bignum" or (errorHandler.buildDepError "ghc-bignum"))
            ]);
          buildable = true;
        };
      };
      benchmarks = {
        "bitvec-bench" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."bitvec" or (errorHandler.buildDepError "bitvec"))
            (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
            (hsPkgs."random" or (errorHandler.buildDepError "random"))
            (hsPkgs."tasty" or (errorHandler.buildDepError "tasty"))
            (hsPkgs."tasty-bench" or (errorHandler.buildDepError "tasty-bench"))
            (hsPkgs."vector" or (errorHandler.buildDepError "vector"))
          ] ++ (if compiler.isGhc && compiler.version.lt "9.0"
            then [
              (hsPkgs."integer-gmp" or (errorHandler.buildDepError "integer-gmp"))
            ]
            else [
              (hsPkgs."ghc-bignum" or (errorHandler.buildDepError "ghc-bignum"))
            ]);
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/bitvec-1.1.5.0.tar.gz";
      sha256 = "83d27cee5be1d5342ddbf39999d0c8ea54cb433d0891eea5471fbfaa29f8dec5";
    });
  }) // {
    package-description-override = "name: bitvec\r\nversion: 1.1.5.0\r\nx-revision: 3\r\ncabal-version: 2.0\r\nbuild-type: Simple\r\nlicense: BSD3\r\nlicense-file: LICENSE\r\ncopyright: 2019-2022 Andrew Lelechenko, 2012-2016 James Cook\r\nmaintainer: Andrew Lelechenko <andrew.lelechenko@gmail.com>\r\nhomepage: https://github.com/Bodigrim/bitvec\r\nsynopsis: Space-efficient bit vectors\r\ndescription:\r\n  A newtype over 'Bool' with a better 'Vector' instance: 8x less memory, up to 3500x faster.\r\n  .\r\n  The <https://hackage.haskell.org/package/vector vector>\r\n  package represents unboxed arrays of 'Bool's\r\n  spending 1 byte (8 bits) per boolean.\r\n  This library provides a newtype wrapper 'Bit' and a custom instance\r\n  of an unboxed 'Vector', which packs bits densely,\r\n  achieving an __8x smaller memory footprint.__\r\n  The performance stays mostly the same;\r\n  the most significant degradation happens for random writes\r\n  (up to 10% slower).\r\n  On the other hand, for certain bulk bit operations\r\n  'Vector' 'Bit' is up to 3500x faster than 'Vector' 'Bool'.\r\n  .\r\n  === Thread safety\r\n  .\r\n  * \"Data.Bit\" is faster, but writes and flips are not thread-safe.\r\n    This is because naive updates are not atomic:\r\n    they read the whole word from memory,\r\n    then modify a bit, then write the whole word back.\r\n    Concurrently modifying non-intersecting slices of the same underlying array\r\n    may also lead to unexpected results, since they can share a word in memory.\r\n  * \"Data.Bit.ThreadSafe\" is slower (usually 10-20%),\r\n    but writes and flips are thread-safe.\r\n    Additionally, concurrently modifying non-intersecting slices of the same underlying array\r\n    works as expected. However, operations that affect multiple elements are not\r\n    guaranteed to be atomic.\r\n  .\r\n  === Similar packages\r\n  .\r\n  * <https://hackage.haskell.org/package/bv bv> and\r\n    <https://hackage.haskell.org/package/bv-little bv-little>\r\n    do not offer mutable vectors.\r\n  .\r\n  * <https://hackage.haskell.org/package/array array>\r\n    is memory-efficient for 'Bool', but lacks\r\n    a handy 'Vector' interface and is not thread-safe.\r\n\r\ncategory: Data, Bit Vectors\r\nauthor: Andrew Lelechenko <andrew.lelechenko@gmail.com>,\r\n        James Cook <mokus@deepbondi.net>\r\n\r\ntested-with: GHC ==8.4.4 GHC ==8.6.5 GHC ==8.8.1 GHC ==8.8.2 GHC ==8.8.4 GHC ==8.10.7 GHC ==9.0.2 GHC ==9.2.7 GHC ==9.4.4 GHC ==9.6.1\r\nextra-doc-files:\r\n  changelog.md\r\n  README.md\r\n\r\nsource-repository head\r\n  type: git\r\n  location: git://github.com/Bodigrim/bitvec.git\r\n\r\nflag simd\r\n  description:\r\n    Use a C SIMD implementation for the ultimate performance of `zipBits`, `invertBits` and `countBits`.\r\n    Disable this flag if there are problems with the C FFI.\r\n  default: True\r\n  manual: True\r\n\r\nlibrary\r\n  exposed-modules:\r\n    Data.Bit\r\n    Data.Bit.ThreadSafe\r\n  build-depends:\r\n    base >=4.11 && <5,\r\n    bytestring >=0.10 && <0.13,\r\n    deepseq <1.6,\r\n    primitive >=0.5,\r\n    vector >=0.11 && <0.14\r\n  default-language: Haskell2010\r\n  hs-source-dirs: src\r\n  other-modules:\r\n    Data.Bit.F2Poly\r\n    Data.Bit.F2PolyTS\r\n    Data.Bit.Immutable\r\n    Data.Bit.ImmutableTS\r\n    Data.Bit.Internal\r\n    Data.Bit.InternalTS\r\n    Data.Bit.Mutable\r\n    Data.Bit.MutableTS\r\n    Data.Bit.PdepPext\r\n    Data.Bit.Utils\r\n  ghc-options: -O2 -Wall -Wcompat\r\n  include-dirs: src\r\n\r\n  if impl(ghc <9.0)\r\n    build-depends: integer-gmp\r\n  else\r\n    build-depends: ghc-bignum\r\n\r\n  if flag(simd) && !arch(javascript) && !arch(wasm32)\r\n    c-sources: cbits/bitvec_simd.c\r\n    cc-options: -fopenmp-simd\r\n    cpp-options: -DUseSIMD\r\n    other-modules:\r\n      Data.Bit.SIMD\r\n\r\ntest-suite bitvec-tests\r\n  type: exitcode-stdio-1.0\r\n  main-is: Main.hs\r\n  build-depends:\r\n    base,\r\n    bitvec,\r\n    primitive >=0.5 && <0.10,\r\n    quickcheck-classes-base <0.7,\r\n    quickcheck-classes >=0.6.1 && <0.7,\r\n    vector >=0.11,\r\n    tasty <1.6,\r\n    tasty-quickcheck <0.12\r\n  default-language: Haskell2010\r\n  hs-source-dirs: test\r\n  other-modules:\r\n    Support\r\n    Tests.Conc\r\n    Tests.F2Poly\r\n    Tests.MVector\r\n    Tests.MVectorTS\r\n    Tests.SetOps\r\n    Tests.SetOpsTS\r\n    Tests.Vector\r\n  ghc-options: -Wall -threaded -rtsopts -Wcompat\r\n  include-dirs: test\r\n\r\n  if impl(ghc <9.0)\r\n    build-depends: integer-gmp <1.2\r\n  else\r\n    build-depends: ghc-bignum\r\n\r\nbenchmark bitvec-bench\r\n  build-depends:\r\n    base,\r\n    bitvec,\r\n    containers <0.8,\r\n    random <1.4,\r\n    tasty,\r\n    tasty-bench >=0.3.2 && <0.5,\r\n    vector\r\n  type: exitcode-stdio-1.0\r\n  main-is: Bench.hs\r\n  default-language: Haskell2010\r\n  hs-source-dirs: bench\r\n  other-modules:\r\n    Bench.BitIndex\r\n    Bench.Common\r\n    Bench.GCD\r\n    Bench.Invert\r\n    Bench.Intersection\r\n    Bench.Product\r\n    Bench.RandomFlip\r\n    Bench.RandomRead\r\n    Bench.RandomWrite\r\n    Bench.Remainder\r\n    Bench.Reverse\r\n    Bench.Sum\r\n    Bench.Union\r\n  ghc-options: -O2 -Wall -Wcompat\r\n\r\n  if impl(ghc <9.0)\r\n    build-depends: integer-gmp\r\n  else\r\n    build-depends: ghc-bignum\r\n";
  }