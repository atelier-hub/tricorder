module Atelier.Types.Semaphore
    ( Semaphore
    , new
    , newSet
    , wait
    , signal
    , unset
    , set
    , peek
    , withSemaphore
    ) where

import Effectful.Concurrent.MVar
    ( Concurrent
    , MVar
    , isEmptyMVar
    , newEmptyMVar
    , newMVar
    , putMVar
    , takeMVar
    , tryPutMVar
    , tryTakeMVar
    )
import Effectful.Exception (bracket)


-- | A flag for threads to either wait to be set, or signal to other processes
-- to continue. A synchronization primitive.
--
-- Using 'wait' on an unset semaphore blocks.
-- Using 'signal' on a set semaphore blocks.
-- All other operations do not block.
--
-- Using 'wait' on a semaphore makes it unset once the wait resolves.
-- Using 'signal' on a semaphore makes it set once the signal resolves.
newtype Semaphore = Semaphore (MVar ())


-- | Creates a new, unset semaphore. Waiting on this semaphore immediately will
-- block.
new :: (Concurrent :> es) => Eff es Semaphore
new = Semaphore <$> newEmptyMVar


-- | Creates a new, set semaphore. Signalling on this semaphore immediately
-- will block.
newSet :: (Concurrent :> es) => Eff es Semaphore
newSet = Semaphore <$> newMVar ()


-- | Wait for a semaphore to be set. Blocks and waits for the semaphore to be
-- set if it is not already set.
wait :: (Concurrent :> es) => Semaphore -> Eff es ()
wait (Semaphore ref) = takeMVar ref


-- | Ensures a semaphore is unset. Returns @True@ if the semaphore was set.
unset :: (Concurrent :> es) => Semaphore -> Eff es Bool
unset (Semaphore ref) = isJust <$> tryTakeMVar ref


-- | Set a semaphore. Blocks and waits if the semaphore is already set.
signal :: (Concurrent :> es) => Semaphore -> Eff es ()
signal (Semaphore ref) = putMVar ref ()


-- | Ensures a semaphore is set. Returns @True@ if the semaphore was not
-- already set.
set :: (Concurrent :> es) => Semaphore -> Eff es Bool
set (Semaphore ref) = tryPutMVar ref ()


-- | Check if a semaphore is set, without changing its state. Returns @True@ if
-- the semaphore is set, @False@ otherwise.
peek :: (Concurrent :> es) => Semaphore -> Eff es Bool
peek (Semaphore ref) = not <$> isEmptyMVar ref


-- | Waits for exclusive access to the semaphore before running a computation,
-- ensuring it is set before starting, and that it is signalled afterwards.
-- If another thread signals or sets the semaphore in the meantime, the caller
-- will _not_ be blocked when attempting to signal the semaphore afterwards.
withSemaphore :: (Concurrent :> es) => Semaphore -> Eff es a -> Eff es a
withSemaphore ref = bracket (wait ref) (const $ set ref) . const
