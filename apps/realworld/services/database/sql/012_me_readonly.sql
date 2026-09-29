-- me is read-only to browsers (ir decision-me-row). Access is `owned` on id, so
-- 006_policies.sql emits the full owner quartet; these three arms are dropped
-- because nothing should write this table from a browser and a person deleting
-- their own row would lock themselves out of their own settings screen. The
-- SELECT arm stays — the row's mere visibility, joined against an author_id or a
-- handle, is how four screens ask "is this mine?" — and so does the service
-- catch-all, which is what the 014 trigger writes through. Narrowing, therefore
-- always safe. Idempotent via DROP POLICY IF EXISTS.

SET lock_timeout = '5s';
SET statement_timeout = '60s';

BEGIN;

DROP POLICY IF EXISTS me_app_user_insert ON me;
DROP POLICY IF EXISTS me_app_user_update ON me;
DROP POLICY IF EXISTS me_app_user_delete ON me;

COMMIT;
