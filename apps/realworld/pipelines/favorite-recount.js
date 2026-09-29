// favorite-recount, browser side: the same count as favorite-recount.blobl,
// written as a fold so the reader can resume it.
//
// This runs at the PGlite browser tier only. The container keeps the bloblang,
// which rpk lints at build time; nothing lints a JavaScript string in a
// pipeline YAML (ir decision-optimistic-fold). The cluster tier does not fold
// at all — it reads `others` from the pipeline and adds the reader's intent.
//
// The accumulator IS the sink row, so `article_stats` can be read back as a
// partial fold.
// `counted_txid` is the read watermark and covers RETRACTED rows too: filtering
// it to active rows would leave a just-retracted row above the watermark, where
// a reader would take it for a change the sink has not seen.

// counted_txid is an int64 carrier: a canonical decimal string, compared as an
// integer. The winner is re-spelled through BigInt rather than passed through,
// because String() of 1e21 is "1e+21" and of "007" is "007", and the column
// holds neither.
const later = (a, b) => String(BigInt(a ?? "0") >= BigInt(b ?? "0") ? BigInt(a ?? "0") : BigInt(b));

export const empty = (article_id) => harden({ article_id, favorite_count: 0, counted_txid: "0" });

// A retracted row still moves the watermark and still counts for nothing,
// which is how one pass over the whole group yields both numbers.
export const step = (acc, row) =>
  harden({
    ...acc,
    favorite_count: acc.favorite_count + (row.deleted_at == null ? 1 : 0),
    counted_txid: later(acc.counted_txid, row.txid),
  });

export const combine = (a, b) =>
  harden({
    ...a,
    favorite_count: a.favorite_count + b.favorite_count,
    counted_txid: later(a.counted_txid, b.counted_txid),
  });

export const result = (acc) => acc;
