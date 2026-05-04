module Unit.Tricorder.Session.BuildCommandSpec (spec_BuildCommand) where

import Effectful (runEff)
import Effectful.Reader.Static (runReader)
import Effectful.State.Static.Shared (evalState)
import Test.Hspec (Spec, describe, it, shouldBe)

import Data.Map.Strict qualified as Map

import Atelier.Effects.FileSystem (runFileSystemState)
import Tricorder.Session.BuildCommand (Config (..), resolveCommand)
import Tricorder.Session.ProjectRoot (ProjectRoot (..))
import Tricorder.Session.ReplBuildDir (ReplBuildDir (ReplBuildDir))
import Tricorder.Session.Targets (Targets (..))


spec_BuildCommand :: Spec
spec_BuildCommand = do
    describe "resolveCommand" testResolveCommand


testResolveCommand :: Spec
testResolveCommand = do
    describe "when config has a command" do
        it "should use specified command" do
            actual <-
                runEff
                    . runReader (Targets ["lib:foo"])
                    . runReader (ProjectRoot "/")
                    . runReader (ReplBuildDir "/replbuild")
                    . evalState mempty
                    . runFileSystemState
                    . resolveCommand
                    $ Config
                    $ Just "foo"
            actual `shouldBe` "foo"

    describe "when config does not have a command" do
        describe "and there is a cabal.project file" do
            it "should use cabal with --enable-multi-repl" do
                actual <-
                    runEff
                        . runReader (Targets ["lib:foo"])
                        . runReader (ProjectRoot "/")
                        . runReader (ReplBuildDir "/replbuild")
                        . evalState (Map.singleton "/cabal.project" "")
                        . runFileSystemState
                        . resolveCommand
                        $ Config Nothing
                actual `shouldBe` "cabal repl --enable-multi-repl --builddir /replbuild lib:foo"

        describe "and there is at least one *.cabal file" do
            it "should use cabal with --enable-multi-repl" do
                actual <-
                    runEff
                        . runReader (Targets ["lib:foo"])
                        . runReader (ProjectRoot "/")
                        . runReader (ReplBuildDir "/replbuild")
                        . evalState (Map.singleton "/foo.cabal" "")
                        . runFileSystemState
                        . resolveCommand
                        $ Config Nothing
                actual `shouldBe` "cabal repl --enable-multi-repl --builddir /replbuild lib:foo"
        describe "and there is a stack.yaml file" do
            it "should use stack ghci" do
                actual <-
                    runEff
                        . runReader (Targets ["lib:foo"])
                        . runReader (ProjectRoot "/")
                        . runReader (ReplBuildDir "/replbuild")
                        . evalState (Map.singleton "/stack.yaml" "")
                        . runFileSystemState
                        . resolveCommand
                        $ Config Nothing
                actual `shouldBe` "stack ghci lib:foo"

        describe "but there are no project files" do
            it "should use default cabal repl" do
                actual <-
                    runEff
                        . runReader (Targets ["lib:foo"])
                        . runReader (ProjectRoot "/")
                        . runReader (ReplBuildDir "/replbuild")
                        . evalState mempty
                        . runFileSystemState
                        . resolveCommand
                        $ Config Nothing
                actual `shouldBe` "cabal repl --builddir /replbuild lib:foo"
