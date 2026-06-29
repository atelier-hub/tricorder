-- | Sample repository effect over the @items@ table, demonstrating the
-- atelier-db read/write pattern.
module Canvas.Effects.ItemRepo
    ( ItemRepo (..)
    , listItems
    , createItem
    , runItemRepo
    )
where

import Atelier.Effects.DB (DBRead, DBWrite)
import Atelier.Effects.DB.Rel8 (insert_, select, transact)
import Effectful (Effect)
import Effectful.Dispatch.Dynamic (interpret_)
import Effectful.TH (makeEffect)
import Rel8 (lit)

import Rel8 qualified

import Canvas.Data.Item (Item)

import Canvas.DB.Schemas.Items qualified as Items


-- | Operations on the @items@ table.
data ItemRepo :: Effect where
    -- | Fetch all items.
    ListItems :: ItemRepo m [Item]
    -- | Insert a new item by name (id and timestamp are assigned by the database).
    CreateItem :: Text -> ItemRepo m ()


makeEffect ''ItemRepo


-- | Interpret 'ItemRepo' against the database effects.
runItemRepo
    :: (DBRead :> es, DBWrite :> es)
    => Eff (ItemRepo : es) a
    -> Eff es a
runItemRepo = interpret_ \case
    ListItems -> do
        rows <- select "list_items" (Rel8.each Items.schema)
        pure (map Items.itemFromRow rows)
    CreateItem nm ->
        transact "create_item"
            $ insert_
                Rel8.Insert
                    { into = Items.schema
                    , rows =
                        Rel8.values
                            [ Items.Row
                                { Items.id = Rel8.unsafeDefault
                                , Items.name = lit nm
                                , Items.createdAt = Rel8.unsafeDefault
                                }
                            ]
                    , onConflict = Rel8.Abort
                    , returning = Rel8.NoReturning
                    }
