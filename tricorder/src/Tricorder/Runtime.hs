module Tricorder.Runtime
    ( PidFile (..)
    , runPidFile
    , ProjectRoot (..)
    , runProjectRoot
    , RuntimeDir (..)
    , runRuntimeDir
    , SocketPath (..)
    , runSocketPath
    , runSocketPathConst
    ) where

import Effectful.Reader.Static (Reader, ask, runReader)
import Numeric (showHex)
import System.FilePath ((</>))

import Atelier.Effects.FileSystem
    ( FileSystem
    , canonicalizePath
    , createDirectoryIfMissing
    , getCurrentDirectory
    , getXdgRuntimeDir
    )
import Atelier.Effects.Posix.Daemons (PidFile (..))


newtype SocketPath = SocketPath {getSocketPath :: FilePath}


runSocketPath
    :: (Reader RuntimeDir :> es)
    => Eff (Reader SocketPath : es) a
    -> Eff es a
runSocketPath act = do
    RuntimeDir runtimeDir <- ask
    let sock = runtimeDir </> "socket.sock"
    runReader (SocketPath sock) act


runSocketPathConst :: FilePath -> Eff (Reader SocketPath : es) a -> Eff es a
runSocketPathConst = runReader . SocketPath


newtype RuntimeDir = RuntimeDir {getRuntimeDir :: FilePath}


runRuntimeDir
    :: ( FileSystem :> es
       , Reader ProjectRoot :> es
       )
    => Eff (Reader RuntimeDir : es) a -> Eff es a
runRuntimeDir act = do
    ProjectRoot projectRoot <- ask
    runtimeDir <- getXdgRuntimeDir
    canonProjectRoot <- canonicalizePath projectRoot
    let projectDirHash = hashPath canonProjectRoot
        dir = runtimeDir </> "tricorder" </> projectDirHash
    createDirectoryIfMissing True dir
    runReader (RuntimeDir dir) act


newtype ProjectRoot = ProjectRoot {getProjectRoot :: FilePath}


runProjectRoot
    :: (FileSystem :> es, HasCallStack)
    => Eff (Reader ProjectRoot : es) a -> Eff es a
runProjectRoot act = do
    projectRoot <- getCurrentDirectory
    runReader (ProjectRoot projectRoot) act


runPidFile :: (Reader RuntimeDir :> es) => Eff (Reader PidFile : es) a -> Eff es a
runPidFile act = do
    RuntimeDir runtimeDir <- ask
    runReader (PidFile $ runtimeDir </> "daemon.pid") act


-- | Polynomial hash of a file path, returned as a hex string.
hashPath :: FilePath -> String
hashPath path =
    let n = foldl' (\acc c -> acc * 31 + toInteger (ord c)) (0 :: Integer) path
    in  showHex (abs n `mod` (16 ^ (16 :: Integer))) ""
