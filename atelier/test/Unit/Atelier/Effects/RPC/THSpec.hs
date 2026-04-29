module Unit.Atelier.Effects.RPC.THSpec (spec_RPCTH) where

import Data.Aeson (decode, encode)
import Test.Hspec

import Atelier.Effects.RPC (Multiplicity (..), SomeRPC (..))
import Atelier.Effects.RPC.TH (makeProtocol)


-- | A small protocol covering all three constructor arities and both
-- multiplicities. Used as a fixture for the splice's behaviour tests.
data Demo (m :: Multiplicity) a where
    Ping :: Demo Once Int
    Echo :: Text -> Demo Once Text
    Pair :: Int -> Bool -> Demo Once (Int, Bool)
    Stream :: Demo Many Int


makeProtocol ''Demo


spec_RPCTH :: Spec
spec_RPCTH = describe "makeProtocol" do
    describe "ToJSON wire format" do
        it "encodes nullary constructors as [tag, []]" do
            encode Ping `shouldBe` "[\"Ping\",[]]"

        it "encodes unary constructors as [tag, arg]" do
            encode (Echo "hi") `shouldBe` "[\"Echo\",\"hi\"]"

        it "encodes 2-ary constructors as [tag, [a, b]]" do
            encode (Pair 3 True) `shouldBe` "[\"Pair\",[3,true]]"

        it "encodes Many-indexed constructors with the same shape as Once" do
            encode Stream `shouldBe` "[\"Stream\",[]]"

    describe "FromJSON dispatch" do
        it "decodes nullary into the right constructor" do
            case decode @(SomeRPC Demo) "[\"Ping\",[]]" of
                Just (OnceRPC Ping) -> pass
                _ -> expectationFailure "expected OnceRPC Ping"

        it "decodes unary into the right constructor with the right field" do
            case decode @(SomeRPC Demo) "[\"Echo\",\"hi\"]" of
                Just (OnceRPC (Echo s)) -> s `shouldBe` "hi"
                _ -> expectationFailure "expected OnceRPC (Echo _)"

        it "decodes 2-ary into the right constructor with the right fields" do
            case decode @(SomeRPC Demo) "[\"Pair\",[3,true]]" of
                Just (OnceRPC (Pair n b)) -> (n, b) `shouldBe` (3, True)
                _ -> expectationFailure "expected OnceRPC (Pair _ _)"

    describe "wrapper dispatch" do
        it "wraps Once-indexed constructors in OnceRPC" do
            case decode @(SomeRPC Demo) "[\"Ping\",[]]" of
                Just (OnceRPC _) -> pass
                _ -> expectationFailure "expected OnceRPC"

        it "wraps Many-indexed constructors in ManyRPC" do
            case decode @(SomeRPC Demo) "[\"Stream\",[]]" of
                Just (ManyRPC _) -> pass
                _ -> expectationFailure "expected ManyRPC"

    describe "round-trip" do
        it "Ping" do
            case decode @(SomeRPC Demo) (encode Ping) of
                Just (OnceRPC Ping) -> pass
                _ -> expectationFailure "round-trip Ping failed"

        it "Echo with unicode payload" do
            case decode @(SomeRPC Demo) (encode (Echo "héllo 世界")) of
                Just (OnceRPC (Echo s)) -> s `shouldBe` "héllo 世界"
                _ -> expectationFailure "round-trip Echo failed"

        it "Pair" do
            case decode @(SomeRPC Demo) (encode (Pair 42 False)) of
                Just (OnceRPC (Pair n b)) -> (n, b) `shouldBe` (42, False)
                _ -> expectationFailure "round-trip Pair failed"

        it "Stream" do
            case decode @(SomeRPC Demo) (encode Stream) of
                Just (ManyRPC Stream) -> pass
                _ -> expectationFailure "round-trip Stream failed"

    describe "error cases" do
        let parseFails bs = isNothing (decode @(SomeRPC Demo) bs)

        it "fails on unknown tag" do
            parseFails "[\"Bogus\",[]]" `shouldBe` True

        it "fails on non-array top level" do
            parseFails "{\"tag\":\"Ping\"}" `shouldBe` True

        it "fails on wrong-arity top-level array" do
            parseFails "[\"Ping\"]" `shouldBe` True
            parseFails "[\"Ping\",[],null]" `shouldBe` True

        it "fails on type mismatch in argument" do
            parseFails "[\"Echo\",42]" `shouldBe` True
