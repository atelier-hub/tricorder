module Tricorder.RPC.Protocol
    ( Multiplicity (..)
    , Protocol (..)
    ) where

import Atelier.Effects.RPC (Multiplicity (..))
import Atelier.Effects.RPC.TH (makeProtocol)
import Tricorder.BuildState (BuildState, Diagnostic)
import Tricorder.GhcPkg.Types (ModuleName)
import Tricorder.SourceLookup (ModuleSourceResult)


data Protocol (m :: Multiplicity) a where
    StatusNow :: Protocol Once BuildState
    StatusAwait :: Protocol Once BuildState
    Source :: [ModuleName] -> Protocol Once [ModuleSourceResult]
    DiagnosticAt :: Int -> Protocol Once (Either Text Diagnostic)
    Watch :: Protocol Many BuildState


makeProtocol ''Protocol
