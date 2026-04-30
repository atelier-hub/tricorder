module Atelier.Effects.RPC.Unix
    ( runClientUnix
    , serveUnix
    ) where

import Data.Aeson (FromJSON, ToJSON, decode, eitherDecode, encode)
import Effectful.Dispatch.Dynamic (interpretWith, localSeqUnlift)
import Effectful.Exception (IOException, finally)

import Data.ByteString.Lazy qualified as BSL

import Atelier.Effects.Conc (Conc)
import Atelier.Effects.RPC (Client (..))
import Atelier.Effects.UnixSocket
    ( UnixSocket
    , acceptHandle
    , bindSocket
    , closeHandle
    , readLine
    , sendLine
    , withConnection
    )

import Atelier.Effects.Conc qualified as Conc


runClientUnix
    :: (UnixSocket :> es)
    => FilePath
    -> Eff (Client req : es) a
    -> Eff es a
runClientUnix sockPath eff = interpretWith eff \env -> \case
    RunRequest req ->
        withConnection sockPath \h -> do
            sendLine h (encodeJSON req)
            line <- readLine h
            pure $ decodeAs $ BSL.fromStrict $ encodeUtf8 line
    RunStream req callback ->
        localSeqUnlift env \unlift ->
            withConnection sockPath \h -> do
                sendLine h (encodeJSON req)
                let loop = do
                        line <- readLine h
                        let raw = BSL.fromStrict $ encodeUtf8 line
                        case decode raw of
                            Nothing -> pure ()
                            Just v -> unlift (callback v) >> loop
                loop


-- | Accept-loop server on a Unix socket.
--
-- Binds to the given path, then loops forever: accepts each incoming
-- connection, forks it with 'Conc.forkTry', reads one line, calls
-- the dispatch callback with @sendLine@ and the line, then closes the handle.
serveUnix
    :: (Conc :> es, UnixSocket :> es)
    => ((Text -> Eff es ()) -> Text -> Eff es ())
    -- ^ dispatch: given @sendLine@ and the received line, produce a response
    -> FilePath
    -> Eff es Void
serveUnix dispatch sockPath = do
    sock <- bindSocket sockPath
    forever do
        h <- acceptHandle sock
        void
            $ Conc.forkTry @IOException
            $ ( do
                    line <- readLine h
                    dispatch (sendLine h) line
              )
                `finally` closeHandle h


encodeJSON :: (ToJSON a) => a -> Text
encodeJSON = decodeUtf8 . BSL.toStrict . encode


decodeAs :: (FromJSON a) => BSL.ByteString -> Either Text a
decodeAs = first toText . eitherDecode
