-- Article.tags projected into rows (ir decision-article-tag-trigger). Three
-- things need tag ROWS and none can have a text column: /tag/:name's inner
-- embed, the chips on every preview (a nested region cannot split a string), and
-- tag-recount, whose source must be a crud-path table. A pipeline cannot produce
-- them — an absolute recount can re-assert the pairs a piece HAS and can never
-- retract the pair it no longer has, because the CDC event carries the
-- after-image only, so retagging would leave stale rows and a dishonest
-- popular-tags panel. Delete-and-reinsert inside the article's own transaction is
-- exact by construction, and puts the piece on each tag's list the moment it is
-- on the community list. SECURITY DEFINER because article_tag carries no
-- app_user write policy at all; deletion of an article needs no arm because the
-- FK cascades. Idempotent: initdb replays this on every fresh volume.

SET lock_timeout = '5s';
SET statement_timeout = '60s';

BEGIN;

CREATE OR REPLACE FUNCTION article_tag_sync() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  -- AFTER UPDATE OF fires on the column being NAMED, not changed, and the revise
  -- form always names tags (it must: a form that dropped it would silently
  -- freeze the projection). Without this guard every title fix would churn the
  -- whole tag set, replace every chip's DOM node and wake the pipeline.
  IF TG_OP = 'UPDATE' AND NEW.tags IS NOT DISTINCT FROM OLD.tags THEN
    RETURN NULL;
  END IF;

  DELETE FROM article_tag WHERE article_id = NEW.id;

  INSERT INTO article_tag (article_id, tag)
  SELECT DISTINCT NEW.id, w
  FROM unnest(regexp_split_to_array(lower(coalesce(NEW.tags, '')), '[^a-z0-9-]+')) AS w
  -- A word longer than 40 would fail article_tag's emitted CHECK and abort the
  -- article's own save; losing one over-long word beats losing the piece.
  WHERE w <> '' AND char_length(w) <= 40;

  RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS tag_sync ON article;
CREATE TRIGGER tag_sync
  AFTER INSERT OR UPDATE OF tags ON article
  FOR EACH ROW EXECUTE FUNCTION article_tag_sync();

COMMIT;
