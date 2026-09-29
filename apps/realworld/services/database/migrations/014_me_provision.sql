-- The reader's own row, provisioned inside the auth service's own insert
-- (ir decision-me-row). A trigger rather than a pipeline because the row must
-- exist on the first paint after a one-click guest sign-in and a CDC round trip
-- is seconds — /settings has no :param to identify anyone with, so a missing me
-- row is a blank settings screen. AFTER INSERT because me.id REFERENCES
-- app_user(id): the parent must be on disk before the child. SECURITY DEFINER
-- because 012 leaves me with no app_user write arm, and handle is copied rather
-- than joined because it cannot drift — 011's column grant excludes it.
-- Idempotent: initdb replays this on every fresh volume.

SET lock_timeout = '5s';
SET statement_timeout = '60s';

BEGIN;

CREATE OR REPLACE FUNCTION me_provision() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  INSERT INTO me (id, handle) VALUES (NEW.id, NEW.handle);
  RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS provision_me ON app_user;
CREATE TRIGGER provision_me
  AFTER INSERT ON app_user
  FOR EACH ROW EXECUTE FUNCTION me_provision();

COMMIT;
