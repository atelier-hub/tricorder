module Atelier.Effects.FileSystem
    ( FileSystem
    , readFileBs
    , readFileLbs
    , doesFileExist
    , doesPathExist
    , listDirectory
    , createDirectoryIfMissing
    , removeFile
    , canonicalizePath
    , getCurrentDirectory
    , getXdgRuntimeDir
    , runFileSystemIO
    , runFileSystemNoOp
    ) where

import Effectful (Effect, IOE)
import Effectful.Dispatch.Dynamic (interpret_)
import Effectful.TH (makeEffect)
import System.Environment (lookupEnv)

import Data.ByteString qualified as BS
import Data.ByteString.Lazy qualified as LBS
import System.Directory qualified as Dir


data FileSystem :: Effect where
    ReadFileBs :: FilePath -> FileSystem m ByteString
    ReadFileLbs :: FilePath -> FileSystem m LBS.ByteString
    DoesFileExist :: FilePath -> FileSystem m Bool
    DoesPathExist :: FilePath -> FileSystem m Bool
    ListDirectory :: FilePath -> FileSystem m [FilePath]
    CreateDirectoryIfMissing :: Bool -> FilePath -> FileSystem m ()
    RemoveFile :: FilePath -> FileSystem m ()
    CanonicalizePath :: FilePath -> FileSystem m FilePath
    GetCurrentDirectory :: FileSystem m FilePath
    GetXdgRuntimeDir :: FileSystem m FilePath


makeEffect ''FileSystem


runFileSystemIO :: (IOE :> es) => Eff (FileSystem : es) a -> Eff es a
runFileSystemIO = interpret_ $ \case
    ReadFileBs path -> liftIO $ BS.readFile path
    ReadFileLbs path -> liftIO $ LBS.readFile path
    DoesFileExist path -> liftIO $ Dir.doesFileExist path
    DoesPathExist path -> liftIO $ Dir.doesPathExist path
    ListDirectory path -> liftIO $ Dir.listDirectory path
    CreateDirectoryIfMissing p path -> liftIO $ Dir.createDirectoryIfMissing p path
    RemoveFile path -> liftIO $ Dir.removeFile path
    CanonicalizePath path -> liftIO $ Dir.canonicalizePath path
    GetCurrentDirectory -> liftIO Dir.getCurrentDirectory
    GetXdgRuntimeDir -> liftIO $ fromMaybe "/tmp" <$> lookupEnv "XDG_RUNTIME_DIR"


runFileSystemNoOp :: Eff (FileSystem : es) a -> Eff es a
runFileSystemNoOp = interpret_ $ \case
    ReadFileBs _ -> pure mempty
    ReadFileLbs _ -> pure mempty
    DoesFileExist _ -> pure False
    DoesPathExist _ -> pure False
    ListDirectory _ -> pure []
    CreateDirectoryIfMissing _ _ -> pure ()
    RemoveFile _ -> pure ()
    CanonicalizePath path -> pure path
    GetCurrentDirectory -> pure "."
    GetXdgRuntimeDir -> pure "/tmp"
