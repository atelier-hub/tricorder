-- Verify canvas:002_create_items_table on pg

BEGIN;

SELECT id, name, created_at FROM canvas.items WHERE false;

ROLLBACK;
