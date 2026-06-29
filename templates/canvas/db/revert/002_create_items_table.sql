-- Revert canvas:002_create_items_table from pg

BEGIN;

DROP TABLE IF EXISTS canvas.items;

COMMIT;
