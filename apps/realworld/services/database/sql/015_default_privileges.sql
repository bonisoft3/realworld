-- 002 grants app_user and service DML on every table postgres creates in this
-- schema from that point on. The app's own tables want it; nothing created
-- afterwards does. The auth service builds webauthn_credential here at first
-- start, as postgres, with no RLS of its own — so the standing default hands
-- every signed-in reader SELECT, INSERT, UPDATE and DELETE on the passkey
-- table, and an INSERT naming somebody else's user_id is that account.
--
-- Running after 004, the declared tables keep the privileges they were created
-- with and everything later inherits none. Revoking from the app roles only:
-- every service connects as postgres and PostgREST reaches app_user, anon and
-- service through SET ROLE, so the auth service still owns and writes its own
-- table.

SET lock_timeout = '5s';
SET statement_timeout = '60s';

BEGIN;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
  REVOKE ALL ON TABLES FROM app_user, service;

COMMIT;
