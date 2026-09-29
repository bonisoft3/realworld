// The community stream mounted WHOLE — the list, the four sub-regions every
// preview carries, and the tag rail, over the emitted markup and a store that
// answers the fragment grammar.
//
// This is the app's widest region: one filter and one order decide what a
// reader sees first, and each of the twenty items stamps four more regions that
// interpolate {id} out of their own row. The window that matters is not any one
// frame but what happens BETWEEN them — a row arriving over CDC has to land in
// its sorted place without rebuilding the previews around it, because a rebuilt
// preview is a lost listener and a picture that flashes. No tier above this one
// can watch a single node across a refresh: the visual battery photographs
// frames, and the cluster tier cannot ask whether the element it is looking at
// is the same object it was looking at before.
//
// Every assertion names a row, or a node the interpreter built from one.
import { assert, mountApp, type Mounted, type Row, textOf } from "../../../plugins/omnishell/test/screen-harness.ts";

const APP = new URL("../", import.meta.url);

const SEED = 20250901;


const piece = (n: number, over: Row = {}): Row => ({
  id: `a-${String(n).padStart(2, "0")}`,
  author_id: "u-ann",
  title: `Piece ${String(n).padStart(2, "0")}`,
  description: "",
  body: "body",
  tags: "",
  cover_url: null,
  cover_credit: null,
  slug: `piece-${String(n).padStart(2, "0")}-abcdef01`,
  // Day n of March 2026, so the seeded order is the reverse of the id order.
  created_at: `2026-03-${String(n).padStart(2, "0")}T09:00:00.000000Z`,
  updated_at: `2026-03-${String(n).padStart(2, "0")}T09:00:00.000000Z`,
  reading_minutes: n,
  txid: "2",
  ...over,
});

// The tables the screen's regions declare, all of them: memoryStore throws on a
// table it was not given, and the author embed resolves against app_user.
const world = (over: Record<string, Row[]> = {}): Record<string, Row[]> => ({
  app_user: [
    { id: "u-ann", handle: "ann", display_name: "Ann Vasari", bio: "", image_url: "/avatars/ann.png", created_at: "2025-01-01T00:00:00.000000Z", txid: "1" },
  ],
  article: [],
  article_tag: [],
  favorite: [],
  bookmark: [],
  article_stats: [],
  tag_count: [],
  ...over,
});

const stream = (tables: Record<string, Row[]>) =>
  mountApp({ appDir: APP, screen: "home", seed: SEED, tables });

const titles = (m: Mounted) => m.all(".preview .preview-title").map(textOf);

Deno.test({
  name: "the stream is capped at twenty, newest first, ties broken by id",
  sanitizeOps: false,
  sanitizeResources: false,
  async fn() {
    const article = [];
    for (let n = 1; n <= 22; n++) article.push(piece(n));
    // Three pieces published in the same instant. created_at alone leaves their
    // order to whatever the store happened to hold, which is a stream that
    // reshuffles itself between refreshes; id.desc is the tiebreak that makes
    // the order total, and it only shows up on a tie.
    article.push(piece(30, { created_at: "2026-03-22T09:00:00.000000Z", updated_at: "2026-03-22T09:00:00.000000Z" }));
    article.push(piece(31, { created_at: "2026-03-22T09:00:00.000000Z", updated_at: "2026-03-22T09:00:00.000000Z" }));

    const m = await stream(world({ article }));
    await m.settle();

    const shown = titles(m);
    assert(shown.length === 20, `the stream drew ${shown.length} previews, and the region asked for 20`);
    assert(
      shown.slice(0, 4).join(",") === "Piece 31,Piece 30,Piece 22,Piece 21",
      `the stream opens ${JSON.stringify(shown.slice(0, 4))}`,
    );
    // The cap has to take the newest twenty, not the first twenty the store
    // held: a limit applied before the sort would show Piece 01 upward.
    assert(!shown.includes("Piece 03"), "the cap kept the oldest pieces and dropped the newest");
    assert(shown.at(-1) === "Piece 05", `the stream ends on ${shown.at(-1)}`);
    // populated, not empty: the base state follows the top region's row count.
    assert(m.screen.getAttribute("data-state") === "populated", `the screen settled on "${m.screen.getAttribute("data-state")}"`);
    await m.stop();
  },
});

Deno.test({
  name: "every preview's sub-regions are scoped to its own row",
  sanitizeOps: false,
  sanitizeResources: false,
  async fn() {
    const m = await stream(world({
      article: [
        piece(3, { title: "With Cover", cover_url: "/covers/three.jpg" }),
        piece(2, { title: "No Cover" }),
        // A cover column that exists but is empty: the region's filter spends
        // two operators on this case (not.is.null AND neq.), because an empty
        // string is a picture request for the page itself.
        piece(1, { title: "Blank Cover", cover_url: "" }),
      ],
      article_tag: [
        { id: "t-1", article_id: "a-03", tag: "roads", txid: "1" },
        { id: "t-2", article_id: "a-03", tag: "atlas", txid: "1" },
        { id: "t-3", article_id: "a-02", tag: "only-two", txid: "1" },
      ],
      article_stats: [{ article_id: "a-03", favorite_count: 12, counted_txid: "5", txid: "5" }],
      favorite: [{ id: "f-1", user_id: "u-me", article_id: "a-02", created_at: "2026-03-04T09:00:00.000000Z", deleted_at: null, txid: "3" }],
      bookmark: [{ id: "b-1", user_id: "u-me", article_id: "a-01", created_at: "2026-03-04T09:00:00.000000Z", txid: "3" }],
    }));
    await m.settle();

    const previews = m.all(".preview");
    assert(titles(m).join(",") === "With Cover,No Cover,Blank Cover", `the stream reads ${JSON.stringify(titles(m))}`);

    // Each of the four sub-regions is stamped once per item and filtered on the
    // item's own {id}. A binding that resolved against the list's context
    // instead of the row's gives every preview the first row's answer, which
    // reads as a plausible screen and is wrong on nineteen of twenty items.
    const sub = (i: number, sel: string) => [...previews[i].querySelectorAll(sel)];
    assert(sub(0, ".thumb-img").length === 1, "the piece with a cover drew no thumbnail");
    assert(sub(0, ".thumb-img")[0].getAttribute("src") === "/covers/three.jpg", `the thumbnail asks for ${sub(0, ".thumb-img")[0].getAttribute("src")}`);
    assert(sub(1, ".thumb-img").length === 0, "a piece with no cover drew a thumbnail");
    assert(sub(2, ".thumb-img").length === 0, "a piece with an empty cover column drew a thumbnail");

    assert(sub(0, ".chip").map(textOf).join(",") === "atlas,roads", `the first preview's chips read ${JSON.stringify(sub(0, ".chip").map(textOf))}`);
    assert(sub(1, ".chip").map(textOf).join(",") === "only-two", `the second preview's chips read ${JSON.stringify(sub(1, ".chip").map(textOf))}`);
    assert(sub(2, ".chip").length === 0, "a piece with no tags drew chips");

    // data-empty-row is the tally's whole answer until the recount pipeline has
    // written a sink row, and a piece nobody has favorited never gets one.
    const tally = (i: number) => sub(i, '.arms [data-live="article_stats"]').map(textOf);
    assert(tally(0).join(",") === "12,12", `the recounted tally reads ${JSON.stringify(tally(0))}`);
    assert(tally(1).join(",") === "0,0", `an unrecounted tally reads ${JSON.stringify(tally(1))}`);

    // The probes decide which arm of each pair the reader is shown, and they
    // are per row: exactly one preview is favorited and a different one saved.
    assert(sub(1, ".fav-probe i").length === 1, "the favorited piece's probe came back empty");
    assert(sub(0, ".fav-probe i").length === 0 && sub(2, ".fav-probe i").length === 0, "a probe lit on a piece that was not favorited");
    assert(sub(2, ".save-probe i").length === 1, "the saved piece's probe came back empty");
    assert(sub(0, ".save-probe i").length === 0 && sub(1, ".save-probe i").length === 0, "a save probe lit on a piece that was not saved");

    // The continuation link is a cursor built from the row it sits under, and
    // routeHref percent-encodes a :param — the timestamp's colons included.
    assert(
      previews[0].querySelectorAll(".older")[0].getAttribute("href") === "/older/2026-03-03T09%3A00%3A00.000000Z",
      `the continuation points at ${previews[0].querySelectorAll(".older")[0].getAttribute("href")}`,
    );
    await m.stop();
  },
});

Deno.test({
  name: "a piece arriving lands in order without rebuilding the stream",
  sanitizeOps: false,
  sanitizeResources: false,
  async fn() {
    const m = await stream(world({
      article: [piece(5), piece(3), piece(1)],
      article_tag: [{ id: "t-1", article_id: "a-03", tag: "roads", txid: "1" }],
    }));
    await m.settle();
    assert(titles(m).join(",") === "Piece 05,Piece 03,Piece 01", `the stream opened ${JSON.stringify(titles(m))}`);

    // Node identity, held across the refresh. The region reconciles by key, so
    // an item that is still in the answer must be the same element afterwards —
    // its listeners, its sub-regions and any transition it is mid-way through
    // all belong to that node. Rebuilt from the template instead, the screen
    // looks identical in a photograph and replays every picture load.
    const before = m.all(".preview");
    const held = before[1];
    const heldChip = m.all(".preview")[1].querySelectorAll(".chip")[0];

    // A row the reader did not write, arriving the way replication delivers
    // one: straight into the store, waking the region's subscription.
    await m.store.create("article", piece(4));
    await m.settle();

    const after = m.all(".preview");
    assert(
      titles(m).join(",") === "Piece 05,Piece 04,Piece 03,Piece 01",
      `the arrival left the stream reading ${JSON.stringify(titles(m))}`,
    );
    assert(after[2] === held, "the piece below the arrival was rebuilt rather than moved");
    assert(after[0] === before[0] && after[3] === before[2], "an untouched preview was rebuilt");
    // The sub-region inside a moved item moves with it: a preview reconciled by
    // key but re-stamped inside would lose its chips and its probe answers.
    assert(after[2].querySelectorAll(".chip")[0] === heldChip, "the moved preview's chips were re-stamped");
    assert(textOf(after[1].querySelectorAll(".preview-title")[0]) === "Piece 04", "the arrival did not bind its own row");

    // And a row leaving takes its node and only its node.
    await m.store.remove("article", "a-04");
    await m.settle();
    const left = m.all(".preview");
    assert(titles(m).join(",") === "Piece 05,Piece 03,Piece 01", `the removal left ${JSON.stringify(titles(m))}`);
    assert(left[1] === held, "the removal rebuilt the pieces that remained");
    await m.stop();
  },
});

Deno.test({
  name: "the rail counts only tags somebody used, and an unwritten community says so",
  sanitizeOps: false,
  sanitizeResources: false,
  async fn() {
    const m = await stream(world({
      article: [piece(1)],
      tag_count: [
        { id: "roads", article_count: 3, txid: "1" },
        { id: "atlas", article_count: 9, txid: "1" },
        // A tag whose last article was deleted: the sink row stays behind at
        // zero, and article_count=gt.0 is the only thing keeping a chip that
        // leads to an empty tag screen out of the rail.
        { id: "orphan", article_count: 0, txid: "1" },
        { id: "boats", article_count: 3, txid: "1" },
      ],
    }));
    await m.settle();
    // Ties on the count fall back to id.asc, so the rail is stable between
    // refreshes rather than ordered by whatever the store held.
    assert(
      m.all(".tag-chip .tag-name").map(textOf).join(",") === "atlas,boats,roads",
      `the rail reads ${JSON.stringify(m.all(".tag-chip .tag-name").map(textOf))}`,
    );
    assert(
      m.all(".tag-chip .tag-tally").map(textOf).join(",") === "9,3,3",
      `the tallies read ${JSON.stringify(m.all(".tag-chip .tag-tally").map(textOf))}`,
    );
    await m.stop();

    const bare = await stream(world());
    await bare.settle();
    assert(bare.all(".preview").length === 0, "a preview was drawn with no articles");
    // data-empty carries the template "{msg.home_list_empty}", not the
    // rendered sentence — emptyNote() (screen.js) interpolates that template
    // into the note's text but never writes the resolved string back onto the
    // attribute, so the assertion names the catalogue's own en value instead.
    const note = bare.one(".list p.empty");
    assert(
      textOf(note) === "Nothing has been written here yet. Yours could be the first — New Article is in the bar above.",
      `the note reads "${textOf(note)}"`,
    );
    // The rail carries its own invitation, and it is a different sentence: one
    // note standing in for both regions is a rail that tells a reader to write
    // an article when what is missing is a tag.
    const railNote = bare.one(".tags p.empty");
    assert(textOf(railNote) === "Tags appear as soon as a writer types one.", `the rail note reads "${textOf(railNote)}"`);
    assert(bare.screen.getAttribute("data-state") === "empty", `an unwritten community settled on "${bare.screen.getAttribute("data-state")}"`);
    await bare.stop();
  },
});

// Which endonym the trigger shows is a stylesheet's answer, and the stylesheet
// spells the fifteen tags again, two files from the table that declares them.
// Nothing derives one from the other, so this is what holds them to one list:
// a locale the CSS never heard of shows a globe, a chevron and no language.
Deno.test({
  name: "every language the app declares is one the trigger can show",
  sanitizeOps: false,
  sanitizeResources: false,
  async fn() {
    const css = await Deno.readTextFile(new URL("shell/shared/system.css", APP));
    const m = await mountApp({ appDir: APP, screen: "home", seed: SEED, tables: world() });
    await m.settle();
    const declared = m.all(".lang-current i").map((el) => el.getAttribute("data-t"));
    assert(declared.length > 0, "the trigger carries no endonyms at all");
    const unshowable = declared.filter((tag) => !css.includes(`.lang-current i[data-t="${tag}"]`));
    assert(
      unshowable.length === 0,
      `system.css can never reveal ${JSON.stringify(unshowable)} — the trigger would read as a globe alone`,
    );
    await m.stop();
  },
});

Deno.test({
  name: "the picker names the language the reader is in, marks it once, and turns only the right-to-left names around",
  sanitizeOps: false,
  sanitizeResources: false,
  async fn() {
    // Arabic: not the default, not first in the list, and the case the dir
    // attribute exists for. Which of the fifteen endonyms the trigger SHOWS is
    // system.css reading [data-locale] off the screen root, so this tier can
    // only assert that the attribute and the fifteen candidates are both there
    // for it to read.
    const m = await mountApp({ appDir: APP, screen: "home", seed: SEED, tables: world(), locale: "ar" });
    await m.settle();

    assert(m.screen.getAttribute("data-locale") === "ar", `the screen mounted in "${m.screen.getAttribute("data-locale")}"`);
    assert(m.screen.firstElementChild === m.one(".lang-picker"), "the picker is not the screen's first row, where the shared placement puts it");
    assert(m.all(".lang-current i").length === 15, `the trigger carries ${m.all(".lang-current i").length} endonyms and the app declares 15`);

    // aria-current is the interpreter's answer to data-locale-current, and it
    // is what lifts the row to the top of the menu and ticks it. Exactly one
    // row can be the page the reader is already on.
    const current = m.all('.lang-item[aria-current="page"]');
    assert(current.length === 1, `${current.length} rows claim to be the page the reader is on`);
    assert(current[0].getAttribute("data-locale") === "ar", `the marked row names ${current[0].getAttribute("data-locale")}`);

    // dir rides the NAME, never the row: a row that turned around whole is the
    // layout bug this replaced.
    const turned = m.all(".lang-item").filter((a) => a.querySelectorAll(".lang-name[dir]").length === 1)
      .map((a) => a.getAttribute("data-locale"));
    assert(turned.join(",") === "ur,ar", `the names carrying dir belong to ${JSON.stringify(turned)}`);
    assert(m.all(".lang-item[dir]").length === 0, "a whole row carries dir, which turns its structure around and not just its script");
    await m.stop();
  },
});
