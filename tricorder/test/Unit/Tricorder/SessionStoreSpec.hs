module Unit.Tricorder.SessionStoreSpec (spec_SessionStore) where

import Data.Default (def)
import Effectful (runPureEff)
import Effectful.Reader.Static (runReader)
import Effectful.State.Static.Shared (evalState, runState)
import Effectful.Writer.Static.Shared (runWriter)
import Test.Hspec

import Data.Aeson qualified as Aeson

import Atelier.Config (LoadedConfig (..))
import Atelier.Effects.FileSystem (runFileSystemState)
import Atelier.Effects.Publishing (runPubWriter)
import Tricorder.Runtime (ProjectRoot (..))
import Tricorder.Session (Session)
import Tricorder.SessionStore (ReloadRequested (..), Reloaded (..), reloadSession)


spec_SessionStore :: Spec
spec_SessionStore = describe "reloadSession" do
    it "publishes the updated session" do
        let (((), newSession), events) =
                runPureEff
                    . runWriter @[Reloaded]
                    . runPubWriter @Reloaded
                    . runState (def :: Session)
                    . evalState mempty
                    . runFileSystemState
                    . runReader (ProjectRoot "/")
                    . runReader (LoadedConfig (Aeson.Object mempty))
                    $ reloadSession ReloadRequested
        events `shouldBe` [Reloaded newSession]
