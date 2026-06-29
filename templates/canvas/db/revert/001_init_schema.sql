-- Revert canvas:001_init_schema from pg

BEGIN;

DROP SCHEMA IF EXISTS canvas CASCADE;

COMMIT;
