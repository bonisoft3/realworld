// Seeds a fresh realworld cluster with a community worth reading.
//
//   deno run -A --unsafely-ignore-certificate-errors scripts/seed.ts [base]
//
// Run it after every `just launch`: the cluster's volumes are anonymous, so a
// relaunch starts from an empty database (see CONTRIBUTING.md).
//
// Every write goes through the app's own doors: /auth/guest mints the person,
// /crud writes as that person under RLS. Nothing touches Postgres directly, so
// a seed that works here is proof the write paths work.

const BASE = Deno.args[0] ?? "https://localhost:8443";

type Person = { token: string; id: string; handle: string };

async function guest(): Promise<Person> {
  const r = await fetch(`${BASE}/auth/guest`, { method: "POST" });
  if (!r.ok) throw new Error(`guest: ${r.status} ${await r.text()}`);
  const j = await r.json();
  const claims = JSON.parse(atob(j.token.split(".")[1]));
  return { token: j.token, id: claims.sub, handle: j.user?.handle ?? claims.handle };
}

async function crud(p: Person, method: string, path: string, body?: unknown) {
  const r = await fetch(`${BASE}/crud${path}`, {
    method,
    headers: {
      "content-type": "application/json",
      authorization: `Bearer ${p.token}`,
      prefer: "return=representation",
    },
    body: body === undefined ? undefined : JSON.stringify(body),
  });
  const text = await r.text();
  if (!r.ok) throw new Error(`${method} ${path}: ${r.status} ${text}`);
  return text ? JSON.parse(text) : null;
}

const uuid = () => crypto.randomUUID();

const WRITERS = [
  {
    key: "tobias",
    name: "Tobias Wren",
    bio: "Compiler engineer. Long essays about type systems and why your build is slow.",
    face: "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=200&h=200&fit=crop",
  },
  {
    key: "marguerite",
    name: "Marguerite Oyelaran",
    bio: "Cities, curb space, and the arithmetic nobody runs before pouring concrete.",
    face: "https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200&h=200&fit=crop",
  },
  {
    key: "chidi",
    name: "Chidi Okonkwo",
    bio: "Reading twice, writing once. Attention as a practice rather than a resource.",
    face: "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200&h=200&fit=crop",
  },
  {
    key: "nell",
    name: "Nell Abarca",
    bio: "Cooks on weeknights. Writes about the gap between the recipe and the Tuesday.",
    face: "https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=200&h=200&fit=crop",
  },
];

const PIECES = [
  {
    by: "tobias",
    title: "Types are a budget, not a bureaucracy",
    description: "Every type you write is spent attention. The question is whether it buys more than it costs.",
    cover: "https://images.unsplash.com/photo-1470071459604-3b5ec3a7fe05?w=1200&q=70",
    tags: "craft engineering types",
    body: `The tiresome argument about static types treats them as a moral question. They are not. They are a budget, and like every budget the interesting question is not whether to have one but what you are buying with it.

## The exchange rate

A type annotation costs you the moment you write it and every moment you refactor it. It buys you a class of errors you never see, a refactor you can do without fear, and an editor that can answer questions.

Whether that trade is good depends entirely on **how long the code lives and how many people touch it**. A script you run twice does not need a type system. A codebase forty people share does not survive without one.

The fights happen because people are arguing about different codebases.

## Where types pay best

1. **Boundaries.** The edge of a module, a service, a file format. This is where types repay most because it is where assumptions go to die.
2. **Things with many states.** A sum type that makes the impossible state unrepresentable saves more than any amount of interior annotation.
3. **Code you are about to change.** Types are a refactoring tool first and a correctness tool second.

## Where they mostly do not

Interior plumbing that one person wrote and one person maintains, with inference doing the work. Annotating every local binding is spending the budget on a place where nothing was ever going to go wrong. Use \`auto\`, use inference, and save the ink.

> Type the doors. Infer the hallways.

## The honest cost

The cost people underestimate is not writing types. It is *fighting* them — the afternoon lost to expressing something the checker has no vocabulary for. That afternoon is real and it is the entire case for gradual typing, which is a way of declaring bankruptcy on a small region without abandoning the currency.

Spend where the assumptions are. Infer where they are not. That is the whole discipline.`,
  },
  {
    by: "marguerite",
    title: "Curb space is the most valuable land nobody prices",
    description: "A parking spot in a dense city is prime real estate rented for the cost of a coffee.",
    cover: "https://images.unsplash.com/photo-1449824913935-59a10b8d2000?w=1200&q=70",
    tags: "cities policy transit",
    body: `Stand on any street in a dense city and count the square metres. Then count what each one earns.

## The arithmetic

A parking space is roughly twelve square metres. In a neighbourhood where floor space rents for forty a month per square metre, that spot is sitting on nearly five hundred a month of land value — and the city charges two euros a day for it, when it charges anything at all.

This is not a subsidy anyone voted for. It is a subsidy that happened because nobody ran the numbers on the ground beneath the paint.

## What the price does

Pricing curb space is not about revenue. It is about *turnover*. An unpriced spot is occupied by whoever got there first and has nowhere better to be. A priced one is occupied by whoever needs it most in the next hour.

> The point of a price is not to collect it. It is to answer a question nobody else can answer for you.

## The objection worth taking seriously

The people who park there are not rich, and a price is a tax on them. True, and answerable: return the money to the neighbourhood. San Francisco and Pasadena both did this and the politics survived, because a price that funds the street it is charged on stops reading as extraction.

The cities that fail at this are the ones that price the curb and send the money downtown.`,
  },
  {
    by: "chidi",
    title: "On rereading",
    description: "The second reading is the first one where you are actually present.",
    cover: "https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=1200&q=70",
    tags: "attention craft reading",
    body: `The first time through a good book you are doing something closer to reconnaissance than reading. You are finding out what happens.

## What the first pass is for

Plot, shape, argument. Where it is going. You cannot attend to a sentence while you are still asking what the paragraph is for, and you cannot ask what the paragraph is for while you still want to know how it ends.

So the first pass spends itself on suspense, which is the cheapest thing a book has.

## What the second pass finds

Everything the writer did on purpose. The word chosen over its four neighbours. The scene planted eighty pages before it pays. The argument that was there the whole time under the one you noticed.

> Suspense is a tax the first reading pays and the second one gets refunded.

There is a kind of reader who thinks rereading is inefficient — that with so many unread books, going back is a waste. That reader is optimising for books finished, which is a number, not an experience.

## A practice

Keep five books you will reread. Not favourites: books that were slightly beyond you. Return to one each year and notice that it has changed, which is how you find out that you have.`,
  },
  {
    by: "nell",
    title: "What people actually eat on Tuesdays",
    description: "Recipe writing is aspirational. Tuesday is not. Here is what closes the gap.",
    cover: "https://images.unsplash.com/photo-1466637574441-749b8f19452f?w=1200&q=70",
    tags: "cooking everyday food",
    body: `Almost every recipe is written for a Saturday. It assumes an unhurried hour, a full pantry, and a cook who wants to be cooking.

## The Tuesday constraint

Twenty-five minutes. One pan you are willing to wash. Whatever is in the fridge, which is never what the recipe opens with. And a person who is hungry now and would rather be sitting down.

Recipes that ignore this are not wrong, they are simply for a different day, and the gap between the two is where most home cooking quietly dies.

## What survives contact

- **A fat, an allium, an acid.** Almost everything good starts here and most weeknight failures are a missing acid.
- **One texture that is not soft.** Toasted crumbs, a raw herb, anything with an edge. It is the difference between dinner and mush.
- **Salt earlier than feels right.** Seasoning at the end seasons the surface.

> A weeknight recipe should survive missing one ingredient. If it does not, it is a weekend recipe wearing a disguise.

## The actual answer

Learn four things by heart and vary them forever. Not because variety is bad, but because a repertoire you can cook without reading is the only repertoire you will cook on a Tuesday.`,
  },
  {
    by: "tobias",
    title: "Your build is slow because it is honest",
    description: "Incrementality is a lie we tell about dependency graphs, and it is usually a load-bearing one.",
    cover: "https://images.unsplash.com/photo-1518791841217-8f162f1e1131?w=1200&q=70",
    tags: "builds compilers engineering",
    body: `Every fast build is fast because it skipped something. The only question is whether it was right to.

## What incrementality actually claims

That the output of a step depends on a knowable set of inputs, and that if none changed, the previous output is still correct. Both halves are assumptions, and the first one is where the bodies are.

Environment variables. The clock. A file the compiler read that nobody declared. The version of a tool that was upgraded under you. Each is an undeclared input and each one turns a cache hit into a wrong answer that looks like a fast answer.

> A build system's speed is a claim about its dependency graph, and most graphs are lying.

## Why the honest build is slow

Because the honest build declares everything, hashes everything, and cannot skip a step it cannot prove is unaffected. Hermeticity is not free — it costs you every input you were previously getting away with not naming.

The trade is that a slow honest build is the same on your machine and on the machine that ships. A fast dishonest one is a coin flip you run a hundred times a day.

## What to actually do

Do not make the build faster by removing declarations. Make it faster by *shrinking* the things that change: smaller modules, fewer wide dependencies, and a cache that is shared rather than local. Speed you buy by cutting the graph is speed you refund with interest at three in the morning.`,
  },
  {
    by: "marguerite",
    title: "The bus that comes every seven minutes",
    description: "Frequency is the only transit feature that matters, and almost nobody measures it.",
    cover: "https://images.unsplash.com/photo-1544620347-c4fd4a3d5957?w=1200&q=70",
    tags: "cities measurement transit",
    body: `Ask a city what its transit is like and it will tell you about coverage: how many kilometres of line, how many stops, how much of the population lives within four hundred metres of one.

## The wrong number

Coverage is easy to measure and easy to build, which is why it is the number cities report. It is also nearly useless on its own. A stop you can walk to in four minutes and then wait at for twenty-five is not transit. It is a bench.

## The right one

Frequency. The moment a line comes often enough that you stop consulting a timetable, it changes category — from a thing you plan around to a thing you use. Every rider knows where that threshold is, and it is somewhere near ten minutes.

> Below ten minutes you have a network. Above it you have a set of appointments.

## Why it is rarely built

Frequency costs operating money forever; coverage costs capital money once, and capital money comes with a ribbon to cut. A new line photographs well. Six more buses on an existing one photographs like nothing at all.

## What to measure instead

Publish the share of residents within walking distance of a line running every ten minutes or better, all day, seven days. It is one number, it is hard to game, and it will embarrass almost every city that computes it honestly.`,
  },
];

// ---- run --------------------------------------------------------------

console.log(`seeding ${BASE}`);

const people: Record<string, Person> = {};
for (const w of WRITERS) {
  const p = await guest();
  await crud(p, "PATCH", `/app_user?id=eq.${p.id}`, {
    display_name: w.name,
    bio: w.bio,
    image_url: w.face,
  });
  people[w.key] = p;
  console.log(`  writer ${w.name} → ${p.handle}`);
}

// Two readers who favourite and follow but write nothing — a community needs
// an audience or every count reads as self-congratulation.
const readers: Person[] = [];
for (let i = 0; i < 4; i++) readers.push(await guest());

const articles: { id: string; slug: string; by: string }[] = [];
const DAY = 86_400_000;
const base = Date.parse("2026-08-06T09:00:00Z");
for (const [i, piece] of PIECES.entries()) {
  const p = people[piece.by];
  const id = uuid();
  // slug is a generated column (title + the uuid's first hex group); the seed
  // recomputes it only to print a link, and never sends it.
  const slug = piece.title.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "")
    .slice(0, 80).replace(/-$/, "") + "-" + id.slice(0, 8);
  await crud(p, "POST", "/article", {
    id,
    title: piece.title,
    description: piece.description,
    body: piece.body,
    cover_url: piece.cover,
    tags: piece.tags,
    created_at: new Date(base - i * DAY - i * 3_600_000).toISOString(),
  });
  articles.push({ id, slug, by: piece.by });
  console.log(`  piece  ${piece.title}`);
}

// Favourites: the lead pieces get the most, so "top" is a real ordering.
const weights = [5, 6, 3, 2, 4, 3];
for (const [i, a] of articles.entries()) {
  const crowd = [...readers, ...Object.values(people)].filter((p) => p.id !== people[a.by].id);
  for (const p of crowd.slice(0, weights[i])) {
    await crud(p, "POST", "/favorite", { id: uuid(), article_id: a.id });
  }
}

// Follows, so Your Feed has something in it for the writers themselves.
const follows: [string, string][] = [
  ["tobias", "marguerite"], ["tobias", "chidi"],
  ["marguerite", "tobias"], ["chidi", "nell"], ["nell", "marguerite"],
];
for (const [a, b] of follows) {
  await crud(people[a], "POST", "/follow", { id: uuid(), followed_id: people[b].id });
}
for (const r of readers) {
  for (const w of ["tobias", "marguerite"]) {
    await crud(r, "POST", "/follow", { id: uuid(), followed_id: people[w].id });
  }
}

// Saves. Private per reader, so these only show on the saver's own list —
// tobias is the account most QA runs sign into by handle, so he gets three.
const SAVES: [string, number[]][] = [
  ["tobias", [1, 2, 5]],
  ["marguerite", [0, 4]],
  ["chidi", [0]],
  ["nell", [1]],
];
for (const [who, idx] of SAVES) {
  for (const i of idx) {
    await crud(people[who], "POST", "/bookmark", { id: uuid(), article_id: articles[i].id });
  }
}
for (const [n, r] of readers.entries()) {
  await crud(r, "POST", "/bookmark", { id: uuid(), article_id: articles[n % articles.length].id });
}

const CONVERSATION: [number, string, string][] = [
  [0, "marguerite", "“Type the doors, infer the hallways” is going straight into our onboarding doc."],
  [0, "chidi", "The gradual-typing-as-bankruptcy metaphor does a lot of work here."],
  [0, "tobias", "Steal it. That is what it is for."],
  [1, "tobias", "The turnover argument is the one that convinces engineers. Revenue never does."],
  [1, "nell", "Pasadena is the example I keep coming back to as well."],
  [2, "nell", "Five books you will reread. I am stealing the practice, not just the idea."],
  [4, "chidi", "“A slow honest build is the same on your machine and on the machine that ships.” Yes."],
  [5, "tobias", "Every ten minutes is exactly where it flipped for me when I stopped owning a car."],
];
for (const [ai, who, body] of CONVERSATION) {
  await crud(people[who], "POST", "/comment", {
    id: uuid(),
    article_id: articles[ai].id,
    body,
  });
}

console.log(`\ndone — ${articles.length} pieces, ${WRITERS.length} writers, ${readers.length} readers`);
console.log(`open ${BASE}/article/${articles[0].slug}`);
