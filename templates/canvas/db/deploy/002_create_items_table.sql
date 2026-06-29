-- Deploy canvas:002_create_items_table to pg
-- requires: 001_init_schema

BEGIN;

CREATE TABLE canvas.items (
    id          bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name        text NOT NULL,
    created_at  timestamptz NOT NULL DEFAULT now()
);

COMMIT;
