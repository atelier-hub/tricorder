{-# OPTIONS_GHC -Wno-redundant-constraints #-}

module Atelier.Effects.File
    ( File
    , withFile
    , hGetLine
    , hPutLBs
    , hPutLBsLn
    , hPutBs
    , hPutBsLn
    , hIsEOF
    , hSetBuffering
    , runFile
    ) where

import Effectful (Dispatch (..), DispatchOf, Effect, IOE)
import Effectful.Dispatch.Static
    ( SideEffects (..)
    , StaticRep
    , evalStaticRep
    , unsafeEff_
    , unsafeSeqUnliftIO
    )

import Data.ByteString.Lazy.Char8 qualified as LB8
import System.IO qualified as IO

import Prelude hiding (hIsEOF, hSetBuffering, withFile)


-- | Operations concerning file handles.
data File :: Effect


type instance DispatchOf File = Static WithSideEffects
data instance StaticRep File = File


-- | Lifted `System.IO.withFile`:
withFile :: (File :> es, HasCallStack) => FilePath -> IOMode -> (Handle -> Eff es a) -> Eff es a
withFile fp m f = unsafeSeqUnliftIO \unlift -> IO.withFile fp m (unlift . f)


-- | Lifted `System.IO.hGetLine`.
hGetLine :: (File :> es, HasCallStack) => Handle -> Eff es Text
hGetLine = unsafeEff_ . fmap toText . IO.hGetLine


-- | Lifted `System.IO.hIsEOF`.
hIsEOF :: (File :> es, HasCallStack) => Handle -> Eff es Bool
hIsEOF = unsafeEff_ . IO.hIsEOF


-- | Lifted `Data.ByteString.Lazy.Char8.hPutStr`.
hPutLBs :: (File :> es, HasCallStack) => Handle -> LByteString -> Eff es ()
hPutLBs h s = unsafeEff_ $ LB8.hPutStr h s


-- | Lifted `System.IO.hSetBuffering`.
hSetBuffering :: (File :> es, HasCallStack) => Handle -> BufferMode -> Eff es ()
hSetBuffering h m = unsafeEff_ $ IO.hSetBuffering h m


-- | `hPutLBs` with a `\n` at the end.
hPutLBsLn :: (File :> es, HasCallStack) => Handle -> LByteString -> Eff es ()
hPutLBsLn h = hPutLBs h . (<> "\n")


-- | Like `hPutLBs`, but for strict `ByteString`s.
hPutBs :: (File :> es, HasCallStack) => Handle -> ByteString -> Eff es ()
hPutBs h = hPutLBs h . toLazy


-- | `hPutBs` with a `\n` at the end.
hPutBsLn :: (File :> es, HasCallStack) => Handle -> ByteString -> Eff es ()
hPutBsLn h = hPutLBs h . toLazy . (<> "\n")


-- | Run file operations.
runFile :: (HasCallStack, IOE :> es) => Eff (File : es) a -> Eff es a
runFile = evalStaticRep File
