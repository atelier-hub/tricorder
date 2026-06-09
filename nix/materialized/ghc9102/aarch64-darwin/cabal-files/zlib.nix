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
    flags = {
      non-blocking-ffi = true;
      pkg-config = true;
      bundled-c-zlib = false;
    };
    package = {
      specVersion = "1.10";
      identifier = { name = "zlib"; version = "0.7.1.1"; };
      license = "BSD-3-Clause";
      copyright = "(c) 2006-2016 Duncan Coutts";
      maintainer = "Duncan Coutts <duncan@community.haskell.org>, Andrew Lelechenko <andrew.lelechenko@gmail.com>, Emily Pillmore <emilypi@cohomolo.gy>, Herbert Valerio Riedel <hvr@gnu.org>";
      author = "Duncan Coutts <duncan@community.haskell.org>";
      homepage = "";
      url = "";
      synopsis = "Compression and decompression in the gzip and zlib formats";
      description = "This package provides a pure interface for compressing and\ndecompressing streams of data represented as lazy\n'ByteString's. It uses the\n<https://en.wikipedia.org/wiki/Zlib zlib C library>\nso it has high performance. It supports the \\\"zlib\\\",\n\\\"gzip\\\" and \\\"raw\\\" compression formats.\n\nIt provides a convenient high level API suitable for most\ntasks and for the few cases where more control is needed it\nprovides access to the full zlib feature set.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
        ] ++ pkgs.lib.optional (flags.bundled-c-zlib || compiler.isGhcjs && true || system.isGhcjs || system.isWasm32 || !flags.pkg-config && system.isWindows) (hsPkgs."zlib-clib" or (errorHandler.buildDepError "zlib-clib"));
        libs = pkgs.lib.optionals (!(flags.bundled-c-zlib || compiler.isGhcjs && true || system.isGhcjs || system.isWasm32 || !flags.pkg-config && system.isWindows)) (pkgs.lib.optional (!flags.pkg-config) (pkgs."z" or (errorHandler.sysDepError "z")));
        pkgconfig = pkgs.lib.optionals (!(flags.bundled-c-zlib || compiler.isGhcjs && true || system.isGhcjs || system.isWasm32 || !flags.pkg-config && system.isWindows)) (pkgs.lib.optional (flags.pkg-config) (pkgconfPkgs."zlib" or (errorHandler.pkgConfDepError "zlib")));
        build-tools = [
          (hsPkgs.pkgsBuildBuild.hsc2hs.components.exes.hsc2hs or (pkgs.pkgsBuildBuild.hsc2hs or (errorHandler.buildToolDepError "hsc2hs:hsc2hs")))
        ] ++ pkgs.lib.optional (system.isWindows && (compiler.isGhc && compiler.version.lt "8.4")) (hsPkgs.pkgsBuildBuild.hsc2hs.components.exes.hsc2hs or (pkgs.pkgsBuildBuild.hsc2hs or (errorHandler.buildToolDepError "hsc2hs:hsc2hs")));
        buildable = true;
      };
      tests = {
        "tests" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."zlib" or (errorHandler.buildDepError "zlib"))
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
      url = "http://hackage.haskell.org/package/zlib-0.7.1.1.tar.gz";
      sha256 = "bf95ab01ed924be800addea195fba5ca97ec69f378368f6ff466bdc29666c1c1";
    });
  }) // {
    package-description-override = "cabal-version:   >= 1.10\nname:            zlib\nversion:         0.7.1.1\n\ncopyright:       (c) 2006-2016 Duncan Coutts\nlicense:         BSD3\nlicense-file:    LICENSE\nauthor:          Duncan Coutts <duncan@community.haskell.org>\nmaintainer:      Duncan Coutts <duncan@community.haskell.org>, Andrew Lelechenko <andrew.lelechenko@gmail.com>, Emily Pillmore <emilypi@cohomolo.gy>, Herbert Valerio Riedel <hvr@gnu.org>\nbug-reports:     https://github.com/haskell/zlib/issues\ncategory:        Codec\nsynopsis:        Compression and decompression in the gzip and zlib formats\ndescription:     This package provides a pure interface for compressing and\n                 decompressing streams of data represented as lazy\n                 'ByteString's. It uses the\n                 <https://en.wikipedia.org/wiki/Zlib zlib C library>\n                 so it has high performance. It supports the \\\"zlib\\\",\n                 \\\"gzip\\\" and \\\"raw\\\" compression formats.\n                 .\n                 It provides a convenient high level API suitable for most\n                 tasks and for the few cases where more control is needed it\n                 provides access to the full zlib feature set.\nbuild-type:      Simple\n\ntested-with:     GHC == 8.0.2\n               , GHC == 8.2.2\n               , GHC == 8.4.4\n               , GHC == 8.6.5\n               , GHC == 8.8.4\n               , GHC == 8.10.7\n               , GHC == 9.0.2\n               , GHC == 9.2.8\n               , GHC == 9.4.8\n               , GHC == 9.6.7\n               , GHC == 9.8.4\n               , GHC == 9.10.2\n               , GHC == 9.12.2\n               , GHC == 9.14.1\n\nextra-source-files: changelog.md\n                    README.md\n                    -- extra headers\n                    cbits-extra/hs-zlib.h\n                    -- test data files\n                    test/data/bad-crc.gz test/data/custom-dict.zlib\n                    test/data/custom-dict.zlib-dict test/data/hello.gz\n                    test/data/not-gzip test/data/two-files.gz\n                    -- demo programs:\n                    examples/gzip.hs examples/gunzip.hs\n\nsource-repository head\n  type: git\n  location: https://github.com/haskell/zlib.git\n\nflag non-blocking-ffi\n  default:     True\n  manual:      True\n  description: The (de)compression calls can sometimes take a long time, which\n               prevents other Haskell threads running. Enabling this flag\n               avoids this unfairness, but with greater overall cost.\n\nflag pkg-config\n  default:     True\n  manual:      False\n  description: Use @pkg-config@ executable to locate foreign @zlib@ library.\n\nflag bundled-c-zlib\n  default:     False\n  manual:      True\n  description: Use @zlib-clib@ package with C sources instead of a system library.\n               C sources are used for GHCJS and WASM unconditionally\n               and on Windows unless @pkg-config@ flag is on.\n\nlibrary\n  exposed-modules: Codec.Compression.GZip,\n                   Codec.Compression.Zlib,\n                   Codec.Compression.Zlib.Raw,\n                   Codec.Compression.Zlib.Internal\n  other-modules:   Codec.Compression.Zlib.Stream,\n                   Codec.Compression.Zlib.ByteStringCompat\n\n  default-language: Haskell2010\n\n  other-extensions: CPP, ForeignFunctionInterface, RankNTypes, BangPatterns\n  other-extensions: DeriveGeneric\n  other-extensions: CApiFFI\n\n  build-depends:   base >= 4.9 && < 4.23,\n                   bytestring >= 0.9 && < 0.13\n\n  build-tools:     hsc2hs >= 0.67 && < 0.69\n  if os(windows) && impl(ghc < 8.4)\n    build-tools:     hsc2hs < 0.68.5\n    -- GHC 7 ships hsc2hs-0.67\n\n  include-dirs:    cbits-extra\n  c-sources:       cbits-extra/hs-zlib.c\n  ghc-options:     -Wall -fwarn-tabs\n  if flag(non-blocking-ffi)\n    cpp-options:   -DNON_BLOCKING_FFI\n\n  -- Cross-platform builds (such as JS and WASM) must have access\n  -- to C sources, so using zlib-clib unconditionally.\n  --\n  -- On Windows, zlib is shipped as part of GHC's mingw/lib directory,\n  -- which GHC always includes in its linker search path. However,\n  -- there is no guarantee that zlib1.dll (the corresponding shared library)\n  -- will be available on the user's PATH at runtime, making it risky to depend upon\n  -- (see https://github.com/haskell/zlib/issues/65 for what can go wrong).\n  -- Thus, we resort to zlib-clib unless pkg-config is available.\n  if flag(bundled-c-zlib) || impl(ghcjs) || os(ghcjs) || arch(wasm32) || (!flag(pkg-config) && os(windows))\n    build-depends: zlib-clib < 2\n  else\n    if flag(pkg-config)\n      -- NB: pkg-config is available on windows as well when using msys2\n      pkgconfig-depends: zlib\n    else\n      extra-libraries: z\n\ntest-suite tests\n  type: exitcode-stdio-1.0\n  main-is:         Test.hs\n  other-modules:   Utils,\n                   Test.Codec.Compression.Zlib.Internal,\n                   Test.Codec.Compression.Zlib.Stream\n  hs-source-dirs:  test\n  default-language: Haskell2010\n  build-depends:   base, bytestring, zlib,\n                   QuickCheck       == 2.*,\n                   tasty            >= 0.8 && < 1.6,\n                   tasty-quickcheck >= 0.8 && < 1\n  ghc-options:     -Wall\n\n  if impl(ghc >= 9.4)\n    ghc-options:   \"-with-rtsopts=-M1G\"\n";
  }