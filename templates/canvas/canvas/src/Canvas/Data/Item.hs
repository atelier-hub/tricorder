-- | The @item@ domain type, used by the sample repository and API.
module Canvas.Data.Item
    ( Item (..)
    )
where

import Atelier.Types.QuietSnake (QuietSnake (..))
import Data.Aeson (ToJSON)
import Data.Time (UTCTime)


data Item = Item
    { id :: Int64
    , name :: Text
    , createdAt :: UTCTime
    }
    deriving stock (Eq, Generic, Show)
    deriving (ToJSON) via QuietSnake Item
