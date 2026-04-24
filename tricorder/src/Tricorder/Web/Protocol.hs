module Tricorder.Web.Protocol
    ( StatusQuery (..)
    , DiagnosticQuery (..)
    , ErrorResponse (..)
    ) where

import Data.Aeson (FromJSON, ToJSON)
import Servant (FromHttpApiData, ToHttpApiData)


newtype StatusQuery = StatusQuery {awaitDone :: Bool}
    deriving stock (Eq, Generic, Show)
    deriving newtype (FromJSON, ToJSON)


newtype DiagnosticQuery = DiagnosticQuery {index :: Int}
    deriving stock (Eq, Generic, Show)
    deriving newtype (FromHttpApiData, FromJSON, ToHttpApiData, ToJSON)


newtype ErrorResponse = ErrorResponse {message :: Text}
    deriving stock (Eq, Generic, Show)
    deriving anyclass (ToJSON)
