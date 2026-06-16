module Tricorder.Events.FileChanged (FileChanged (..)) where


-- | A relevant source file was modified on disk.
newtype FileChanged = FileChanged {path :: FilePath}
    deriving stock (Eq, Show)
