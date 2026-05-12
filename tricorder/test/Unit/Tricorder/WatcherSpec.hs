module Unit.Tricorder.WatcherSpec (spec_Watcher) where

import Effectful (runEff)
import Effectful.Concurrent (runConcurrent)
import Effectful.Dispatch.Dynamic (reinterpret_)
import Effectful.Reader.Static (runReader)
import Effectful.State.Static.Shared (execState, put)
import Effectful.Writer.Static.Shared (runWriter)
import Test.Hspec (Spec, describe, it, shouldBe, shouldMatchList)

import Atelier.Effects.Delay (runDelay)
import Atelier.Effects.Publishing (runPubWriter)
import Tricorder.BuildState
    ( CabalChangeDetected (..)
    , ChangeKind (..)
    , DaemonInfo (..)
    , SourceChangeDetected (..)
    )
import Tricorder.Effects.BuildStore (BuildStore (..))
import Tricorder.Watcher (WatchedFile (..), markWatchedFiles)


spec_Watcher :: Spec
spec_Watcher = do
    describe "markWatchedFiles" testMarkWatchedFiles


testMarkWatchedFiles :: Spec
testMarkWatchedFiles = do
    it "should mark build store as dirty" do
        ((state, _), _) <- runTest "foo"
        state `shouldBe` Just SourceChange

    describe "with non-cabal file change" $ it "should publish SourceChangeDetected" do
        (_, sourceChanges) <- runTest "foo"
        sourceChanges `shouldMatchList` [SourceChangeDetected]

    describe "with cabal file change" $ it "should publish CabalChangeDetected" do
        ((_, cabalChanges), _) <- runTest "foo.cabal"
        cabalChanges `shouldMatchList` [CabalChangeDetected]
  where
    runTest =
        runEff
            . runConcurrent
            . runDelay
            . runReader emptyDaemonInfo
            . runWriter
            . runPubWriter @SourceChangeDetected
            . runWriter
            . runPubWriter @CabalChangeDetected
            . mockBuildStore
            . markWatchedFiles
            . WatchedFile
    mockBuildStore :: Eff (BuildStore : es) a -> Eff es (Maybe ChangeKind)
    mockBuildStore = reinterpret_ (execState Nothing) \case
        MarkDirty ck -> put $ Just ck
        _ -> error "Not implemented"


emptyDaemonInfo :: DaemonInfo
emptyDaemonInfo =
    DaemonInfo
        { targets = []
        , watchDirs = []
        , sockPath = ""
        , logFile = ""
        , metricsPort = Nothing
        }
