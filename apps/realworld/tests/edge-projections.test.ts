import { PGlite } from 'npm:@electric-sql/pglite@0.5.8';
import { assertEquals, assertRejects } from 'jsr:@std/assert@1.0.14';

Deno.test('edge projections recount and retract without losing the reader watermark', async () => {
  const db = new PGlite();
  try {
    await db.exec(`
      CREATE ROLE service;
      CREATE TABLE favorite (id text PRIMARY KEY, user_id text, article_id text, deleted_at timestamptz, created_at timestamptz, txid bigint);
      CREATE TABLE article_stats (article_id text PRIMARY KEY, favorite_count int, counted_txid bigint);
      CREATE TABLE favorite_count (id text PRIMARY KEY, user_id text, article_id text, mine_counted int, total_at_read int, as_of_txid bigint);
      CREATE TABLE favorite_index (id text PRIMARY KEY, user_id text, article_id text, active boolean, favorited_at timestamptz);
      CREATE TABLE article_tag (article_id text, tag text);
      CREATE TABLE tag_count (id text PRIMARY KEY, article_count int);
    `);
    await db.exec(await Deno.readTextFile(new URL('../services/database/sql/016_edge_projections.sql', import.meta.url)));
    await db.exec(`INSERT INTO favorite VALUES ('1','u1','a',NULL,'2026-01-01',9), ('2','u2','a',NULL,'2026-01-02',10);
      INSERT INTO article_tag VALUES ('a','news'), ('a','news'), ('b','news');
      SELECT refresh_edge_projections();`);
    assertEquals((await db.query('SELECT favorite_count, counted_txid::text FROM article_stats')).rows, [{ favorite_count: 2, counted_txid: '10' }]);
    assertEquals((await db.query("SELECT mine_counted, total_at_read, as_of_txid::text FROM favorite_count WHERE user_id='u1'")).rows, [{ mine_counted: 1, total_at_read: 2, as_of_txid: '9' }]);
    assertEquals((await db.query('SELECT article_count FROM tag_count')).rows, [{ article_count: 2 }]);
    await db.exec("DELETE FROM favorite WHERE id = '2'; SELECT refresh_edge_projections();");
    assertEquals((await db.query("SELECT mine_counted, total_at_read, as_of_txid::text FROM favorite_count WHERE user_id='u2'")).rows, [{ mine_counted: 0, total_at_read: 1, as_of_txid: '0' }]);
    await db.exec(`UPDATE favorite SET deleted_at = now(), txid = 11 WHERE id = '1'; DELETE FROM article_tag; SELECT refresh_edge_projections(); SELECT refresh_edge_projections();`);
    assertEquals((await db.query("SELECT mine_counted, total_at_read FROM favorite_count WHERE user_id='u2'")).rows, [{ mine_counted: 0, total_at_read: 0 }]);
    assertEquals((await db.query('SELECT favorite_count, counted_txid::text FROM article_stats')).rows, [{ favorite_count: 0, counted_txid: '11' }]);
    assertEquals((await db.query("SELECT mine_counted, total_at_read, as_of_txid::text FROM favorite_count WHERE user_id='u1'")).rows, [{ mine_counted: 0, total_at_read: 0, as_of_txid: '11' }]);
    assertEquals((await db.query('SELECT active FROM favorite_index ORDER BY id')).rows, [{ active: false }, { active: false }]);
    assertEquals((await db.query('SELECT article_count FROM tag_count')).rows, [{ article_count: 0 }]);
  } finally { await db.close(); }
});

Deno.test('favorite guard rejects the author on insert and update', async () => {
  const db = new PGlite();
  try {
    await db.exec(`CREATE TABLE article (id text PRIMARY KEY, author_id text NOT NULL);
      CREATE TABLE favorite (id text PRIMARY KEY, user_id text NOT NULL, article_id text REFERENCES article(id));
      INSERT INTO article VALUES ('a', 'author'), ('b', 'reader');`);
    await db.exec(await Deno.readTextFile(new URL('../services/database/sql/018_favorite_guard.sql', import.meta.url)));
    await assertRejects(() => db.exec("INSERT INTO favorite VALUES ('1', 'author', 'a')"), Error, 'cannot favorite');
    await db.exec("INSERT INTO favorite VALUES ('1', 'reader', 'a')");
    await assertRejects(() => db.exec("UPDATE favorite SET article_id = 'b' WHERE id = '1'"), Error, 'cannot favorite');
    assertEquals((await db.query('SELECT article_id FROM favorite')).rows, [{ article_id: 'a' }]);
  } finally { await db.close(); }
});
