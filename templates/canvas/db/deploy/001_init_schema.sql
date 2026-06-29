-- Deploy canvas:001_init_schema to pg

BEGIN;

CREATE SCHEMA IF NOT EXISTS canvas;

COMMIT;
