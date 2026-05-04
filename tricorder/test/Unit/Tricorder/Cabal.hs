module Unit.Tricorder.Cabal (gpd, cabalFixture) where

import Distribution.PackageDescription.Parsec (parseGenericPackageDescriptionMaybe)
import Distribution.Types.GenericPackageDescription (GenericPackageDescription)


--------------------------------------------------------------------------------
-- Helpers
--------------------------------------------------------------------------------

gpd :: GenericPackageDescription
gpd =
    fromMaybe (error "cabalFixture failed to parse")
        $ parseGenericPackageDescriptionMaybe cabalFixture


cabalFixture :: ByteString
cabalFixture =
    "cabal-version: 2.0\n\
    \name:          myapp\n\
    \version:       0.1.0.0\n\
    \build-type:    Simple\n\
    \\n\
    \library\n\
    \  hs-source-dirs: src\n\
    \  build-depends: base\n\
    \  default-language: Haskell2010\n\
    \\n\
    \library myapp-utils\n\
    \  hs-source-dirs: utils\n\
    \  build-depends: base\n\
    \  default-language: Haskell2010\n\
    \\n\
    \executable myapp-exe\n\
    \  main-is: Main.hs\n\
    \  hs-source-dirs: app\n\
    \  build-depends: base\n\
    \  default-language: Haskell2010\n\
    \\n\
    \test-suite myapp-test\n\
    \  type: exitcode-stdio-1.0\n\
    \  main-is: Test.hs\n\
    \  hs-source-dirs: test\n\
    \  build-depends: base\n\
    \  default-language: Haskell2010\n"
