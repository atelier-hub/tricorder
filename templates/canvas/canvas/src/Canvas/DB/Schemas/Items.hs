-- | rel8 table schema for @canvas.items@.
module Canvas.DB.Schemas.Items
    ( Row (..)
    , schema
    , itemFromRow
    )
where

import Data.Time (UTCTime)
import Rel8
    ( Column
    , Name
    , Rel8able
    , Result
    , TableSchema
    )

import Canvas.DB.Schema (mkSchema)
import Canvas.Data.Item (Item (..))


data Row f = Row
    { id :: Column f Int64
    , name :: Column f Text
    , createdAt :: Column f UTCTime
    }
    deriving stock (Generic)
    deriving anyclass (Rel8able)


deriving stock instance Eq (Row Result)


deriving stock instance Show (Row Result)


-- | Table schema for @canvas.items@.
schema :: TableSchema (Row Name)
schema = mkSchema "items"


-- | Convert a database row into the domain 'Item'.
itemFromRow :: Row Result -> Item
itemFromRow row =
    Item
        { id = row.id
        , name = row.name
        , createdAt = row.createdAt
        }
