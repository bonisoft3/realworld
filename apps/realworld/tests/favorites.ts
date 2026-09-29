// One favourite, through the cluster: written over CRUD, counted by
// favorite-recount into article_stats, paired by favorite-count into the
// reader's favorite_count, indexed by favorite-index, then retracted — counted
// again and indexed inactive. No other rung of this app writes a row and reads
// what the pipelines made of it.
//
// Both watermarks are int64 carriers, so each path owes them as a canonical
// decimal string — a bare JSON number is what PostgREST refuses and what a
// JavaScript reader rounds — and they are compared as integers, because as
// strings "9" outranks "10".

import { assert, assertEquals } from "jsr:@std/assert@1";
import { baseUrl } from "../../../plugins/omnishell/base-url.ts";

const base = await baseUrl(Deno.args[0] ?? ".");
const call = (path: string, init: RequestInit = {}) => fetch(`${base}${path}`, init);
const json = async (r: Response, what: string) => {
  const body = await r.text();
  assert(r.ok, `${what}: ${r.status} ${body}`);
  return body === "" ? null : JSON.parse(body);
};

const guest = async () =>
  (await json(await call("/auth/guest", { method: "POST", headers: { "content-type": "application/json" }, body: "{}" }), "guest")).token as string;
const as = (token: string) => ({
  Authorization: `Bearer ${token}`,
  "content-type": "application/json",
  Prefer: "return=representation",
});

// A reader may not favourite their own piece, so the author is someone else.
const [article] = await json(
  await call("/crud/article", {
    method: "POST",
    headers: as(await guest()),
    body: JSON.stringify({ title: "favorites check", body: "a piece to be favourited" }),
  }),
  "the author publishes",
);
const reader = await guest();
const readerId = JSON.parse(atob(reader.split(".")[1])).sub;

const until = async (what: string, path: string, done: (rows: Record<string, unknown>[]) => boolean) => {
  for (let i = 0; i < 120; i++) {
    const rows = await json(await call(path, { headers: as(reader) }), what);
    if (done(rows)) return rows[0];
    await new Promise((r) => setTimeout(r, 500));
  }
  throw new Error(`${what}: the pipeline never wrote it`);
};
const int64 = (value: unknown, what: string) => {
  assert(typeof value === "string" && /^(0|-?[1-9][0-9]*)$/.test(value), `${what} is a canonical int64 string: ${JSON.stringify(value)}`);
  return BigInt(value);
};

const favoriteId = crypto.randomUUID();
const [favorite] = await json(
  await call("/crud/favorite", {
    method: "POST",
    headers: as(reader),
    body: JSON.stringify({ id: favoriteId, user_id: readerId, article_id: article.id }),
  }),
  "the reader favourites",
);
const stats = `/crud/article_stats?article_id=eq.${article.id}`;

const counted = await until("article_stats", stats, (r) => r.length === 1 && r[0].favorite_count === 1);
assertEquals(int64(counted.counted_txid, "counted_txid"), BigInt(favorite.txid), "the count's watermark is the favourite it read");

const pair = await until("favorite_count", `/crud/favorite_count?article_id=eq.${article.id}`, (r) => r.length === 1);
assertEquals(int64(pair.as_of_txid, "as_of_txid"), BigInt(favorite.txid), "the reader's pair speaks for their favourite");
assertEquals(pair.mine_counted, 1);

await json(
  await call(`/crud/favorite?id=eq.${favoriteId}`, {
    method: "PATCH",
    headers: as(reader),
    body: JSON.stringify({ deleted_at: new Date().toISOString().replace("Z", "000Z") }),
  }),
  "the reader retracts",
);
const retracted = await until("article_stats after retraction", stats, (r) => r.length === 1 && r[0].favorite_count === 0);
assert(
  int64(retracted.counted_txid, "counted_txid") > int64(counted.counted_txid, "counted_txid"),
  `a retraction moves the watermark forward: ${counted.counted_txid} → ${retracted.counted_txid}`,
);

// The retraction's row is built from the CDC event rather than a fetched row,
// and the event spells its instant as Postgres text, not as the carrier.
const index = await until(
  "favorite_index after retraction",
  `/crud/favorite_index?id=eq.${readerId}:${article.id}`,
  (r) => r.length === 1 && r[0].active === false,
);
assert(
  /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{6}Z$/.test(String(index.favorited_at)),
  `favorited_at is a canonical timestamp: ${JSON.stringify(index.favorited_at)}`,
);

console.log(`favorites: counted at ${counted.counted_txid}, retracted at ${retracted.counted_txid}`);
