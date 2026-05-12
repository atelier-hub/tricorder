module Unit.Tricorder.SessionSpec (spec_Session) where

import Data.Default (Default (..))
import Distribution.PackageDescription.Parsec (parseGenericPackageDescriptionMaybe)
import Distribution.Types.GenericPackageDescription (GenericPackageDescription)
import Effectful (runPureEff)
import Effectful.State.Static.Shared (evalState)
import Test.Hspec

import Data.Map.Strict qualified as Map

import Atelier.Effects.FileSystem (runFileSystemState)
import Tricorder.Runtime (ProjectRoot (..))
import Tricorder.Session
    ( Config (..)
    , allComponentTargets
    , resolveCommand
    , resolveTestTargets
    , sourceDirsForTarget
    )


spec_Session :: Spec
spec_Session = do
    describe "resolveCommand" testResolveCommand
    describe "resolveTestTargets" testResolveTestTargets
    describe "sourceDirsForTarget" testSourceDirsForTarget
    describe "allComponentTargets" testAllComponentTargets


testSourceDirsForTarget :: Spec
testSourceDirsForTarget = do
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


testAllComponentTargets :: Spec
testAllComponentTargets = do
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
        let cfg = def :: Config
        resolveTestTargets cfg ["lib:mylib", "test:mylib-test"] `shouldBe` ["test:mylib-test"]

    it "returns empty list when no test: components in targets" do
        let cfg = def :: Config
        resolveTestTargets cfg ["lib:mylib", "exe:myapp"] `shouldBe` []

    it "uses explicit testTargets list when set" do
        let cfg = def {testTargets = Just ["test:b-test"]} :: Config
        resolveTestTargets cfg ["lib:a", "test:a-test", "test:b-test"] `shouldBe` ["test:b-test"]

    it "returns empty list when testTargets is explicitly empty" do
        let cfg = def {testTargets = Just []} :: Config
        resolveTestTargets cfg ["lib:a", "test:a-test"] `shouldBe` []

    it "infers multiple test: components" do
        let cfg = def :: Config
        resolveTestTargets cfg ["lib:a", "test:a-test", "test:b-test"] `shouldBe` ["test:a-test", "test:b-test"]


testResolveCommand :: Spec
testResolveCommand = do
    describe "when config has a command" do
        it "should use specified command" do
            let actual =
                    runPureEff
                        . evalState mempty
                        . runFileSystemState
                        $ resolveCommand pr def {command = Just "foo"}
            actual `shouldBe` "foo"

    describe "when config does not have a command" do
        describe "and there is a cabal.project file" do
            it "should use cabal with --enable-multi-repl" do
                let actual =
                        runPureEff
                            . evalState (Map.singleton "/cabal.project" "")
                            . runFileSystemState
                            $ resolveCommand pr cfg
                actual `shouldBe` "cabal repl --enable-multi-repl --builddir /replbuild lib:foo"

        describe "and there is at least one *.cabal file" do
            it "should use cabal with --enable-multi-repl" do
                let actual =
                        runPureEff
                            . evalState (Map.singleton "/foo.cabal" "")
                            . runFileSystemState
                            $ resolveCommand pr cfg
                actual `shouldBe` "cabal repl --enable-multi-repl --builddir /replbuild lib:foo"
        describe "and there is a stack.yaml file" do
            it "should use stack ghci" do
                let actual =
                        runPureEff
                            . evalState (Map.singleton "/stack.yaml" "")
                            . runFileSystemState
                            $ resolveCommand pr cfg
                actual `shouldBe` "stack ghci lib:foo"

        describe "but there are no project files" do
            it "should use default cabal repl" do
                let actual =
                        runPureEff
                            . evalState mempty
                            . runFileSystemState
                            $ resolveCommand pr cfg
                actual `shouldBe` "cabal repl --builddir /replbuild lib:foo"
  where
    pr = ProjectRoot "/"
    cfg = def {replBuildDir = "/replbuild", targets = ["lib:foo"]}


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
