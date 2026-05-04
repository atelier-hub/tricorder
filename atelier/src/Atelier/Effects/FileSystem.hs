module Atelier.Effects.FileSystem
    ( FileSystem (..)
    , readFileBs
    , readFileLbsFrom
    , readFileLbs
    , followFile
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
    , runFileSystemState
    ) where

import Control.Exception (bracket)
import Effectful (Effect, IOE)
import Effectful.Dispatch.Dynamic (interpret_)
import Effectful.Exception (throwIO)
import Effectful.State.Static.Shared (State, gets, modify)
import Effectful.TH (makeEffect)
import System.Environment (lookupEnv)
import System.IO.Error (userError)
import System.Posix.Types (COff (..), FileOffset)

import Data.ByteString qualified as BS
import Data.ByteString.Lazy qualified as LBS
import Data.Map.Strict qualified as M
import System.Directory qualified as Dir
import System.Posix.IO qualified as Posix

import Atelier.Effects.Delay (Delay)
import Atelier.Effects.Posix.IO (readFdFrom)
import Atelier.Time (Millisecond)

import Atelier.Effects.Delay qualified as Delay


data FileSystem :: Effect where
    ReadFileBs :: FilePath -> FileSystem m ByteString
    ReadFileLbsFrom :: FilePath -> FileOffset -> FileSystem m LBS.ByteString
    DoesFileExist :: FilePath -> FileSystem m Bool
    DoesPathExist :: FilePath -> FileSystem m Bool
    ListDirectory :: FilePath -> FileSystem m [FilePath]
    CreateDirectoryIfMissing :: Bool -> FilePath -> FileSystem m ()
    RemoveFile :: FilePath -> FileSystem m ()
    CanonicalizePath :: FilePath -> FileSystem m FilePath
    GetCurrentDirectory :: FileSystem m FilePath
    GetXdgRuntimeDir :: FileSystem m FilePath


makeEffect ''FileSystem


readFileLbs :: (FileSystem :> es) => FilePath -> Eff es LBS.ByteString
readFileLbs path = readFileLbsFrom path 0


-- | Follow a file as it grows, calling @onChunk@ with each new chunk of
-- content. Polls every 200ms. Does not return.
followFile
    :: (Delay :> es, FileSystem :> es)
    => FilePath
    -> (ByteString -> Eff es ())
    -> Eff es a
followFile path onChunk = go 0
  where
    go offset = do
        newContent <- readFileLbsFrom path offset
        if LBS.null newContent then pure () else onChunk (LBS.toStrict newContent)
        Delay.wait (200 :: Millisecond)
        go (offset + fromIntegral (LBS.length newContent))


runFileSystemIO :: (IOE :> es) => Eff (FileSystem : es) a -> Eff es a
runFileSystemIO = interpret_ $ \case
    ReadFileBs path -> liftIO $ BS.readFile path
    ReadFileLbsFrom path offset ->
        liftIO
            $ bracket
                (Posix.openFd path Posix.ReadOnly Posix.defaultFileFlags)
                Posix.closeFd
                (readFdFrom offset)
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
    ReadFileLbsFrom _ _ -> pure mempty
    DoesFileExist _ -> pure False
    DoesPathExist _ -> pure False
    ListDirectory _ -> pure []
    CreateDirectoryIfMissing _ _ -> pure ()
    RemoveFile _ -> pure ()
    CanonicalizePath path -> pure path
    GetCurrentDirectory -> pure "."
    GetXdgRuntimeDir -> pure "/tmp"


-- | Run `FileSystem` effect backed by a `State` effect with a `Map`. The keys
-- of the `Map` are treated as file names. Only the `dirname` of files are
-- counted as existing directories.
runFileSystemState
    :: (State (Map FilePath ByteString) :> es)
    => Eff (FileSystem : es) a -> Eff es a
runFileSystemState = interpret_ \case
    ReadFileBs fp ->
        maybe (throwIO $ userError "No such file") pure
            =<< gets (M.lookup fp)
    ReadFileLbsFrom fp (COff offset) -> do
        contents <-
            maybe (throwIO $ userError "No such file") pure
                =<< gets (M.lookup fp)
        pure
            . toLazy
            . BS.drop (fromIntegral offset)
            $ contents
    DoesFileExist fp -> gets $ M.member fp
    DoesPathExist fp -> gets $ any (\p -> fp `isPrefixOf` p && fp /= p) . M.keys
    ListDirectory fp -> gets $ filter (\p -> fp `isPrefixOf` p && fp /= p) . M.keys
    CreateDirectoryIfMissing _ _ -> pure ()
    RemoveFile fp -> modify $ M.delete fp
    CanonicalizePath fp -> pure fp
    GetCurrentDirectory -> pure "/"
    GetXdgRuntimeDir -> pure "/tmp"
