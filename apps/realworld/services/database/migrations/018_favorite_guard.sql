SET lock_timeout = '5s';
SET statement_timeout = '60s';

CREATE OR REPLACE FUNCTION favorite_guard() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF EXISTS (SELECT 1 FROM article WHERE id = NEW.article_id AND author_id = NEW.user_id) THEN
    RAISE EXCEPTION 'a reader cannot favorite what they wrote' USING ERRCODE = '23514';
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS favorite_guard ON favorite;
CREATE TRIGGER favorite_guard BEFORE INSERT OR UPDATE ON favorite
FOR EACH ROW EXECUTE FUNCTION favorite_guard();
