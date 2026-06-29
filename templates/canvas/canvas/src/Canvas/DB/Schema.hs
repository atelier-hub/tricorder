-- | Helpers for defining rel8 table schemas in the @canvas@ Postgres schema.
module Canvas.DB.Schema
    ( canvasSchema
    , mkSchema
    , countRows
    )
where

import Atelier.Effects.DB (DBRead)
import Atelier.Effects.DB.Rel8 (select1)
import Rel8
    ( Name
    , Rel8able
    , TableSchema (..)
    , namesFromLabelsWith
    )
import Text.Casing (quietSnake)

import Data.List.NonEmpty qualified as NonEmpty
import Rel8 qualified


-- | Postgres schema name for all application tables.
canvasSchema :: Text
canvasSchema = "canvas"


-- | Build a 'TableSchema' in the application schema, mapping camelCase Haskell
-- field names to snake_case column names automatically.
mkSchema
    :: forall row
     . (Rel8able row)
    => String
    -> TableSchema (row Name)
mkSchema tableName =
    TableSchema
        { name =
            Rel8.QualifiedName
                { name = tableName
                , schema = Just (toString canvasSchema)
                }
        , columns =
            namesFromLabelsWith
                @(row Name)
                (quietSnake . NonEmpty.last)
        }


-- | Count all rows in a table.
countRows :: (DBRead :> es, Rel8able row) => TableSchema (row Name) -> Eff es Int
countRows schema =
    fmap fromIntegral
        $ select1 ("count_rows[" <> toText schema.name.name <> "]")
        $ Rel8.aggregate Rel8.countStar
        $ Rel8.each schema
