module Unit.Tricorder.SessionSpec (spec_Session) where

import Atelier.Effects.FileSystem (runFileSystemState)
import Atelier.Effects.Log (runLogNoOp)
import Data.Default (Default (..))
import Distribution.PackageDescription.Parsec (parseGenericPackageDescriptionMaybe)
import Distribution.Types.GenericPackageDescription (GenericPackageDescription)
import Effectful (runPureEff)
import Effectful.State.Static.Shared (evalState)
import Test.Hspec

import Data.Map.Strict qualified as Map
import Data.Text qualified as T

import Tricorder.Runtime (ProjectRoot (..))
import Tricorder.Session
    ( Config (..)
    , allComponentTargets
    , discoverCabalFiles
    , resolveCommand
    , resolveTargets
    , resolveTestTargets
    , resolveWatchDirs
    , sourceDirsForTarget
    )


spec_Session :: Spec
spec_Session = do
    describe "resolveCommand" testResolveCommand
    describe "discoverCabalFiles" testDiscoverCabalFiles
    describe "resolveTargets" testResolveTargets
    describe "resolveWatchDirs" testResolveWatchDirs
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


-- | Pins the discovery contract: a @cabal.project@ selects per-package
-- @.cabal@ files from its @packages:@ stanza; otherwise the @.cabal@ files in
-- the project root are used.
testDiscoverCabalFiles :: Spec
testDiscoverCabalFiles = do
    describe "when there is no cabal.project" do
        it "finds the .cabal files in the project root" do
            let actual =
                    runDiscovery (Map.singleton "/myapp.cabal" cabalFixture)
                        $ discoverCabalFiles pr
            actual `shouldBe` ["/myapp.cabal"]

        it "returns no files when the root has no cabal file" do
            let actual = runDiscovery mempty $ discoverCabalFiles pr
            actual `shouldBe` []

    describe "when there is a multi-package cabal.project" do
        it "resolves each listed package to its .cabal (regression: was root-only)" do
            let actual = runDiscovery multiPackageFs $ discoverCabalFiles pr
            actual `shouldBe` ["/pkg-a/pkg-a.cabal", "/pkg-b/pkg-b.cabal"]
  where
    pr = ProjectRoot "/"
    runDiscovery fs = runPureEff . evalState fs . runFileSystemState . runLogNoOp


testResolveTargets :: Spec
testResolveTargets = do
    describe "when targets are configured" do
        it "returns configured targets as-is without reading any cabal file" do
            -- The cabal file is absent from the mock FS, so any attempt to read
            -- it would error; passing the test proves the early return.
            let actual =
                    runPureEff
                        . evalState mempty
                        . runFileSystemState
                        $ resolveTargets ["/myapp.cabal"] ["lib:foo", "test:foo-test"]
            actual `shouldBe` ["lib:foo", "test:foo-test"]

    describe "when no targets are configured" do
        it "auto-detects all components from the cabal file" do
            let actual =
                    runPureEff
                        . evalState (Map.singleton "/myapp.cabal" cabalFixture)
                        . runFileSystemState
                        $ resolveTargets ["/myapp.cabal"] []
            actual
                `shouldBe` ["lib:myapp", "lib:myapp-utils", "exe:myapp-exe", "test:myapp-test"]

        it "surfaces test-suite components so they can be run after a build" do
            let actual =
                    runPureEff
                        . evalState (Map.singleton "/myapp.cabal" cabalFixture)
                        . runFileSystemState
                        $ resolveTargets ["/myapp.cabal"] []
            actual `shouldContain` ["test:myapp-test"]

        it "returns no targets when there are no cabal files" do
            let actual =
                    runPureEff
                        . evalState mempty
                        . runFileSystemState
                        $ resolveTargets [] []
            actual `shouldBe` []

        it "aggregates components across every package (regression: was 0)" do
            let actual =
                    runPureEff
                        . evalState multiPackageFs
                        . runFileSystemState
                        $ resolveTargets ["/pkg-a/pkg-a.cabal", "/pkg-b/pkg-b.cabal"] []
            actual `shouldContain` ["lib:pkg-a"]
            actual `shouldContain` ["lib:pkg-b"]
            filter ("test:" `T.isPrefixOf`) actual
                `shouldBe` ["test:pkg-a-test", "test:pkg-b-test"]


testResolveWatchDirs :: Spec
testResolveWatchDirs = do
    describe "when watch_dirs is set in config" do
        it "uses config dirs relative to project root" do
            let actual =
                    runPureEff
                        . evalState mempty
                        . runFileSystemState
                        $ resolveWatchDirs pr [] def {watchDirs = ["src", "test"]} []
            actual `shouldBe` ["/src", "/test"]

    describe "when watch_dirs is not set" do
        it "falls back to [\".\"] when targets list is empty" do
            let actual =
                    runPureEff
                        . evalState mempty
                        . runFileSystemState
                        $ resolveWatchDirs pr [] def []
            actual `shouldBe` ["."]

        it "infers source dirs from resolved targets" do
            let actual =
                    runPureEff
                        . evalState (Map.singleton "/myapp.cabal" cabalFixture)
                        . runFileSystemState
                        $ resolveWatchDirs pr ["/myapp.cabal"] def ["lib:myapp", "test:myapp-test"]
            actual `shouldBe` ["/src", "/test"]

        it "falls back to [\".\"] when there are no cabal files" do
            let actual =
                    runPureEff
                        . evalState mempty
                        . runFileSystemState
                        $ resolveWatchDirs pr [] def ["lib:myapp"]
            actual `shouldBe` ["."]

    describe "when the project is a multi-package cabal.project" do
        it "infers per-package source dirs, scoped to each package's directory" do
            let actual =
                    runPureEff
                        . evalState multiPackageFs
                        . runFileSystemState
                        $ resolveWatchDirs
                            pr
                            ["/pkg-a/pkg-a.cabal", "/pkg-b/pkg-b.cabal"]
                            def
                            ["lib:pkg-a", "test:pkg-a-test", "lib:pkg-b", "test:pkg-b-test"]
            actual
                `shouldBe` ["/pkg-a/src", "/pkg-a/test", "/pkg-b/src", "/pkg-b/test"]
  where
    pr = ProjectRoot "/"


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


-- | An in-memory project root with a @cabal.project@ listing two packages,
-- each in its own subdirectory with a library and a test suite.
multiPackageFs :: Map FilePath ByteString
multiPackageFs =
    Map.fromList
        [ ("/cabal.project", "packages:\n  pkg-a\n  pkg-b\n\ntests: True\n")
        , ("/pkg-a/pkg-a.cabal", libTestCabal "pkg-a")
        , ("/pkg-b/pkg-b.cabal", libTestCabal "pkg-b")
        ]


-- | A minimal cabal file for @name@ with one library and one test suite
-- (@<name>-test@).
libTestCabal :: Text -> ByteString
libTestCabal name =
    encodeUtf8
        $ T.unlines
            [ "cabal-version: 2.0"
            , "name:          " <> name
            , "version:       0.1.0.0"
            , "build-type:    Simple"
            , ""
            , "library"
            , "  hs-source-dirs: src"
            , "  build-depends: base"
            , "  default-language: Haskell2010"
            , ""
            , "test-suite " <> name <> "-test"
            , "  type: exitcode-stdio-1.0"
            , "  main-is: Test.hs"
            , "  hs-source-dirs: test"
            , "  build-depends: base"
            , "  default-language: Haskell2010"
            ]


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
