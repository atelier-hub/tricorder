module Unit.Tricorder.FileWatcherSpec (spec_FileWatcher) where

import Control.Concurrent (forkIO, killThread, newQSem, signalQSem, waitQSem)
import Data.IORef (modifyIORef, newIORef, readIORef)
import Effectful (IOE, runEff)
import Effectful.Concurrent (Concurrent, runConcurrent)
import Test.Hspec

import Atelier.Effects.FileWatcher (FileWatcher, Watch, dir, runFileWatcherScripted, watchFilePaths)


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
            paths <- collectPaths ["/src/Foo.hs"]
            paths `shouldBe` ["/src/Foo.hs"]

        it "calls the callback with each path in order" do
            paths <- collectPaths ["/src/Foo.hs", "/src/Bar.hs"]
            paths `shouldBe` ["/src/Foo.hs", "/src/Bar.hs"]

        it "ignores the watch specification" do
            paths <- collectPathsWith [dir "/any"] ["/src/Foo.hs"]
            paths `shouldBe` ["/src/Foo.hs"]

        it "passes the full path to the callback unchanged" do
            let path = "/home/user/project/src/Some/Deep/Module.hs"
            paths <- collectPaths [path]
            paths `shouldBe` [path]


--------------------------------------------------------------------------------
-- Helpers
--------------------------------------------------------------------------------

-- | Run the scripted interpreter, collecting all callback-delivered paths.
-- Uses a semaphore to wait for exactly N events before cancelling the watcher.
collectPaths :: [FilePath] -> IO [FilePath]
collectPaths = collectPathsWith []


collectPathsWith :: [Watch] -> [FilePath] -> IO [FilePath]
collectPathsWith watches scripted = do
    ref <- newIORef []
    sem <- newQSem 0
    tid <- forkIO $ void $ runScripted scripted $ watchFilePaths watches \p -> liftIO do
        modifyIORef ref (<> [p])
        signalQSem sem
    replicateM_ (length scripted) (waitQSem sem)
    killThread tid
    readIORef ref


runScripted :: [FilePath] -> Eff '[FileWatcher, Concurrent, IOE] a -> IO a
runScripted paths = runEff . runConcurrent . runFileWatcherScripted paths
