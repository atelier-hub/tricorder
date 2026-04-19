module Unit.Tricorder.FileWatcherSpec (spec_FileWatcher) where

import Effectful (IOE, runEff)
import Effectful.Concurrent (Concurrent, runConcurrent)
import Test.Hspec

import Atelier.Effects.FileWatcher (FileWatcher, dir, runFileWatcherScripted, watchFilePaths)


spec_FileWatcher :: Spec
spec_FileWatcher = do
    describe "runFileWatcherScripted" testScripted


--------------------------------------------------------------------------------
-- Scripted interpreter tests
--------------------------------------------------------------------------------

testScripted :: Spec
testScripted = do
    describe "watchFilePaths" do
        it "calls the callback with the scripted path" do
            result <-
                runScripted ["/src/Foo.hs"]
                    $ watchFilePaths [] pure
            result `shouldBe` "/src/Foo.hs"

        it "calls the callback with each path in order" do
            result <-
                runScripted ["/src/Foo.hs", "/src/Bar.hs"]
                    $ (,) <$> watchFilePaths [] pure <*> watchFilePaths [] pure
            result `shouldBe` ("/src/Foo.hs", "/src/Bar.hs")

        it "ignores the watch specification" do
            result <-
                runScripted ["/src/Foo.hs"]
                    $ watchFilePaths [dir "/any"] pure
            result `shouldBe` "/src/Foo.hs"

        it "passes the full path to the callback unchanged" do
            let path = "/home/user/project/src/Some/Deep/Module.hs"
            result <- runScripted [path] $ watchFilePaths [] pure
            result `shouldBe` path


--------------------------------------------------------------------------------
-- Helpers
--------------------------------------------------------------------------------

runScripted :: [FilePath] -> Eff '[FileWatcher, Concurrent, IOE] a -> IO a
runScripted paths = runEff . runConcurrent . runFileWatcherScripted paths
