module Tricorder.Effects.EvalRunner
    ( -- * Effect
      EvalRunner (..)
    , runEvals
    , findEvalCommentsInModules

      -- * Interpreters
    , runEvalRunnerIO
    , runEvalRunnerNoOp
    ) where

import Atelier.Effects.Conc (Conc)
import Atelier.Effects.File (File)
import Atelier.Effects.FileSystem (FileSystem, readFileBs)
import Atelier.Effects.Log (Log)
import Atelier.Effects.Process (Process)
import Atelier.Effects.Timeout (Timeout)
import Data.Default (def)
import Data.Text.Encoding (decodeUtf8Lenient)
import Data.Traversable (for)
import Effectful (Effect)
import Effectful.Concurrent (Concurrent)
import Effectful.Dispatch.Dynamic (interpret_)
import Effectful.Exception (trySync)
import Effectful.Reader.Static (Reader, ask)
import Effectful.TH (makeEffect)

import Atelier.Effects.Log qualified as Log
import Data.Map.Strict qualified as Map
import Data.Text qualified as T

import Tricorder.BuildState (EvalInfo (..), EvalResult (..))
import Tricorder.Effects.GhciSession.GhciParser (LoadedModule (..))
import Tricorder.Effects.GhciSession.GhciProcess (execGhci, withGhciProcess)
import Tricorder.Effects.SessionStore (SessionStore)
import Tricorder.EvalComment (EvalComment (..), findEvalComments)
import Tricorder.Runtime (ProjectRoot (..))
import Tricorder.Session (Command, Session (..))

import Tricorder.Effects.SessionStore qualified as SessionStore


data EvalRunner :: Effect where
    -- | Scan all loaded source files for eval comments and evaluate them, each
    -- in a fresh GHCi session started in that file's module context.
    RunEvals :: [(FilePath, LoadedModule, NonEmpty EvalComment)] -> EvalRunner m [EvalResult]
    FindEvalCommentsInModules
        :: Map FilePath LoadedModule
        -> EvalRunner m [(FilePath, LoadedModule, NonEmpty EvalComment)]


makeEffect ''EvalRunner


-- | Production interpreter: spawns one short-lived @cabal repl@ session per
-- source file that contains at least one eval comment, then runs each
-- @-- $> \<expr\>@ comment in that module's context.
runEvalRunnerIO
    :: ( Conc :> es
       , Concurrent :> es
       , File :> es
       , FileSystem :> es
       , Log :> es
       , Process :> es
       , Reader ProjectRoot :> es
       , SessionStore :> es
       , Timeout :> es
       )
    => Eff (EvalRunner : es) a -> Eff es a
runEvalRunnerIO = interpret_ \case
    RunEvals modulesWithComments -> do
        ProjectRoot projectRoot <- ask
        session <- SessionStore.get
        results <- for modulesWithComments \(absPath, lm, comments) -> do
            Log.info
                $ "EvalRunner: running "
                    <> show (length comments)
                    <> " eval comment(s) in "
                    <> toText lm.relPath
            runFileEvals session.command projectRoot absPath lm.relPath comments
        pure $ concat $ toList <$> results
    FindEvalCommentsInModules loadedModules -> do
        concat <$> for (Map.toList loadedModules) \(absPath, lm) -> do
            fileResult <- trySync $ readFileBs absPath
            pure $ case fileResult of
                Left _ -> []
                Right bs ->
                    case findEvalComments $ decodeUtf8Lenient bs of
                        [] -> []
                        x : xs -> [(absPath, lm, x :| xs)]


-- RunEvals loadedModules -> do
--     ProjectRoot projectRoot <- ask
--     session <- SessionStore.get
--     results <- forM (Map.toList loadedModules) \(absPath, lm) -> do
--         fileResult <- trySync $ readFileBs absPath
--         case fileResult of
--             Left _ -> pure []
--             Right bs -> do
--                 let comments = findEvalComments $ decodeUtf8Lenient bs
--                 if null comments then
--                     pure []
--                 else do
--                     Log.info
--                         $ "EvalRunner: running "
--                             <> show (length comments)
--                             <> " eval comment(s) in "
--                             <> toText lm.relPath
--                     runFileEvals session.command projectRoot absPath lm.relPath comments
--     pure (concat results)

-- | Inert interpreter for testing: always returns an empty result list.
runEvalRunnerNoOp :: Eff (EvalRunner : es) a -> Eff es a
runEvalRunnerNoOp = interpret_ \case
    RunEvals _ -> pure []
    FindEvalCommentsInModules _ -> pure []


-- ---------------------------------------------------------------------------
-- Internal helpers

-- | Spawn a fresh @cabal repl@ session for one source file and run all of its
-- eval comments in that module's context. Returns an 'EvalResult' for each
-- comment; on session startup failure the list is empty.
runFileEvals
    :: ( Conc :> es
       , Concurrent :> es
       , File :> es
       , Log :> es
       , Process :> es
       , Timeout :> es
       )
    => Command
    -> FilePath
    -- ^ Project root (working directory for the GHCi process).
    -> FilePath
    -- ^ Absolute path to the source file (for logging).
    -> FilePath
    -- ^ Relative path to the source file (stored in results).
    -> NonEmpty EvalComment
    -> Eff es (NonEmpty EvalResult)
runFileEvals cmd projectRoot absPath relPath comments = do
    let noProgress = \_ -> pure ()
        wrapForGhci expr
            | T.elem '\n' expr = ":{" <> "\n" <> expr <> "\n" <> ":}"
            | otherwise = expr
    sessionResult <- trySync
        $ withGhciProcess def cmd projectRoot noProgress (\_ -> pure ()) \ghci _ -> do
            _ <- execGhci ghci (":load " <> toText absPath) noProgress
            for comments \ec -> do
                outputResult <- trySync $ execGhci ghci (wrapForGhci ec.expression) noProgress
                pure
                    EvalResult
                        { info =
                            EvalInfo
                                { file = relPath
                                , line = ec.lineNumber
                                , expression = ec.expression
                                }
                        , output = case outputResult of
                            Left ex -> "error: " <> toText (displayException ex)
                            Right ls -> T.unlines ls
                        }
    case sessionResult of
        Left ex -> do
            let errMsg =
                    "EvalRunner: session startup failed for "
                        <> toText absPath
                        <> ": "
                        <> toText (displayException ex)
            Log.warn errMsg
            pure
                $ EvalResult
                    { info =
                        EvalInfo
                            { file = relPath
                            , line = 0
                            , expression = "<no expression>"
                            }
                    , output = errMsg
                    }
                    :| []
        Right results -> pure results
