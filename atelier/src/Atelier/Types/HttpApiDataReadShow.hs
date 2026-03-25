module Atelier.Types.HttpApiDataReadShow (HttpApiDataReadShow (..)) where

import Web.HttpApiData (FromHttpApiData (..), ToHttpApiData (..))


newtype HttpApiDataReadShow a
    = HttpApiDataReadShow {getHttpApiDataReadShow :: a}


instance (Read a) => FromHttpApiData (HttpApiDataReadShow a) where
    parseUrlPiece = bimap toText HttpApiDataReadShow . readEither . toString


instance (Show a) => ToHttpApiData (HttpApiDataReadShow a) where
    toUrlPiece = show . getHttpApiDataReadShow
