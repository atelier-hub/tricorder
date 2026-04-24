module Tricorder.Web.API
    ( API
    , Routes (..)
    , DiagnosticResponse (..)
    )
where

import Data.Aeson (FromJSON, ToJSON)
import GHC.Generics (Generically (..))
import Servant
    ( Get
    , JSON
    , NamedRoutes
    , NewlineFraming
    , PostNoContent
    , QueryFlag
    , QueryParam
    , QueryParams
    , SourceIO
    , StreamGet
    , (:-)
    , (:>)
    )

import Tricorder.BuildState (BuildState, Diagnostic)
import Tricorder.SourceLookup (ModuleName, ModuleSourceResult)
import Tricorder.Web.Config (BasePath)
import Tricorder.Web.Protocol (DiagnosticQuery)
import Prelude hiding ((:>))


-- | Named routes for the API
data Routes mode = Routes
    { ping
        :: mode
            :- BasePath
                :> "ping"
                :> Get '[JSON] Bool
    , status
        :: mode
            :- BasePath
                :> "status"
                :> QueryFlag "await_done"
                :> Get '[JSON] BuildState
    , watch
        :: mode
            :- BasePath
                :> "watch"
                :> StreamGet NewlineFraming JSON (SourceIO BuildState)
    , source
        :: mode
            :- BasePath
                :> "source"
                :> QueryParams "module_names" ModuleName
                :> Get '[JSON] [ModuleSourceResult]
    , diagnostic
        :: mode
            :- BasePath
                :> "diagnostic"
                :> QueryParam "at" DiagnosticQuery
                :> Get '[JSON] DiagnosticResponse
    , quit
        :: mode
            :- BasePath
                :> PostNoContent
    }
    deriving stock (Generic)


data DiagnosticResponse
    = ErrorResponse Text
    | DiagnosticResponse Diagnostic
    deriving stock (Generic)
    deriving (FromJSON, ToJSON) via (Generically DiagnosticResponse)


-- | API using named routes
type API = NamedRoutes Routes
