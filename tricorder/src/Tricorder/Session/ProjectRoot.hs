module Tricorder.Session.ProjectRoot
    ( ProjectRoot (..)
    , asReader
    ) where

import Effectful.Reader.Static (Reader, runReader)

import Atelier.Effects.FileSystem (FileSystem, getCurrentDirectory)


newtype ProjectRoot = ProjectRoot {getProjectRoot :: FilePath}


asReader
    :: (FileSystem :> es, HasCallStack)
    => Eff (Reader ProjectRoot : es) a -> Eff es a
asReader act = do
    projectRoot <- getCurrentDirectory
    runReader (ProjectRoot projectRoot) act
