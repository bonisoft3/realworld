// The article screen mounted WHOLE — the emitted markup, the app's own
// markdown renderer inside its compartment, and every nested region hanging off
// the one-row list, against a store that answers the fragment grammar.
//
// This screen earns the tier twice over. It is the app's only parametrized
// route with a subject (/article/:slug), and the visual battery fills route
// params with slugs no fixture row carries — so every fact this screen derives
// from a row is invisible up there, and the frames it photographs are the
// loading and gone ones. And it is the app's deepest nesting: a cursor filter,
// two sub-regions and two probes all interpolate {id}, {author_id} or
// {created_at} out of the row the slug resolved to, which no other tier can
// even reach.
//
// Every assertion below names a row, or an attribute or node the interpreter
// built from one. Nothing reads the screen's static copy: article.html carries
// a .quiet-note paragraph holding the comment region's empty sentence verbatim
// as a storybook stand-in, so a test that matched on that sentence would pass
// with the region rendering nothing at all.
//
// The store applies the app's own access policies to the reader the mount
// names, so a probe filter carrying no owner column — the pill's
// article_id=eq.{id}&deleted_at=is.null, the byline's followed_id=eq.{author_id}
// — means "mine" here for the same reason it does in the cluster.
import { assert, mountApp, type Mounted, type Row, textOf } from "../../../plugins/omnishell/test/screen-harness.ts";

const APP = new URL("../", import.meta.url);

// The instant the held clock opens on: a form stamping {now} writes exactly
// this, so the retract's own stamp is a value with a name.
const EPOCH = "2026-02-04T12:00:00.000000Z";
const SEED = 20250901;

const SLUG = "the-long-way-round-1a2b3c4d";


const user = (id: string, handle: string, name: string, bio: string): Row => ({
  id,
  handle,
  display_name: name,
  bio,
  image_url: `/avatars/${handle}.png`,
  created_at: "2025-01-01T00:00:00.000000Z",
  txid: "1",
});

const piece = (over: Row): Row => ({
  author_id: "u-ann",
  title: "untitled",
  description: "",
  body: "body",
  tags: "",
  cover_url: null,
  cover_credit: null,
  created_at: "2026-02-01T09:00:00.000000Z",
  updated_at: "2026-02-01T09:00:00.000000Z",
  reading_minutes: 1,
  txid: "2",
  ...over,
});

// The tables the screen's regions declare, all of them: memoryStore throws on a
// table it was not given, and an embed resolves against the joined table too.
const world = (over: Record<string, Row[]> = {}): Record<string, Row[]> => ({
  app_user: [
    user("u-ann", "ann", "Ann Vasari", "Writes about roads."),
    user("u-bob", "bob", "Bob Prine", "Reads about roads."),
    user("u-me", "me", "Me Myself", ""),
  ],
  me: [{ id: "u-me", handle: "me", txid: "1" }],
  article: [piece({ id: "a-main", slug: SLUG, title: "The Long Way Round", description: "Six weeks, one road.", body: "Plain enough.", reading_minutes: 12 })],
  article_tag: [],
  comment: [],
  favorite: [],
  bookmark: [],
  follow: [],
  article_stats: [],
  favorite_count: [],
  favorite_index: [],
  tag_count: [],
  ...over,
});

// The reader every owner column defaults to, the way auth_uid() fills it in
// the cluster. The natural keys an upsert resolves against come from the app's
// own shell.yaml, so a test cannot state a key the database does not enforce.
const read = (tables: Record<string, Row[]>, slug = SLUG, defaults?: Record<string, Row>) =>
  mountApp({
    appDir: APP,
    screen: "article",
    seed: SEED,
    epoch: EPOCH,
    params: { slug },
    tables,
    cluster: { me: "u-me", defaults },
  });

const state = (m: Mounted) => m.screen.getAttribute("data-state");

Deno.test({
  name: "the slug resolves to one piece, and every nested region reads that row",
  sanitizeOps: false,
  sanitizeResources: false,
  async fn() {
    const m = await read(world({
      article: [
        piece({ id: "a-main", slug: SLUG, title: "The Long Way Round", description: "Six weeks, one road.", body: "Plain enough.", reading_minutes: 12, cover_url: "/covers/road.jpg", cover_credit: "Ann, on the A9" }),
        // A decoy under the same author: the slug filter is the only thing
        // keeping it out of the subject position, and every {id} downstream is
        // interpolated from whichever row won.
        piece({ id: "a-other", slug: "a-different-piece-99999999", title: "A Different Piece", created_at: "2026-02-02T09:00:00.000000Z" }),
      ],
      article_tag: [
        { id: "t-1", article_id: "a-main", tag: "zeta", txid: "1" },
        { id: "t-2", article_id: "a-main", tag: "alpha", txid: "1" },
        { id: "t-3", article_id: "a-other", tag: "not-mine", txid: "1" },
      ],
      article_stats: [
        { article_id: "a-main", favorite_count: 7, counted_txid: "5", txid: "5" },
        { article_id: "a-other", favorite_count: 99, counted_txid: "5", txid: "5" },
      ],
    }));
    await m.settle();

    assert(state(m) === "populated", `the screen settled on "${state(m)}"`);
    assert(textOf(m.one(".piece-title")) === "The Long Way Round", `the screen resolved "${textOf(m.one(".piece-title"))}"`);
    assert(textOf(m.one(".deck")) === "Six weeks, one road.", `the deck reads "${textOf(m.one(".deck"))}"`);

    // The byline's every field comes from the article row's author embed
    // (data-select author:app_user(...)), not from a region of its own — so an
    // embed that failed to resolve shows up here as empty text, and the writer
    // card at the foot of the piece reads the same embed.
    assert(textOf(m.one(".byline-row .name")) === "Ann Vasari", `the byline names "${textOf(m.one(".byline-row .name"))}"`);
    assert(textOf(m.one(".byline-row .handle")) === "ann", `the byline handle reads "${textOf(m.one(".byline-row .handle"))}"`);
    assert(textOf(m.one(".writer-bio")) === "Writes about roads.", `the writer card's bio reads "${textOf(m.one(".writer-bio"))}"`);
    assert(
      m.one(".byline-row .avatar").getAttribute("src") === "/avatars/ann.png",
      `the avatar asks for ${m.one(".byline-row .avatar").getAttribute("src")}`,
    );
    // A bound attribute that never resolved is the failure this catches: an
    // unbound data-param-handle composes "/profile/%7Bauthor.handle%7D", a
    // link to a profile that cannot exist.
    assert(
      m.one(".writer-name").getAttribute("href") === "/profile/ann",
      `the writer card links to ${m.one(".writer-name").getAttribute("href")}`,
    );

    // One fixed UTC format, never the raw column (screen.js formatDatetime).
    assert(textOf(m.one(".byline-row .date")) === "Feb 1, 09:00", `the date reads "${textOf(m.one(".byline-row .date"))}"`);
    assert(
      m.one(".byline-row .date").getAttribute("datetime") === "2026-02-01T09:00:00.000000Z",
      `the machine-readable date reads ${m.one(".byline-row .date").getAttribute("datetime")}`,
    );
    // The reading_time ICU message formats the plural reading minutes — the count is never bare text.
    assert(textOf(m.one(".byline-row .read")) === "12 min read", `the reading time reads "${textOf(m.one(".byline-row .read"))}"`);

    // The cover is a sub-region filtered on {id} plus two operators the
    // grammar has to carry (not.is.null and a bare neq.): a cover that
    // resolved against the wrong row, or a filter the store widened, both
    // show as the decoy's picture or as no picture at all.
    assert(m.one(".cover-img").getAttribute("src") === "/covers/road.jpg", `the cover asks for ${m.one(".cover-img").getAttribute("src")}`);
    assert(textOf(m.one(".cover-credit")) === "Ann, on the A9", `the credit reads "${textOf(m.one(".cover-credit"))}"`);

    // Tags: this piece's only, in the region's declared tag.asc — the store's
    // own ordering, over rows seeded in the opposite order.
    assert(
      m.all(".chips .chip").map(textOf).join(",") === "alpha,zeta",
      `the chips read ${JSON.stringify(m.all(".chips .chip").map(textOf))}`,
    );

    // Both pill arms carry the tally, and both read the recount for THIS
    // piece: article_stats is keyed article_id, not id, so a store that keyed
    // it by convention would answer with the decoy's 99.
    assert(
      m.all(".arms .count").map(textOf).join(",") === "7,7",
      `the tallies read ${JSON.stringify(m.all(".arms .count").map(textOf))}`,
    );
    await m.stop();
  },
});

Deno.test({
  name: "the earlier strip is a cursor on this piece's own author and date",
  sanitizeOps: false,
  sanitizeResources: false,
  async fn() {
    const m = await read(world({
      article: [
        piece({ id: "a-main", slug: SLUG, title: "The Long Way Round", created_at: "2026-02-01T09:00:00.000000Z" }),
        piece({ id: "a-e1", slug: "e1-11111111", title: "Earlier One", created_at: "2026-01-05T09:00:00.000000Z" }),
        piece({ id: "a-e2", slug: "e2-22222222", title: "Earlier Two", created_at: "2026-01-04T09:00:00.000000Z" }),
        piece({ id: "a-e3", slug: "e3-33333333", title: "Earlier Three", created_at: "2026-01-03T09:00:00.000000Z" }),
        piece({ id: "a-e4", slug: "e4-44444444", title: "Earlier Four", created_at: "2026-01-02T09:00:00.000000Z" }),
        piece({ id: "a-new", slug: "newer-55555555", title: "Newer", created_at: "2026-03-01T09:00:00.000000Z" }),
        piece({ id: "a-bob", slug: "bobs-66666666", title: "Bob's Earlier", author_id: "u-bob", created_at: "2026-01-06T09:00:00.000000Z" }),
      ],
    }));
    await m.settle();

    const titles = m.all(".earlier-piece .earlier-title").map(textOf);
    // Three facts at once, and each one is a different bug. The cursor is
    // created_at=lt.{created_at} on the row being read, which is also the only
    // thing excluding the piece itself — the region has no neq on id, so a
    // cursor bound from the wrong row puts the reader's own piece in its own
    // "earlier" strip. author_id=eq.{author_id} keeps Bob out even though his
    // piece is the closest earlier one by date. And limit=3 has to survive the
    // interpolation to leave the fourth behind.
    assert(
      titles.join(",") === "Earlier One,Earlier Two,Earlier Three",
      `the strip reads ${JSON.stringify(titles)}`,
    );
    assert(!titles.includes("The Long Way Round"), "the piece being read is in its own earlier strip");
    // Each entry links by slug, not by id: the route is /article/:slug and an
    // id there resolves to nothing.
    const links = m.all(".earlier-piece").map((a) => a.getAttribute("href"));
    assert(
      JSON.stringify(links) === JSON.stringify(["/article/e1-11111111", "/article/e2-22222222", "/article/e3-33333333"]),
      `the strip links to ${JSON.stringify(links)}`,
    );
    assert(
      textOf(m.all(".earlier-piece .earlier-meta time")[0]) === "Jan 5, 09:00",
      `the strip's first date reads "${textOf(m.all(".earlier-piece .earlier-meta time")[0])}"`,
    );
    await m.stop();
  },
});

Deno.test({
  name: "a writer's markdown becomes content, never markup",
  sanitizeOps: false,
  sanitizeResources: false,
  async fn() {
    const body = [
      "# Heading",
      "",
      "A [safe link](https://example.com/x), a [local one](/about) and a [trap](javascript:alert).",
      "",
      "<script>alert(2)</script>",
      "",
      "- one",
      "- two",
    ].join("\n");
    const m = await read(world({ article: [piece({ id: "a-main", slug: SLUG, title: "The Long Way Round", body })] }));
    await m.settle();

    const rendered = m.one(".body");
    // The renderer is the app's own Jessie module, evaluated in a compartment;
    // the screen names it in files.renderers and nothing else on the screen
    // uses it. Structure first: an unrendered body binds the source as one
    // text node, which every text assertion below would still pass.
    assert(textOf(m.one(".body h1")) === "Heading", `the heading rendered as "${textOf(m.one(".body h1"))}"`);
    assert(m.all(".body li").map(textOf).join(",") === "one,two", `the list rendered ${JSON.stringify(m.all(".body li").map(textOf))}`);

    // safeUrl admits http, https, mailto and relative references, and nothing
    // else; a rejected link is pushed back as the characters the writer typed.
    // Both halves matter. Only counting anchors would pass a renderer that
    // dropped the trap silently, losing text somebody wrote — and only
    // checking the trap would pass the far quieter failure, which is that the
    // allowlist refuses EVERYTHING: safeUrl has no host globals to reach for
    // (a compartment endows none), so a scheme test written against URL throws
    // into its own catch and every absolute link renders as literal source.
    const hrefs = m.all(".body a").map((a) => a.getAttribute("href"));
    assert(
      JSON.stringify(hrefs) === JSON.stringify(["https://example.com/x", "/about"]),
      `the body rendered ${JSON.stringify(hrefs)}`,
    );
    assert(textOf(rendered).includes("[trap](javascript:alert)"), "the refused link lost the writer's characters");

    // A body containing markup renders as the characters typed: the terminal's
    // renderer builds every node with createElement/textContent, so this holds
    // without any sanitizer to keep in step with it.
    assert(m.all(".body script").length === 0, "the body grew a script element");
    assert(textOf(rendered).includes("<script>alert(2)</script>"), "the literal tag was not shown as text");
    await m.stop();
  },
});

Deno.test({
  name: "the probes read their true state on arrival, per arm and per depth",
  sanitizeOps: false,
  sanitizeResources: false,
  async fn() {
    const m = await read(world({
      favorite: [{ id: "f-1", user_id: "u-me", article_id: "a-main", created_at: "2026-02-02T09:00:00.000000Z", deleted_at: null, txid: "3" }],
      bookmark: [{ id: "b-1", user_id: "u-me", article_id: "a-main", created_at: "2026-02-02T09:00:00.000000Z", txid: "3" }],
      follow: [{ id: "fo-1", follower_id: "u-me", followed_id: "u-ann", created_at: "2026-02-02T09:00:00.000000Z", txid: "3" }],
      comment: [
        { id: "c-mine", article_id: "a-main", author_id: "u-me", body: "Mine.", created_at: "2026-02-03T08:00:00.000000Z", txid: "4" },
        { id: "c-bobs", article_id: "a-main", author_id: "u-bob", body: "Bob's.", created_at: "2026-02-03T09:00:00.000000Z", txid: "4" },
        { id: "c-other", article_id: "a-other", author_id: "u-me", body: "Elsewhere.", created_at: "2026-02-03T10:00:00.000000Z", txid: "4" },
      ],
      article: [
        piece({ id: "a-main", slug: SLUG, title: "The Long Way Round" }),
        piece({ id: "a-other", slug: "a-different-piece-99999999", title: "A Different Piece" }),
      ],
    }));
    await m.settle();

    // Each probe is a singleton region whose one bound child is the whole
    // signal: the CSS swap that hides one arm and shows the other keys on the
    // probe having a child, so a probe that came back empty on a fresh visit
    // is a reader shown "Favorite" on a piece they already favorited.
    assert(m.all(".arms .fav-probe i").length === 1, "the favorite probe came back empty on a favorited piece");
    assert(m.all(".arms .save-probe i").length === 1, "the save probe came back empty on a saved piece");
    // Two follow probes — the controls row's and the writer card's — declare
    // the same filter, so they are one contract and must settle together.
    assert(m.all(".follow-probe i").length === 2, `${m.all(".follow-probe i").length} of the two follow probes lit`);
    // Not mine to edit: me is owned on id, so the ownership probe is empty for
    // a piece Ann wrote, which is what leaves Follow standing instead of
    // Edit · Delete.
    assert(m.all(".controls .me-probe i").length === 0, "the ownership probe lit on someone else's piece");

    // The thread is this piece's, in created_at.asc, with the author embed
    // resolved per comment.
    assert(m.all(".comment").length === 2, `${m.all(".comment").length} comments on the piece`);
    assert(
      m.all(".comment .comment-body").map(textOf).join(",") === "Mine.,Bob's.",
      `the thread reads ${JSON.stringify(m.all(".comment .comment-body").map(textOf))}`,
    );
    assert(
      m.all(".comment .byline .handle").map(textOf).join(",") === "me,bob",
      `the thread's bylines read ${JSON.stringify(m.all(".comment .byline .handle").map(textOf))}`,
    );
    // The × belongs to one comment. Its probe sits three regions deep, inside
    // an item stamped from a template, and its filter is interpolated from the
    // comment's author_id — a probe bound from the article's row instead would
    // light on every comment or on none.
    const owned = m.all(".comment").filter((c) => c.querySelectorAll(".own-probe i").length === 1);
    assert(owned.length === 1, `${owned.length} comments answered as mine`);
    assert(textOf(owned[0].querySelectorAll(".comment-body")[0]) === "Mine.", "the wrong comment answered as mine");
    await m.stop();
  },
});

Deno.test({
  name: "the pills write through the DOM and take it back",
  sanitizeOps: false,
  sanitizeResources: false,
  async fn() {
    const m = await read(world());
    await m.settle();
    const probe = (sel: string) => m.all(`${sel} i`).length;
    assert(probe(".arms .fav-probe") === 0, "a piece nobody favorited opened with the probe lit");

    // Pressed through the control the reader actually presses, so the hidden
    // fields, the row context they interpolate from and the store call are all
    // the shipped path — not a store call a test made up.
    m.fire(".controls form.when-unset", "submit");
    await m.settle();
    let favorites = m.rows("favorite");
    assert(favorites.length === 1, `favouriting once wrote ${favorites.length} rows`);
    assert(favorites[0].article_id === "a-main", `the favorite landed on ${favorites[0].article_id}`);
    // The owner column is DEFAULT auth_uid(): the form never submits it, and a
    // favorite belonging to nobody is one no policy will ever hand back.
    assert(favorites[0].user_id === "u-me", `the favorite belongs to ${favorites[0].user_id}`);
    assert(favorites[0].deleted_at === null, `the set arm wrote deleted_at ${JSON.stringify(favorites[0].deleted_at)}`);
    assert(probe(".arms .fav-probe") === 1, "the probe did not light on the piece just favorited");

    // The retract is the other arm of the same pair, and it is an UPSERT on the
    // (user_id, article_id) unique — not a second row. A retract that inserted
    // instead would leave the live row standing, so the probe stays lit and the
    // reader can never take a favorite back.
    const id = favorites[0].id;
    m.fire(".controls form.when-set", "submit");
    await m.settle();
    favorites = m.rows("favorite");
    assert(favorites.length === 1, `retracting wrote ${favorites.length} favorite rows`);
    assert(favorites[0].id === id, "the retract minted a second favorite instead of settling the first");
    // Soft, never a delete: the recount pipeline reads deleted_at as its
    // retraction (shell.yaml pipelines.favorite-recount), so a row removed
    // outright is a decrement the tally never sees.
    // The epoch plus the table time the preceding settles spent: on a held
    // clock the stamp is a value the test can name, and a wall clock leaking
    // back into {now} would not land on it.
    assert(
      favorites[0].deleted_at === "2026-02-04T12:00:00.600000Z",
      `the retract stamped deleted_at ${JSON.stringify(favorites[0].deleted_at)}`,
    );
    assert(probe(".arms .fav-probe") === 0, "the probe stayed lit after the favorite was taken back");

    // Save is the same shape with a hard delete, because a bookmark has no
    // public face and nothing downstream counts it.
    m.fire(".controls form.when-unsaved", "submit");
    await m.settle();
    assert(m.rows("bookmark").length === 1, `saving wrote ${m.rows("bookmark").length} rows`);
    assert(m.rows("bookmark")[0].user_id === "u-me", `the save belongs to ${m.rows("bookmark")[0].user_id}`);
    assert(probe(".arms .save-probe") === 1, "the save probe did not light on the piece just saved");
    m.fire(".controls form.when-saved", "submit");
    await m.settle();
    // The unsave form carries its own filter: the row context here is the
    // ARTICLE, so a bare sibling delete would address the article's id and
    // remove nothing at all.
    assert(m.rows("bookmark").length === 0, `unsaving left ${JSON.stringify(m.rows("bookmark"))}`);
    assert(probe(".arms .save-probe") === 0, "the save probe stayed lit after the piece was taken off the list");

    // Follow is declared twice on this screen — the controls row and the writer
    // card — with the same form names and the same filters. They are one
    // contract, so a press on either has to settle both.
    m.fire(".controls .when-reader form.when-unfollowed", "submit");
    await m.settle();
    const follows = m.rows("follow");
    assert(follows.length === 1, `following once wrote ${follows.length} rows`);
    assert(follows[0].followed_id === "u-ann" && follows[0].follower_id === "u-me", `the follow reads ${JSON.stringify(follows[0])}`);
    assert(probe(".follow-probe") === 2, `${probe(".follow-probe")} of the two follow probes lit`);
    // Retracted from the OTHER copy: if the two were separate contracts this is
    // where they would come apart.
    m.fire(".writer .when-reader form.when-following", "submit");
    await m.settle();
    assert(m.rows("follow").length === 0, `unfollowing left ${JSON.stringify(m.rows("follow"))}`);
    assert(probe(".follow-probe") === 0, `${probe(".follow-probe")} follow probes stayed lit after the unfollow`);
    await m.stop();
  },
});

Deno.test({
  name: "a comment reaches the piece it was written under, and an empty one does not",
  sanitizeOps: false,
  sanitizeResources: false,
  async fn() {
    // comment.author_id and comment.created_at are DEFAULT auth_uid() and
    // DEFAULT now(): the reader never states either, and the settled row the
    // thread renders carries both. Fixed literals, never a clock.
    const SERVER = { comment: { author_id: "u-me", created_at: "2026-02-04T11:30:00.000000Z" } };
    const m = await read(
      world({
        article: [
          piece({ id: "a-main", slug: SLUG, title: "The Long Way Round" }),
          piece({ id: "a-other", slug: "a-different-piece-99999999", title: "A Different Piece" }),
        ],
        comment: [{ id: "c-mine", article_id: "a-main", author_id: "u-me", body: "Said already.", created_at: "2026-02-03T08:00:00.000000Z", txid: "4" }],
      }),
      SLUG,
      SERVER,
    );
    await m.settle();

    // The textarea is required, and nothing else on the form is: an empty
    // submit has to be refused by the screen rather than reaching the store,
    // where a CHECK constraint would refuse it as a network failure instead.
    m.fire(".comment-box", "submit");
    await m.settle();
    assert(m.rows("comment").length === 1, `an empty comment wrote ${JSON.stringify(m.rows("comment"))}`);
    assert(m.screen.getAttribute("data-state") === "validation-error", `the empty submit settled on "${m.screen.getAttribute("data-state")}"`);
    assert(!m.one(".comment-box .invalid").hasAttribute("hidden"), "the refusal said nothing to the reader");

    (m.one(".comment-box textarea") as unknown as { value: string }).value = "  Worth the walk.  ";
    m.fire(".comment-box", "submit");
    await m.settle();
    const posted = m.rows("comment").filter((c) => c.id !== "c-mine");
    assert(posted.length === 1, `posting wrote ${posted.length} comments`);
    // The form sits inside the article's row and outside the comment region, so
    // {id} is the piece's — a hidden field bound from the wrong context posts
    // the reader's words onto somebody else's piece.
    assert(posted[0].article_id === "a-main", `the comment landed on ${posted[0].article_id}`);
    assert(posted[0].body === "Worth the walk.", `the comment reads ${JSON.stringify(posted[0].body)}`);
    // Three columns from the form and two from the server, and nothing else.
    assert(
      Object.keys(posted[0]).sort().join(",") === "article_id,author_id,body,created_at,id",
      `the row reads ${JSON.stringify(Object.keys(posted[0]))}`,
    );
    // A submitted value beats a default, so a default that survived is a column
    // the form did not send: this is what says the screen never let the reader
    // state who wrote a comment or when.
    assert(posted[0].author_id === SERVER.comment.author_id, `the comment is attributed to ${posted[0].author_id}`);
    assert(posted[0].created_at === SERVER.comment.created_at, `the comment is dated ${posted[0].created_at}`);

    // And it is on the screen, through the region rather than by hand — every
    // binding in the item, the <time> included. A row missing a column some
    // binding names renders nothing at all, and that failure is a guarded
    // refresh error no rejection trap can see, so only the DOM can report it.
    assert(m.all(".comment").length === 2, `${m.all(".comment").length} comments rendered`);
    const fresh = m.all(".comment")[1];
    assert(textOf(fresh.querySelectorAll(".comment-body")[0]) === "Worth the walk.", `the thread reads "${textOf(fresh.querySelectorAll(".comment-body")[0])}"`);
    assert(textOf(fresh.querySelectorAll(".byline .handle")[0]) === "me", `the new comment is bylined "${textOf(fresh.querySelectorAll(".byline .handle")[0])}"`);
    const when = fresh.querySelectorAll(".date")[0];
    assert(when.getAttribute("datetime") === SERVER.comment.created_at, `the machine-readable date reads ${when.getAttribute("datetime")}`);
    assert(textOf(when) === "Feb 4, 11:30", `the date reads "${textOf(when)}"`);
    // Newest last: the thread is ordered created_at.asc, and the row that just
    // arrived has to sort against the seeded one by its server date.
    assert(textOf(m.all(".comment .comment-body")[0]) === "Said already.", "the arrival displaced the comment that was already there");

    // The × is offered on the reader's own comment and removes it by row id,
    // not by filter: the row context inside the item is the comment, which is
    // already the right one.
    assert(m.all(".comment .own-probe i").length === 2, `${m.all(".comment .own-probe i").length} of the reader's own comments offered a way to remove them`);
    m.fire(fresh.querySelectorAll(".when-mine")[0], "submit");
    await m.settle();
    assert(m.rows("comment").length === 1, `removing left ${JSON.stringify(m.rows("comment"))}`);
    assert(m.rows("comment")[0].id === "c-mine", "the × removed the wrong comment");
    assert(m.all(".comment").length === 1, "the removed comment stayed on the screen");
    await m.stop();
  },
});

Deno.test({
  name: "a slug nobody wrote is gone, and a piece nobody answered is quiet",
  sanitizeOps: false,
  sanitizeResources: false,
  async fn() {
    const quiet = await read(world());
    await quiet.settle();
    // The comment region's note is appended by the region, and it is a p
    // because the region is a div — screen.js picks li only for UL/OL, and an
    // li adrift in a div is the bug that choice exists to prevent. It is also
    // how the note is told apart from .quiet-note, the storybook stand-in
    // sibling that carries the same sentence in the source.
    //
    // data-empty carries the template "{msg.no_comments_yet}", not the
    // rendered sentence — emptyNote() (screen.js) interpolates that template
    // into the note's text but never writes the resolved string back onto the
    // attribute, so a template is not comparable to its own rendering.
    // .quiet-note binds the same key through its own independent data-text,
    // so comparing against it catches both a region rendering nothing and the
    // two copies of the key resolving to different text.
    const note = quiet.one(".comment-list p.empty");
    assert(textOf(note) === textOf(quiet.one(".quiet-note")), `the note reads "${textOf(note)}"`);
    assert(quiet.all(".comment").length === 0, "a comment was rendered into an empty thread");
    // A piece that exists with no comments is populated: empty is a fact about
    // the thread, not about the screen's subject.
    assert(state(quiet) === "populated", `a piece with no comments settled on "${state(quiet)}"`);
    await quiet.stop();

    const gone = await read(world(), "nobody-ever-wrote-this-00000000");
    await gone.settle();
    // The distinction the screen is built around: .piece-probe is a top-level
    // SINGLETON, and a singleton with no row sets gone, which the one-row list
    // beside it cannot express — zero rows there report empty, and empty is a
    // fact about a collection, not about a subject. Collapsing the two shows
    // "nothing has been written yet" for a piece that was removed.
    assert(state(gone) === "gone", `a slug nobody wrote settled on "${state(gone)}"`);
    assert(gone.all(".piece-body").length === 0, "the vanished piece still rendered itself");
    assert(gone.all(".comment-list p.empty").length === 0, "the vanished piece invited comments");
    await gone.stop();
  },
});
