# Contributing to apps/realworld

The app is *Conduit* — that is its product name, from the brief and
`decision-design-identity`. This file calls it **realworld** throughout,
because `conduit` is also the CDC service in the cluster and a sentence with
both in it is unreadable.

What this app needs that nothing else in the tree states. Everything derivable
from the sources is deliberately absent: `program.cue` is the program,
`ir.html` is the design it realizes, `plugins/pronto/schema.cue` is the
vocabulary both are written in, and restating any of them here would only rot.

## The loop

```bash
cd apps/realworld
just lint     # bijection + screens + cue vet + rpk + caddy
just build    # program.cue → the emitted bundle (write.ts)
COMPOSE_PROJECT_NAME=realworld-press just launch
deno run -A --unsafely-ignore-certificate-errors scripts/seed.ts
```

### The app is https-only

`https://localhost:8443/`. The door, its certificate and trusting it are
[the proxy's](../../libraries/mecha/docs/proxy.md).

### Every launch empties the database

The cluster's volumes are anonymous, so `just launch` starts from nothing.
`scripts/seed.ts` writes four writers, four readers, six pieces with real
bodies, favourites, follows and a comment thread — through the app's own doors
(`POST /auth/guest`, then `/crud` as that person under RLS), never into
Postgres. A seed that works is therefore evidence the write paths work.

`article.slug` is a GENERATED column: never post it.

### Visual lint

`just integrate` runs it in the compose `integrate` service. To run it alone
against a launched cluster, export the project name, since it shells out to
`docker compose port` in its own process:

```bash
export COMPOSE_PROJECT_NAME=realworld-press
deno run -A --unsafely-ignore-certificate-errors \
  ../../plugins/omnishell/check-visual.ts .
```

It loads each route at two viewports and **never presses anything**, so
interaction states exist only as storyboard frames. Any new arm ships with its
refusal frame in the same change — the Save arm did not, which is how two
refusals overprinting reached a human before any check saw them.

## Editing the ir

`ir.html` is pinned by hash. After editing it:

```bash
shasum -a 256 ir.html   # → meta: ir: sha256 in program.cue
```

Every object of a kind
[pronto's SPEC](../../plugins/pronto/SPEC.md#programcue) compares must appear
in **both** `ir.html` and `program.cue`, or `check-facts` fails.

## Driving it from a browser

Auth is `POST /auth/guest`; the token lives in
`sessionStorage['pronto-token']`. A `goto` clears it, so the order is: navigate,
set the token, reload.

Anything transient wants a **per-frame trace of the computed value**, never a
sample at fixed offsets. Both regressions in the counter work were invisible to
sampling and obvious in one per-frame run. And for optimistic UI the oracle is
the **converged database**, not the screen: several plausible screen-only
detectors flagged behaviour that turned out to be correct.

## Where the interesting parts are written down

- [pronto's access](../../plugins/pronto/docs/access.md#a-count-the-reader-is-inside-of)
  — the favourite counter, and why a reader inside an aggregate they cannot see
  is the hard case.
- [mecha's proxy](../../libraries/mecha/docs/proxy.md) — why there is one door
  and it is h2.

## Not started

Ideas with the shape of the work, not commitments:

- **Latest / Top / Most discussed** on home — a segmented control. Top orders by
  `article_stats.favorite_count`, which means listing ArticleStats and nesting
  the article, or a new sink. "Most discussed" needs a comment count that does
  not exist yet.
- **Comment count on the preview** — pairs with the above; the counter has to
  exist before a preview can show it.
- **Writer stats** (pieces, followers) on the profile and the writer's card —
  needs a `writer_stats` sink.
- **Related "More in {tag}"** at the article foot — a live region on the first
  tag; nesting depth is the open question.
- **Threaded replies** — `Comment.parent_id` and a nested region.
- **Drafts** — `Article.published`. Highest value, widest blast radius: it
  touches every list's filter and the editor.

Not reachable without an escape hatch, and the ir's zero-hatch decision would
have to be reopened first: live markdown preview, word count, tag autocomplete,
scroll-spy TOC, highlight-to-quote, share-to-clipboard.
