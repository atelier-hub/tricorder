module Tricorder.Session.SocketPath
    ( SocketPath (..)
    , asReader
    ) where

import Effectful.Reader.Static (Reader, ask, runReader)
import System.FilePath ((</>))

import Tricorder.Session.RuntimeDir (RuntimeDir (..))


newtype SocketPath = SocketPath {getSocketPath :: FilePath}


asReader
    :: (Reader RuntimeDir :> es)
    => Eff (Reader SocketPath : es) a
    -> Eff es a
asReader act = do
    RuntimeDir runtimeDir <- ask
    let sock = runtimeDir </> "socket.sock"
    runReader (SocketPath sock) act
