module Tricorder.Socket.Protocol
    ( Multiplicity (..)
    , Request (..)
    , SomeRequest (..)
    , toWire
    , fromWire
    , ErrorResponse (..)
    ) where

import Data.Aeson (FromJSON, ToJSON)

import Tricorder.BuildState (BuildState, Diagnostic)
import Tricorder.GhcPkg.Types (ModuleName)
import Tricorder.SourceLookup (ModuleSourceResult)


data Multiplicity = Once | Many


data Request (m :: Multiplicity) a where
    StatusNow :: Request Once BuildState
    StatusAwait :: Request Once BuildState
    Source :: [ModuleName] -> Request Once [ModuleSourceResult]
    DiagnosticAt :: Int -> Request Once (Either Text Diagnostic)
    Watch :: Request Many BuildState


data SomeRequest
    = forall a. (ToJSON a) => OnceReq (Request Once a)
    | forall a. (ToJSON a) => ManyReq (Request Many a)


-- Wire format — internal serialisation detail, not exported

data StatusQuery = StatusQuery {awaitDone :: Bool}
    deriving stock (Eq, Generic, Show)
    deriving anyclass (FromJSON, ToJSON)


newtype DiagnosticQuery = DiagnosticQuery {index :: Int}
    deriving stock (Eq, Generic, Show)
    deriving anyclass (FromJSON, ToJSON)


data Query
    = Status StatusQuery
    | Watch_
    | Source_ [ModuleName]
    | DiagnosticAt_ DiagnosticQuery
    deriving stock (Eq, Generic, Show)
    deriving anyclass (FromJSON, ToJSON)


toWire :: Request m a -> Query
toWire StatusNow = Status (StatusQuery {awaitDone = False})
toWire StatusAwait = Status (StatusQuery {awaitDone = True})
toWire (Source ms) = Source_ ms
toWire (DiagnosticAt i) = DiagnosticAt_ (DiagnosticQuery {index = i})
toWire Watch = Watch_


fromWire :: Query -> SomeRequest
fromWire (Status (StatusQuery False)) = OnceReq StatusNow
fromWire (Status (StatusQuery True)) = OnceReq StatusAwait
fromWire (Source_ ms) = OnceReq (Source ms)
fromWire (DiagnosticAt_ dq) = OnceReq (DiagnosticAt dq.index)
fromWire Watch_ = ManyReq Watch


newtype ErrorResponse = ErrorResponse {message :: Text}
    deriving stock (Eq, Generic, Show)
    deriving anyclass (ToJSON)
