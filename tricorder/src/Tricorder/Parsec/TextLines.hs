module Tricorder.Parsec.TextLines (TextLines (..)) where

import Text.Megaparsec (Stream (..))
import Prelude hiding (many)


newtype TextLines = TextLines [Text]


instance Stream TextLines where
    type Token TextLines = Text
    type Tokens TextLines = [Text]
    tokenToChunk Proxy = pure
    tokensToChunk Proxy = id
    chunkToTokens Proxy = id
    chunkLength Proxy = length
    chunkEmpty Proxy = null
    take1_ (TextLines []) = Nothing
    take1_ (TextLines (t : ts)) = Just (t, TextLines ts)
    takeN_ n (TextLines s)
        | n <= 0 = Just ([], TextLines s)
        | null s = Nothing
        | otherwise = let (a, b) = splitAt n s in Just (a, TextLines b)
    takeWhile_ p (TextLines s) =
        let (a, b) = span p s in (a, TextLines b)
