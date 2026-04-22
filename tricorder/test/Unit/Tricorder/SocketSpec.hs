module Unit.Tricorder.SocketSpec (spec_Socket) where

import Effectful (IOE, runEff)
import System.IO (hClose, hGetLine, openFile)
import Test.Hspec

import Tricorder.Effects.UnixSocket
    ( SocketScript (..)
    , UnixSocket
    , acceptHandle
    , bindSocket
    , removeSocketFile
    , runUnixSocketScripted
    , socketFileExists
    )


spec_Socket :: Spec
spec_Socket = do
    describe "runUnixSocketScripted" testScripted


--------------------------------------------------------------------------------
-- Scripted interpreter tests
--------------------------------------------------------------------------------

testScripted :: Spec
testScripted = do
    describe "socketFileExists" do
        it "returns True when scripted" do
            result <- runScripted [NextFileCheck True] $ socketFileExists "/"
            result `shouldBe` True

        it "returns False when scripted" do
            result <- runScripted [NextFileCheck False] $ socketFileExists "/"
            result `shouldBe` False

    describe "removeSocketFile" do
        it "is always a no-op" do
            -- No NextFileCheck/NextAccept needed; just returns ()
            runScripted [] $ removeSocketFile "/nonexistent/path"

    describe "acceptHandle" do
        it "returns the scripted handle, readable from a file" do
            let tmpPath = "/tmp/tricorder-socket-accept-test.txt"
            writeFile tmpPath "hello from test\n"
            h <- liftIO $ openFile tmpPath ReadMode
            line <- runScripted [NextAccept h] $ do
                sock <- bindSocket "/"
                h' <- acceptHandle sock
                liftIO $ hGetLine h'
            liftIO $ hClose h
            line `shouldBe` "hello from test"


--------------------------------------------------------------------------------
-- Helpers
--------------------------------------------------------------------------------

-- | Run scripted socket operations (no Delay needed).
runScripted :: [SocketScript] -> Eff '[UnixSocket, IOE] a -> IO a
runScripted script = runEff . runUnixSocketScripted script
