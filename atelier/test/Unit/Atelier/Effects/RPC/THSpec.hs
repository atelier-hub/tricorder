module Unit.Atelier.Effects.RPC.THSpec (spec_RPCTH) where

import Data.Aeson (decode, encode)
import Test.Hspec

import Atelier.Effects.RPC (Multiplicity (..))
import Atelier.Effects.RPC.TH (makeProtocol)


-- | A small protocol covering all three constructor arities and both
-- multiplicities. Used as a fixture for the splice's behaviour tests.
data Demo (m :: Multiplicity) a where
    Ping :: Demo Once Int
    Echo :: Text -> Demo Once Text
    Pair :: Int -> Bool -> Demo Once (Int, Bool)
    Stream :: Demo Many Int


makeProtocol ''Demo ''Multiplicity


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
            case decode @SomeDemo "[\"Ping\",[]]" of
                Just (OnceDemo Ping) -> pass
                _ -> expectationFailure "expected OnceDemo Ping"

        it "decodes unary into the right constructor with the right field" do
            case decode @SomeDemo "[\"Echo\",\"hi\"]" of
                Just (OnceDemo (Echo s)) -> s `shouldBe` "hi"
                _ -> expectationFailure "expected OnceDemo (Echo _)"

        it "decodes 2-ary into the right constructor with the right fields" do
            case decode @SomeDemo "[\"Pair\",[3,true]]" of
                Just (OnceDemo (Pair n b)) -> (n, b) `shouldBe` (3, True)
                _ -> expectationFailure "expected OnceDemo (Pair _ _)"

    describe "wrapper dispatch" do
        it "wraps Once-indexed constructors in OnceDemo" do
            case decode @SomeDemo "[\"Ping\",[]]" of
                Just (OnceDemo _) -> pass
                _ -> expectationFailure "expected OnceDemo"

        it "wraps Many-indexed constructors in ManyDemo" do
            case decode @SomeDemo "[\"Stream\",[]]" of
                Just (ManyDemo _) -> pass
                _ -> expectationFailure "expected ManyDemo"

    describe "round-trip" do
        it "Ping" do
            case decode @SomeDemo (encode Ping) of
                Just (OnceDemo Ping) -> pass
                _ -> expectationFailure "round-trip Ping failed"

        it "Echo with unicode payload" do
            case decode @SomeDemo (encode (Echo "héllo 世界")) of
                Just (OnceDemo (Echo s)) -> s `shouldBe` "héllo 世界"
                _ -> expectationFailure "round-trip Echo failed"

        it "Pair" do
            case decode @SomeDemo (encode (Pair 42 False)) of
                Just (OnceDemo (Pair n b)) -> (n, b) `shouldBe` (42, False)
                _ -> expectationFailure "round-trip Pair failed"

        it "Stream" do
            case decode @SomeDemo (encode Stream) of
                Just (ManyDemo Stream) -> pass
                _ -> expectationFailure "round-trip Stream failed"

    describe "error cases" do
        let parseFails bs = isNothing (decode @SomeDemo bs)

        it "fails on unknown tag" do
            parseFails "[\"Bogus\",[]]" `shouldBe` True

        it "fails on non-array top level" do
            parseFails "{\"tag\":\"Ping\"}" `shouldBe` True

        it "fails on wrong-arity top-level array" do
            parseFails "[\"Ping\"]" `shouldBe` True
            parseFails "[\"Ping\",[],null]" `shouldBe` True

        it "fails on type mismatch in argument" do
            parseFails "[\"Echo\",42]" `shouldBe` True
