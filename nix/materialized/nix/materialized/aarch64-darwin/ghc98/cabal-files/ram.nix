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
      specVersion = "3.0";
      identifier = { name = "ram"; version = "0.22.0"; };
      license = "BSD-3-Clause";
      copyright = "Vincent Hanquez <vincent@snarc.org>";
      maintainer = "hi@jappie.me";
      author = "Vincent Hanquez <vincent@snarc.org>";
      homepage = "https://github.com/jappeace/ram";
      url = "";
      synopsis = "memory and related abstraction stuff";
      description = "This is a fork of memory. It's open to accept changes from anyone,\nand aims to use existing well maintained libraries as much as possible.\n\nChunk of memory, polymorphic byte array management and manipulation\n\n* A polymorphic byte array abstraction and function similar to strict ByteString.\n\n* Different type of byte array abstraction.\n\n* Raw memory IO operations (memory set, memory copy, ..)\n\n* Aliasing with endianness support.\n\n* Encoding : Base16, Base32, Base64.\n\n* Hashing : FNV, SipHash";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          (hsPkgs."deepseq" or (errorHandler.buildDepError "deepseq"))
          (hsPkgs."ghc-prim" or (errorHandler.buildDepError "ghc-prim"))
        ];
        buildable = true;
      };
      tests = {
        "test-memory" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."ram" or (errorHandler.buildDepError "ram"))
            (hsPkgs."QuickCheck" or (errorHandler.buildDepError "QuickCheck"))
            (hsPkgs."tasty" or (errorHandler.buildDepError "tasty"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/ram-0.22.0.tar.gz";
      sha256 = "2f7e4011c36e029d9f3b7079a4e692e1962f330f7f0b0a117f360398d2035d15";
    });
  }) // {
    package-description-override = "cabal-version:   3.0\nname:            ram\nversion:         0.22.0\nsynopsis:        memory and related abstraction stuff\ndescription:\n  This is a fork of memory. It's open to accept changes from anyone,\n  and aims to use existing well maintained libraries as much as possible.\n\n  Chunk of memory, polymorphic byte array management and manipulation\n\n  * A polymorphic byte array abstraction and function similar to strict ByteString.\n\n  * Different type of byte array abstraction.\n\n  * Raw memory IO operations (memory set, memory copy, ..)\n\n  * Aliasing with endianness support.\n\n  * Encoding : Base16, Base32, Base64.\n\n  * Hashing : FNV, SipHash\n\nlicense:         BSD-3-Clause\nlicense-file:    LICENSE\ncopyright:       Vincent Hanquez <vincent@snarc.org>\nauthor:          Vincent Hanquez <vincent@snarc.org>\nmaintainer:      hi@jappie.me\ncategory:        memory\nstability:       experimental\nbuild-type:      Simple\nhomepage:        https://github.com/jappeace/ram\nbug-reports:     https://github.com/jappeace/ram/issues\nextra-doc-files:\n  CHANGELOG.md\n  README.md\n\nsource-repository head\n  type:     git\n  location: https://github.com/jappeace/ram\n\nlibrary\n  exposed-modules:\n    Data.ByteArray\n    Data.ByteArray.Encoding\n    Data.ByteArray.Hash\n    Data.ByteArray.Mapping\n    Data.ByteArray.Pack\n    Data.ByteArray.Parse\n    Data.Memory.Encoding.Base16\n    Data.Memory.Encoding.Base32\n    Data.Memory.Encoding.Base64\n    Data.Memory.Endian\n    Data.Memory.ExtendedWords\n    Data.Memory.PtrMethods\n\n  other-modules:\n    Data.ByteArray.Bytes\n    Data.ByteArray.MemView\n    Data.ByteArray.Methods\n    Data.ByteArray.Pack.Internal\n    Data.ByteArray.ScrubbedBytes\n    Data.ByteArray.Types\n    Data.ByteArray.View\n    Data.Memory.Hash.FNV\n    Data.Memory.Hash.SipHash\n    Data.Memory.Internal.Compat\n    Data.Memory.Internal.CompatPrim\n    Data.Memory.Internal.Imports\n\n  exposed-modules:  Data.ByteArray.Sized\n  build-depends:\n    , base        <4.23\n    , bytestring  <0.13\n    , deepseq     >=1.1 && <1.17\n    , ghc-prim    <0.14\n\n  -- FIXME armel or mispel is also little endian.\n  -- might be a good idea to also add a runtime autodetect mode.\n  -- ARCH_ENDIAN_UNKNOWN\n  if (arch(i386) || arch(x86_64))\n    cpp-options: -DARCH_IS_LITTLE_ENDIAN\n\n  if os(windows)\n    other-modules: Data.Memory.MemMap.Windows\n\n  else\n    other-modules: Data.Memory.MemMap.Posix\n\n  ghc-options:      -Wall -fwarn-tabs\n  default-language: Haskell2010\n\ntest-suite test-memory\n  type:             exitcode-stdio-1.0\n  hs-source-dirs:   tests\n  main-is:          Tests.hs\n  other-modules:\n    Imports\n    SipHash\n    Utils\n\n  build-depends:\n    , base        <5\n    , bytestring\n    , ram\n    , QuickCheck\n    , tasty\n\n  ghc-options:\n    -Wall -fno-warn-orphans -fno-warn-missing-signatures -threaded\n\n  default-language: Haskell2010\n";
  }