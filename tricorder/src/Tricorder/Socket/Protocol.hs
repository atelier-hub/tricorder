module Tricorder.Socket.Protocol
    ( Query (..)
    , StatusQuery (..)
    , DiagnosticQuery (..)
    , ErrorResponse (..)
    ) where

import Data.Aeson (FromJSON, ToJSON)

import Tricorder.GhcPkg.Types (ModuleName)


data StatusQuery = StatusQuery {awaitDone :: Bool}
    deriving stock (Eq, Generic, Show)
    deriving anyclass (FromJSON, ToJSON)


newtype DiagnosticQuery = DiagnosticQuery {index :: Int}
    deriving stock (Eq, Generic, Show)
    deriving anyclass (FromJSON, ToJSON)


data Query
    = Status StatusQuery
    | Watch
    | Source [ModuleName]
    | DiagnosticAt DiagnosticQuery
    | Quit
    deriving stock (Eq, Generic, Show)
    deriving anyclass (FromJSON, ToJSON)


newtype ErrorResponse = ErrorResponse {message :: Text}
    deriving stock (Eq, Generic, Show)
    deriving anyclass (ToJSON)
