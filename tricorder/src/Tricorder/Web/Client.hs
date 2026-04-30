module Tricorder.Web.Client
    ( Client
    , queryStatus
    , queryStatusWait
    , watchStatus
    , querySource
    , queryDiagnostic
    , isLive
    , shutDown
    , run
    , isDaemonRunning
    ) where

import Effectful (Effect, IOE, withSeqEffToIO)
import Effectful.Dispatch.Dynamic (interpretWith, localSeqUnliftIO)
import Effectful.Error.Static (runErrorNoCallStack, throwError)
import Effectful.Reader.Static (Reader, ask)
import Effectful.TH (makeEffect)
import Network.HTTP.Client (Manager, defaultManagerSettings, newManager)
import Servant.Client
    ( AsClientT
    , BaseUrl (..)
    , ClientEnv
    , Scheme (..)
    , (//)
    , (/:)
    )
import Servant.Client.Generic (genericClient)
import Servant.Client.Streaming (ClientM, mkClientEnv, withClientM)

import Servant.Types.SourceT qualified as SourceT

import Atelier.Effects.Posix.Daemons (Daemons)
import Tricorder.BuildState (BuildState, Diagnostic)
import Tricorder.GhcPkg.Types (ModuleName)
import Tricorder.Runtime (PidFile)
import Tricorder.SourceLookup (ModuleSourceResult)
import Tricorder.Web.API (DiagnosticResponse (..), Routes (..))
import Tricorder.Web.Config (Config (..))
import Tricorder.Web.Protocol (DiagnosticQuery (..))

import Atelier.Effects.Posix.Daemons qualified as Daemons


data Client :: Effect where
    -- | Query the current build status (non-blocking).
    QueryStatus :: Client m (Either Text BuildState)
    -- | Query the build status, blocking until the current build cycle completes.
    QueryStatusWait :: Client m (Either Text BuildState)
    -- | Connect and stream build updates, calling the handler after each completed build.
    WatchStatus :: (BuildState -> m ()) -> Client m (Either Text ())
    -- | Look up the source for one or more modules via the daemon.
    QuerySource :: [ModuleName] -> Client m (Either Text [ModuleSourceResult])
    -- | Fetch the full body of a single diagnostic by 1-based index.
    QueryDiagnostic :: Int -> Client m (Either Text Diagnostic)
    -- | Check if daemon API is ready for requests.
    IsLive :: Client m (Either Text Bool)
    -- | Request the daemon to perform its necessary cleanup and shut down.
    ShutDown :: Client m (Either Text ())


makeEffect ''Client


run
    :: forall es a
     . ( IOE :> es
       , Reader Config :> es
       )
    => Eff (Client : es) a -> Eff es a
run act = do
    cfg <- ask
    m <- liftIO $ newManager defaultManagerSettings
    let
        clientEnv = mkEnv cfg.host cfg.port m
        withClient :: forall b c. ClientM b -> (Either Text b -> Eff es c) -> Eff es c
        withClient clientM handle = withSeqEffToIO \effToIO ->
            withClientM clientM clientEnv (effToIO . handle . first show)
    interpretWith act \env -> \case
        QueryStatus -> withClient (client // status /: False) pure
        QueryStatusWait -> withClient (client // status /: True) pure
        WatchStatus handler -> do
            withClient (client // watch) \res ->
                case res of
                    Left err -> pure $ Left err
                    Right sourceT -> runErrorNoCallStack
                        $ withSeqEffToIO \parentEffToIO ->
                            parentEffToIO $ localSeqUnliftIO env \localEffToIO ->
                                SourceT.foreach
                                    (parentEffToIO . throwError . toText)
                                    (localEffToIO . handler)
                                    sourceT
        QuerySource ms -> withClient (client // source /: ms) pure
        QueryDiagnostic idx -> do
            withClient (client // diagnostic /: Just (DiagnosticQuery idx)) \res ->
                case res of
                    Left e -> pure $ Left e
                    Right (ErrorResponse e) -> pure $ Left e
                    Right (DiagnosticResponse a) -> pure $ Right a
        IsLive -> withClient (client // ping) pure
        ShutDown -> fmap void $ withClient (client // quit) pure


isDaemonRunning :: (Client :> es, Daemons :> es, Reader PidFile :> es) => Eff es Bool
isDaemonRunning = do
    pidFile <- ask
    running <- Daemons.isRunning pidFile
    live <- isLive
    pure $ running && live == Right True


client :: Routes (AsClientT ClientM)
client = genericClient


mkEnv :: String -> Int -> Manager -> ClientEnv
mkEnv host port manager = mkClientEnv manager $ BaseUrl Http host port ""
