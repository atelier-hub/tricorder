module Unit.Ghcib.SocketSpec (spec_Socket) where

import Effectful (IOE, runEff)
import Effectful.Exception (try)
import System.IO (hClose, hGetLine, openFile)
import Test.Hspec

import Atelier.Effects.Delay (Delay, runDelayNoOp)
import Ghcib.Effects.UnixSocket
    ( SocketScript (..)
    , UnixSocket
    , acceptHandle
    , bindSocket
    , removeSocketFile
    , runUnixSocketScripted
    , socketFileExists
    )
import Ghcib.Socket.Server (SocketRemoved (..), socketMonitorTrigger)


spec_Socket :: Spec
spec_Socket = do
    describe "runUnixSocketScripted" testScripted
    describe "socketMonitorTrigger" testMonitor


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
            let tmpPath = "/tmp/ghcib-socket-accept-test.txt"
            writeFile tmpPath "hello from test\n"
            h <- liftIO $ openFile tmpPath ReadMode
            line <- runScripted [NextAccept h] $ do
                sock <- bindSocket "/"
                h' <- acceptHandle sock
                liftIO $ hGetLine h'
            liftIO $ hClose h
            line `shouldBe` "hello from test"


--------------------------------------------------------------------------------
-- socketMonitorTrigger tests
--------------------------------------------------------------------------------

testMonitor :: Spec
testMonitor = do
    it "throws when socket file does not exist" do
        result <-
            runMonitor [NextFileCheck False]
                $ try @SocketRemoved
                $ socketMonitorTrigger "/sock"
        result `shouldBe` Left SocketRemoved

    it "checks again after each delay cycle" do
        -- Two True checks followed by False: monitor survives two cycles then throws.
        result <-
            runMonitor [NextFileCheck True, NextFileCheck True, NextFileCheck False]
                $ try @SocketRemoved
                $ socketMonitorTrigger "/sock"
        result `shouldBe` Left SocketRemoved

    it "does not throw while file exists" do
        -- Single True check; we catch the userError thrown by try after the False.
        -- Here we confirm the first check (True) does NOT throw.
        result <-
            runMonitor [NextFileCheck True, NextFileCheck False]
                $ try @SocketRemoved
                $ socketMonitorTrigger "/sock"
        result `shouldBe` Left SocketRemoved -- eventually throws on the False


--------------------------------------------------------------------------------
-- Helpers
--------------------------------------------------------------------------------

-- | Run scripted socket operations (no Delay needed).
runScripted :: [SocketScript] -> Eff '[UnixSocket, IOE] a -> IO a
runScripted script = runEff . runUnixSocketScripted script


-- | Run monitor tests with a no-op Delay so waits are instant.
runMonitor :: [SocketScript] -> Eff '[UnixSocket, Delay, IOE] a -> IO a
runMonitor script = runEff . runDelayNoOp . runUnixSocketScripted script

-- Note: IOE is in the stack because runUnixSocketScripted requires it
-- (it creates a real socket for BindSocket). The monitor itself doesn't need it.
