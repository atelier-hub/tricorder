module Unit.Tricorder.SessionSpec (spec_Session) where

import Data.Default (Default (..))
import Distribution.PackageDescription.Parsec (parseGenericPackageDescriptionMaybe)
import Distribution.Types.GenericPackageDescription (GenericPackageDescription)
import Test.Hspec

import Tricorder.Session (Session (..), allComponentTargets, resolveTestTargets, sourceDirsForTarget)


spec_Session :: Spec
spec_Session = do
    describe "resolveTestTargets" testResolveTestTargets
    describe "sourceDirsForTarget" do
        describe "lib:" do
            it "returns main library source dirs" do
                sourceDirsForTarget gpd "lib:" `shouldBe` ["src"]

        describe "lib:<package-name>" do
            it "returns main library source dirs when name matches package name" do
                sourceDirsForTarget gpd "lib:myapp" `shouldBe` ["src"]

        describe "lib:<sub-library>" do
            it "returns sub-library source dirs" do
                sourceDirsForTarget gpd "lib:myapp-utils" `shouldBe` ["utils"]

            it "returns empty list for unknown sub-library" do
                sourceDirsForTarget gpd "lib:nonexistent" `shouldBe` []

        describe "exe:<name>" do
            it "returns executable source dirs" do
                sourceDirsForTarget gpd "exe:myapp-exe" `shouldBe` ["app"]

        describe "test:<name>" do
            it "returns test suite source dirs" do
                sourceDirsForTarget gpd "test:myapp-test" `shouldBe` ["test"]

        describe "unknown target" do
            it "returns empty list" do
                sourceDirsForTarget gpd "unknown" `shouldBe` []

    describe "allComponentTargets" do
        it "includes the main library as lib:<package-name>" do
            allComponentTargets gpd `shouldContain` ["lib:myapp"]

        it "includes sub-libraries" do
            allComponentTargets gpd `shouldContain` ["lib:myapp-utils"]

        it "includes executables" do
            allComponentTargets gpd `shouldContain` ["exe:myapp-exe"]

        it "includes test suites" do
            allComponentTargets gpd `shouldContain` ["test:myapp-test"]

        it "returns all four components for the fixture" do
            allComponentTargets gpd
                `shouldBe` ["lib:myapp", "lib:myapp-utils", "exe:myapp-exe", "test:myapp-test"]


testResolveTestTargets :: Spec
testResolveTestTargets = do
    it "infers test: components from targets when testTargets is absent" do
        let cfg = def {targets = ["lib:mylib", "test:mylib-test"]}
        resolveTestTargets cfg `shouldBe` ["test:mylib-test"]

    it "returns empty list when no test: components in targets" do
        let cfg = def {targets = ["lib:mylib", "exe:myapp"]}
        resolveTestTargets cfg `shouldBe` []

    it "uses explicit testTargets list when set" do
        let cfg = def {targets = ["lib:a", "test:a-test", "test:b-test"], testTargets = Just ["test:b-test"]}
        resolveTestTargets cfg `shouldBe` ["test:b-test"]

    it "returns empty list when testTargets is explicitly empty" do
        let cfg = def {targets = ["lib:a", "test:a-test"], testTargets = Just []}
        resolveTestTargets cfg `shouldBe` []

    it "infers multiple test: components" do
        let cfg = def {targets = ["lib:a", "test:a-test", "test:b-test"]}
        resolveTestTargets cfg `shouldBe` ["test:a-test", "test:b-test"]


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
