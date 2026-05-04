module Tricorder.Session.RuntimeDir
    ( RuntimeDir (..)
    , asReader
    ) where

import Effectful.Reader.Static (Reader, ask, runReader)
import Numeric (showHex)
import System.FilePath ((</>))

import Atelier.Effects.FileSystem
    ( FileSystem
    , canonicalizePath
    , createDirectoryIfMissing
    , getXdgRuntimeDir
    )
import Tricorder.Session.ProjectRoot (ProjectRoot (..))


newtype RuntimeDir = RuntimeDir {getRuntimeDir :: FilePath}


asReader
    :: ( FileSystem :> es
       , Reader ProjectRoot :> es
       )
    => Eff (Reader RuntimeDir : es) a -> Eff es a
asReader act = do
    ProjectRoot projectRoot <- ask
    runtimeDir <- getXdgRuntimeDir
    canonProjectRoot <- canonicalizePath projectRoot
    let projectDirHash = hashPath canonProjectRoot
        dir = runtimeDir </> "tricorder" </> projectDirHash
    createDirectoryIfMissing True dir
    runReader (RuntimeDir dir) act


-- | Polynomial hash of a file path, returned as a hex string.
hashPath :: FilePath -> String
hashPath path =
    let n = foldl' (\acc c -> acc * 31 + toInteger (ord c)) (0 :: Integer) path
    in  showHex (abs n `mod` (16 ^ (16 :: Integer))) ""
