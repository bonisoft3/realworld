-- Owner writes over public-read tables (ir decision-public-read-owner-writes).
-- #Access has no "everyone reads, the owner writes" mode. public-read emits a
-- SELECT arm and the service catch-all and nothing else, so these three tables
-- would refuse every form insert as declared. The arms arrive here, additively:
-- RLS policies are PERMISSIVE and OR together, and nothing above is dropped
-- because public-read put nothing there. The rejected alternative — declaring
-- `owned` and widening SELECT in SQL — is a booby trap: emit.cue mirrors the
-- DECLARED mode into shell.yaml and the browser re-applies it on every locally
-- translated read, so the same table would mean "mine" in-tab and "everyone's"
-- server-side. The rule: the declared mode is the mode the client must believe;
-- widen only where the mirror already allows, narrow freely.
--
-- Two absences are deliberate. `comment` gets no UPDATE arm — editing a comment
-- is out of scope, and the missing policy is what keeps that true even if a form
-- ever appears. `article_tag` gets no arm at all: every row of it belongs to the
-- 013 trigger (ir decision-article-tag-trigger).
--
-- Idempotent via DROP POLICY IF EXISTS; initdb replays this on a fresh volume.

SET lock_timeout = '5s';
SET statement_timeout = '60s';

BEGIN;

DROP POLICY IF EXISTS article_app_user_insert ON article;
CREATE POLICY article_app_user_insert ON article FOR INSERT TO app_user
  WITH CHECK (author_id = auth_uid());
-- WITH CHECK is narrowing over what `owned` would emit: without it a hand-made
-- PATCH could reassign author_id and hand the piece to somebody else.
DROP POLICY IF EXISTS article_app_user_update ON article;
CREATE POLICY article_app_user_update ON article FOR UPDATE TO app_user
  USING (author_id = auth_uid()) WITH CHECK (author_id = auth_uid());
DROP POLICY IF EXISTS article_app_user_delete ON article;
CREATE POLICY article_app_user_delete ON article FOR DELETE TO app_user
  USING (author_id = auth_uid());

DROP POLICY IF EXISTS comment_app_user_insert ON comment;
CREATE POLICY comment_app_user_insert ON comment FOR INSERT TO app_user
  WITH CHECK (author_id = auth_uid());
DROP POLICY IF EXISTS comment_app_user_delete ON comment;
CREATE POLICY comment_app_user_delete ON comment FOR DELETE TO app_user
  USING (author_id = auth_uid());

DROP POLICY IF EXISTS app_user_app_user_update ON app_user;
CREATE POLICY app_user_app_user_update ON app_user FOR UPDATE TO app_user
  USING (id = auth_uid());
-- There is deliberately no INSERT and no DELETE arm on app_user: identities are
-- minted under the `service` role and never removed.

-- The column lever (ir test-handle-not-writable). An RLS policy gates which ROW
-- may be updated and never which COLUMNS, and 002_grants.sql emits a table-wide
-- GRANT UPDATE ON ALL TABLES TO app_user — so the policy above would happily let
-- `PATCH /crud/app_user?id=eq.<me> {"handle":"…"}` through on the reader's own
-- row. That is the case a row policy cannot cover, and Me.handle's "cannot
-- drift" justification rests on it: me.handle is a copy frozen at provisioning,
-- so one such PATCH would strand the person's own profile route. Narrowing, so
-- safe under decision 2's own rule; PostgREST answers 42501 on any other column.
REVOKE UPDATE ON app_user FROM app_user;
GRANT UPDATE (display_name, bio, image_url) ON app_user TO app_user;

COMMIT;
