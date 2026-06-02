module Unit.Tricorder.Effects.GhciSession.GhciProcessSpec (spec_GhciProcess) where

import Control.Concurrent.STM (newTVarIO)
import Control.Exception (catch)
import Data.IORef (newIORef, readIORef, writeIORef)
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

import Atelier.Effects.Conc (runConc)
import Atelier.Effects.Delay (runDelay)
import Atelier.Effects.File (runFile)
import Atelier.Effects.Timeout (runTimeout)
import Atelier.Time (Millisecond)
import Tricorder.Effects.GhciSession.GhciProcess
    ( GhciProcess (..)
    , InterruptDecision (..)
    , SessionState (..)
    , decideInterrupt
    , execGhci
    )

import Atelier.Effects.Conc qualified as Conc
import Atelier.Effects.Delay qualified as Delay


spec_GhciProcess :: Spec
spec_GhciProcess = do
    describe "decideInterrupt" testDecideInterrupt
    describe "execGhci" testExecGhciScope


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
