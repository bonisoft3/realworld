-- 002 grants app_user and service DML on every table postgres creates in this
-- schema from that point on. The app's own tables want it; nothing created
-- afterwards does: a table a service or a later step makes here would hand
-- every signed-in reader SELECT, INSERT, UPDATE and DELETE on it. (The auth
-- service keeps its passkeys and links in mecha_auth, out of this schema.)
--
-- Running after 004, the declared tables keep the privileges they were created
-- with and everything later inherits none. Revoking from the app roles only:
-- every service connects as postgres and PostgREST reaches app_user, anon and
-- service through SET ROLE, so every service still owns and writes its own
-- tables.

SET lock_timeout = '5s';
SET statement_timeout = '60s';

BEGIN;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
  REVOKE ALL ON TABLES FROM app_user, service;

COMMIT;
