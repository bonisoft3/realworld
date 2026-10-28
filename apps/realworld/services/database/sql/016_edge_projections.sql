SET lock_timeout = '5s';
SET statement_timeout = '60s';

CREATE OR REPLACE FUNCTION refresh_edge_projections() RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  INSERT INTO article_stats (article_id, favorite_count, counted_txid)
  SELECT a.id, count(f.id) FILTER (WHERE f.deleted_at IS NULL)::integer,
         coalesce(max(f.txid), 0)
  FROM (SELECT article_id AS id FROM favorite UNION SELECT article_id FROM article_stats) a
  LEFT JOIN favorite f ON f.article_id = a.id
  GROUP BY a.id
  ON CONFLICT (article_id) DO UPDATE SET
    favorite_count = EXCLUDED.favorite_count, counted_txid = EXCLUDED.counted_txid
  WHERE (article_stats.favorite_count, article_stats.counted_txid)
    IS DISTINCT FROM (EXCLUDED.favorite_count, EXCLUDED.counted_txid);

  INSERT INTO favorite_count (id, user_id, article_id, mine_counted, total_at_read, as_of_txid)
  SELECT f.user_id::text || ':' || f.article_id::text, f.user_id, f.article_id,
         CASE WHEN f.deleted_at IS NULL THEN 1 ELSE 0 END,
         count(g.id) FILTER (WHERE g.deleted_at IS NULL)::integer, f.txid
  FROM favorite f JOIN favorite g ON g.article_id = f.article_id
  GROUP BY f.id, f.user_id, f.article_id, f.deleted_at, f.txid
  ON CONFLICT (id) DO UPDATE SET mine_counted = EXCLUDED.mine_counted,
    total_at_read = EXCLUDED.total_at_read, as_of_txid = EXCLUDED.as_of_txid
  WHERE (favorite_count.mine_counted, favorite_count.total_at_read, favorite_count.as_of_txid)
    IS DISTINCT FROM (EXCLUDED.mine_counted, EXCLUDED.total_at_read, EXCLUDED.as_of_txid);

  UPDATE favorite_count p SET mine_counted = 0,
    total_at_read = (SELECT count(*)::integer FROM favorite f
                     WHERE f.article_id = p.article_id AND f.deleted_at IS NULL),
    as_of_txid = 0
  WHERE NOT EXISTS (SELECT 1 FROM favorite f
                    WHERE f.user_id = p.user_id AND f.article_id = p.article_id)
    AND (p.mine_counted, p.total_at_read, p.as_of_txid) IS DISTINCT FROM
        (0, (SELECT count(*)::integer FROM favorite f
             WHERE f.article_id = p.article_id AND f.deleted_at IS NULL), 0::bigint);

  INSERT INTO favorite_index (id, user_id, article_id, active, favorited_at)
  SELECT user_id::text || ':' || article_id::text, user_id, article_id,
         deleted_at IS NULL, created_at FROM favorite
  ON CONFLICT (id) DO UPDATE SET active = EXCLUDED.active, favorited_at = EXCLUDED.favorited_at
  WHERE (favorite_index.active, favorite_index.favorited_at)
    IS DISTINCT FROM (EXCLUDED.active, EXCLUDED.favorited_at);

  UPDATE favorite_index i SET active = false
  WHERE i.active AND NOT EXISTS (
    SELECT 1 FROM favorite f WHERE f.user_id = i.user_id AND f.article_id = i.article_id
  );

  INSERT INTO tag_count (id, article_count)
  SELECT t.id, count(DISTINCT a.article_id)::integer
  FROM (SELECT tag AS id FROM article_tag UNION SELECT id FROM tag_count) t
  LEFT JOIN article_tag a ON a.tag = t.id GROUP BY t.id
  ON CONFLICT (id) DO UPDATE SET article_count = EXCLUDED.article_count
  WHERE tag_count.article_count IS DISTINCT FROM EXCLUDED.article_count;
END;
$$;

REVOKE ALL ON FUNCTION refresh_edge_projections() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION refresh_edge_projections() TO service;
