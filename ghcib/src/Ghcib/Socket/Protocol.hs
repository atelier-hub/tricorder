module Ghcib.Socket.Protocol
    ( Query (..)
    , StatusQuery (..)
    , ErrorResponse (..)
    ) where

import Data.Aeson (FromJSON, ToJSON)

import Ghcib.GhcPkg.Types (ModuleName)


data StatusQuery = StatusQuery {awaitDone :: Bool}
    deriving stock (Eq, Generic, Show)
    deriving anyclass (FromJSON, ToJSON)


data Query
    = Status StatusQuery
    | Watch
    | Source [ModuleName]
    deriving stock (Eq, Generic, Show)
    deriving anyclass (FromJSON, ToJSON)


newtype ErrorResponse = ErrorResponse {message :: Text}
    deriving stock (Eq, Generic, Show)
    deriving anyclass (ToJSON)
