module Unit.Tricorder.Effects.GhciSession.GhciProcessSpec (spec_GhciProcess) where

import Atelier.Effects.Conc (runConc)
import Atelier.Effects.Delay (runDelay)
import Atelier.Effects.File (runFile)
import Atelier.Effects.Process (runProcessIO)
import Atelier.Effects.Timeout (runTimeout)
import Atelier.Time (Millisecond)
import Control.Concurrent.STM (newTVarIO)
import Control.Exception (catch)
import Data.IORef (newIORef, readIORef, writeIORef)
import Data.Time.Units (Second)
import Effectful (runEff)
import Effectful.Concurrent (runConcurrent)
import Effectful.Exception (trySync)
import System.Process.Typed
    ( createPipe
    , getStderr
    , getStdin
    , getStdout
    , setStderr
    , setStdin
    , setStdout
    , shell
    , startProcess
    , stopProcess
    , waitExitCode
    )
import Test.Hspec

import Atelier.Effects.Conc qualified as Conc
import Atelier.Effects.Delay qualified as Delay
import Atelier.Effects.File qualified as File
import Data.Text qualified as T
import System.Process qualified as Process

import Tricorder.Effects.GhciSession.GhciProcess
    ( GhciProcess (..)
    , GhciProcessError (..)
    , InterruptDecision (..)
    , SessionState (..)
    , decideInterrupt
    , execGhci
    , waitForBannerOrFail
    )


spec_GhciProcess :: Spec
spec_GhciProcess = do
    describe "decideInterrupt" testDecideInterrupt
    describe "execGhci" testExecGhciScope
    describe "execGhci (stale marker desync)" testExecGhciStaleMarker
    describe "execGhci (sync marker scope independence)" testSyncMarkerScopeIndependent
    describe "waitForBannerOrFail" testWaitForBannerOrFail


-- | Regression for the touch-during-reload desync. Interrupting a *Busy* GHCi
-- (a reload in flight) leaves a stale sync marker in the stdout/stderr buffers
-- ahead of the next command's real output. Because 'drainUntil' used to stop on
-- ANY marker-prefix line, the next 'execGhci' matched that stale marker and
-- returned *before its command ran* — surfacing as @All good. (0 modules)@ (or,
-- on the other timing, a hang). 'execGhci' must skip markers that aren't its
-- own and stop only on the marker it is waiting for.
testExecGhciStaleMarker :: Spec
testExecGhciStaleMarker =
    it "skips a stale leftover marker and returns the command's real output" do
        (stdinR, stdinW) <- Process.createPipe
        (stdoutR, stdoutW) <- Process.createPipe
        (stderrR, stderrW) <- Process.createPipe
        -- A dummy process handle to fill the record; 'execGhci' never uses it.
        p <-
            startProcess
                $ setStdin createPipe
                $ setStdout createPipe
                $ setStderr createPipe
                $ shell "true"
        _ <- waitExitCode p
        stateVar <- newTVarIO (Idle 9)
        let gp =
                GhciProcess
                    { stdin = stdinW
                    , stdout = stdoutR
                    , stderr = stderrR
                    , handle = p
                    , stateVar
                    }
            -- Mirrors 'markerFor': "#~TRI-FINISH-<n>~#".
            marker n = "#~TRI-FINISH-" <> show (n :: Int) <> "~#" :: Text
        result <-
            runEff
                . runConcurrent
                . runTimeout
                . runDelay
                . runFile
                . runConc
                $ do
                    -- A stale 'marker 5' (left by a prior interrupted reload)
                    -- precedes the fresh command's real output + its 'marker 9'
                    -- (state is 'Idle 9', so 'execGhci' waits for marker 9).
                    for_ [marker 5, "out-line", marker 9] (File.hPutTextLn stdoutW)
                    for_ [marker 5, "err-line", marker 9] (File.hPutTextLn stderrW)
                    File.hClose stdoutW
                    File.hClose stderrW
                    -- Keep the stdin read-end alive across the write inside
                    -- 'execGhci' (otherwise it is GC-finalised → broken pipe).
                    r <- execGhci gp "reload" (\_ -> pure ())
                    File.hClose stdinR
                    pure r
        _ <- (Right <$> stopProcess p) `catch` \(_ :: SomeException) -> pure (Left ())
        result `shouldBe` ["out-line", "err-line"]


-- | Root-cause regression for the "stuck Building…" stall. A SIGINT-interrupted
-- ':reload' empties GHCi's interactive scope — it drops the implicit
-- @import Prelude@ (verified against ghci 9.10). A sync marker built from bare
-- Prelude names then fails to run instead of printing: @putStrLn@ is no longer
-- in scope, and neither is the @>>@ operator. The marker never appears, so
-- 'drainUntil' blocks until the watchdog fires. The marker must therefore use
-- only fully-qualified 'System.IO.hPutStrLn' statements (which survive the
-- emptied scope), one per stream, with no bare names or operators.
--
-- We assert on exactly what 'execGhci' writes to GHCi's stdin.
testSyncMarkerScopeIndependent :: Spec
testSyncMarkerScopeIndependent =
    it "writes the finish marker using only fully-qualified names (no bare putStrLn / >>)" do
        (stdinR, stdinW) <- Process.createPipe
        (stdoutR, stdoutW) <- Process.createPipe
        (stderrR, stderrW) <- Process.createPipe
        p <-
            startProcess
                $ setStdin createPipe
                $ setStdout createPipe
                $ setStderr createPipe
                $ shell "true"
        _ <- waitExitCode p
        stateVar <- newTVarIO (Idle 9)
        let gp =
                GhciProcess
                    { stdin = stdinW
                    , stdout = stdoutR
                    , stderr = stderrR
                    , handle = p
                    , stateVar
                    }
            marker = "#~TRI-FINISH-9~#" :: Text
        written <-
            runEff
                . runConcurrent
                . runTimeout
                . runDelay
                . runFile
                . runConc
                $ do
                    -- Pre-seed the marker on both streams so the drain returns
                    -- immediately; we only care about what was written to stdin.
                    File.hPutTextLn stdoutW marker
                    File.hPutTextLn stderrW marker
                    File.hClose stdoutW
                    File.hClose stderrW
                    _ <- execGhci gp ":reload" (\_ -> pure ())
                    File.hClose stdinW
                    let readAll acc =
                            trySync (File.hGetLine stdinR) >>= \case
                                Left (_ :: SomeException) -> pure (reverse acc)
                                Right l -> readAll (l : acc)
                    readAll []
        _ <- (Right <$> stopProcess p) `catch` \(_ :: SomeException) -> pure (Left ())
        let blob = T.intercalate "\n" written
        (" >> " `T.isInfixOf` blob) `shouldBe` False
        ("System.IO.hPutStrLn System.IO.stdout" `T.isInfixOf` blob) `shouldBe` True
        ("System.IO.hPutStrLn System.IO.stderr" `T.isInfixOf` blob) `shouldBe` True


-- | Regression: when the build command exits before printing a GHCi banner,
-- 'waitForBannerOrFail' must surface the *complete* stderr output in the
-- 'StartupFailed' error. The original implementation snapshotted the captured
-- lines as soon as the process exited (it waited on 'waitExitCode'), racing
-- the concurrent stderr drain — so a burst of error lines still buffered in
-- the pipe was truncated, and the real cabal/build failure was lost.
testWaitForBannerOrFail :: Spec
testWaitForBannerOrFail =
    it "captures the full stderr output when the command exits before the banner" do
        let lineCount = 200 :: Int
            lastLine = "err line " <> show lineCount
        -- 'true' exits immediately. We only need it for the 'Process' handle
        -- that 'waitForBannerOrFail' stops on the failure path; the banner and
        -- error streams are pipes we drive ourselves, so the timing is
        -- deterministic rather than a race against the OS pipe buffer.
        p <-
            startProcess
                $ setStdin createPipe
                $ setStdout createPipe
                $ setStderr createPipe
                $ shell "true"
        _ <- waitExitCode p
        (bannerOut, bannerOutW) <- Process.createPipe
        (errR, errW) <- Process.createPipe
        result <-
            runEff
                . runConcurrent
                . runTimeout
                . runDelay
                . runFile
                . runConc
                . runProcessIO
                $ do
                    -- No banner will ever arrive: close the write end so the
                    -- wait sees EOF at once and takes the "command exited"
                    -- failure branch.
                    File.hClose bannerOutW
                    -- Producer: pause long enough that a snapshot-at-exit reads
                    -- an empty buffer, THEN stream the whole error log and
                    -- close so the drain sees EOF. A correct implementation
                    -- awaits that drain before reading the captured lines.
                    _ <- Conc.fork do
                        Delay.wait (30 :: Millisecond)
                        for_ [1 .. lineCount] \i ->
                            File.hPutTextLn errW ("err line " <> show i :: Text)
                        File.hClose errW
                    trySync (waitForBannerOrFail (5 :: Second) bannerOut errR p)
        _ <- (Right <$> stopProcess p) `catch` \(_ :: SomeException) -> pure (Left ())
        case result of
            Right () -> expectationFailure "expected waitForBannerOrFail to throw a startup error"
            Left ex -> case fromException ex of
                Just (StartupFailed msg) ->
                    (lastLine `T.isInfixOf` msg) `shouldBe` True
                other ->
                    expectationFailure ("expected StartupFailed, got: " <> show other)


testDecideInterrupt :: Spec
testDecideInterrupt = do
    -- Regression: an idle GHCi must not be SIGINT'd, since the matching
    -- sync-marker write would leave a stale marker line in stdout/stderr
    -- that the next 'execGhci' drain would match instead of the fresh one,
    -- desyncing the protocol and reporting "0 modules" or hanging.
    it "is a no-op when the session is Idle" do
        decideInterrupt (Idle 7) `shouldBe` (Idle 7, NoOpIdle)

    it "preserves the counter for any Idle state" do
        decideInterrupt (Idle 0) `shouldBe` (Idle 0, NoOpIdle)
        decideInterrupt (Idle 42) `shouldBe` (Idle 42, NoOpIdle)

    it "advances to Idle (n+1) and emits SendInterruptFor n when Busy" do
        decideInterrupt (Busy 7) `shouldBe` (Idle 8, SendInterruptFor 7)

    it "advances correctly from Busy 0" do
        decideInterrupt (Busy 0) `shouldBe` (Idle 1, SendInterruptFor 0)


-- | Pins down the 'Conc.scoped' fix in 'execGhci': when the drain forks
-- raise 'UnexpectedExit' (because the underlying process exited and EOF'd
-- the pipes), the exception must be CONTAINED inside 'execGhci' and
-- surfaced via the caller's 'trySync' — not propagated to the ambient
-- 'Conc.scoped' that called 'execGhci'.
--
-- Without the inner 'Conc.scoped' in 'execGhci', Ki propagates an
-- exception from a forked thread to its owning scope. If 'execGhci' forks
-- its drains directly into the ambient scope (the original bug), the
-- ambient scope is torn down — siblings die, the whole builder cycle
-- unwinds, and the daemon ends up in the "Restarting builder..." state
-- the user observed.
testExecGhciScope :: Spec
testExecGhciScope =
    -- Spawn a real subprocess that exits immediately ('true'). Its
    -- stdout/stderr pipes EOF as soon as the child exits, which makes
    -- 'drainUntil' inside 'execGhci' throw 'UnexpectedExit' — exactly the
    -- mid-command termination path the fix exists to handle.
    it "contains drain exceptions inside its own scope so siblings survive" do
        p <-
            startProcess
                $ setStdin createPipe
                $ setStdout createPipe
                $ setStderr createPipe
                $ shell "true"
        -- Wait for the child to actually exit so the pipes are EOF before
        -- 'execGhci' starts draining (otherwise the drain blocks).
        _ <- waitExitCode p
        stateVar <- newTVarIO (Idle 0)
        let gp =
                GhciProcess
                    { stdin = getStdin p
                    , stdout = getStdout p
                    , stderr = getStderr p
                    , handle = p
                    , stateVar
                    }
        siblingDoneRef <- newIORef False
        result <-
            runEff
                . runConcurrent
                . runTimeout
                . runDelay
                . runFile
                . runConc
                $ Conc.scoped do
                    -- A sibling fork in the SAME ambient scope. If the bug
                    -- regresses, the drain exception will tear this scope
                    -- down and the sibling will be cancelled before it can
                    -- flip the ref.
                    sibling <- Conc.fork do
                        Delay.wait (50 :: Millisecond)
                        liftIO (writeIORef siblingDoneRef True)
                    -- Drive 'execGhci' on a dead process; the drains should
                    -- raise 'UnexpectedExit', which 'trySync' must catch
                    -- here rather than letting Ki tear down the scope.
                    execResult <- trySync (execGhci gp "cmd" (\_ -> pure ()))
                    -- Wait for the sibling to run.
                    Conc.await sibling
                    pure execResult
        -- stopProcess flushes the buffered command+marker to a pipe whose
        -- read end is already closed, which raises ResourceVanished. The
        -- subprocess has long since exited; just swallow the cleanup error.
        _ <- (Right <$> stopProcess p) `catch` \(_ :: SomeException) -> pure (Left ())
        siblingDone <- readIORef siblingDoneRef
        siblingDone `shouldBe` True
        case result of
            Left _ -> pure ()
            Right _ -> expectationFailure "expected execGhci to raise UnexpectedExit"
