module Tricorder.RPC.Protocol
    ( Multiplicity (..)
    , Protocol (..)
    , SomeProtocol (..)
    , dispatch
    ) where

import Data.Aeson (decode, object, (.=))

import Data.ByteString.Lazy qualified as BSL

import Atelier.Effects.RPC (Handler, Multiplicity (..), encodeText, serveMany, serveOnce)
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


makeProtocol ''Protocol ''Multiplicity


-- | Decode one wire-format request line and route it to the appropriate
-- 'Handler' operation, sending each response back through @send@.
-- On parse failure, sends a JSON object @{"message":"invalid request"}@.
dispatch
    :: (Handler Protocol :> es)
    => (Text -> Eff es ())
    -> Text
    -> Eff es ()
dispatch send line =
    case decode @SomeProtocol (BSL.fromStrict (encodeUtf8 line)) of
        Nothing -> send (encodeText invalidRequest)
        Just (OnceProtocol req) -> serveOnce req >>= send . encodeText
        Just (ManyProtocol req) -> serveMany req (send . encodeText)
  where
    invalidRequest = object ["message" .= ("invalid request" :: Text)]
