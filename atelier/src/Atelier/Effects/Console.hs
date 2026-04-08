module Atelier.Effects.Console
    ( -- * Effect
      Console
    , putStrLn
    , putStr
    , putTextLn
    , putText

      -- * Interpreters
    , runConsoleHandle
    , runConsole
    , runConsoleToList
    ) where

import Effectful (Effect, IOE)
import Effectful.Dispatch.Dynamic (interpret_, reinterpret_)
import Effectful.State.Static.Shared (modify, runState)
import Effectful.TH (makeEffect)

import Data.ByteString.Char8 qualified as B8

import Prelude hiding (putStr, putStrLn, putText, putTextLn)


data Console :: Effect where
    PutStr :: ByteString -> Console m ()


makeEffect ''Console


putStrLn :: (Console :> es) => ByteString -> Eff es ()
putStrLn = putStr . (<> "\n")


putText :: (Console :> es) => Text -> Eff es ()
putText = putStr . encodeUtf8


putTextLn :: (Console :> es) => Text -> Eff es ()
putTextLn = putStrLn . encodeUtf8


runConsoleHandle :: (IOE :> es) => Handle -> Eff (Console : es) a -> Eff es a
runConsoleHandle h = interpret_ \case
    PutStr s -> liftIO $ B8.hPut h s


runConsole :: (IOE :> es) => Eff (Console : es) a -> Eff es a
runConsole = runConsoleHandle stdout


runConsoleToList :: Eff (Console : es) a -> Eff es (a, [ByteString])
runConsoleToList = reinterpret_ (fmap (second reverse) . runState []) \case
    PutStr s -> modify (s :)
