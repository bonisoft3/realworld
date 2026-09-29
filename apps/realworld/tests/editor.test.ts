// The editor screen mounted WHOLE — the blank sheet, the writing-as me region,
// and the publish form wired to the store.
import { assert, mountApp, type Row, textOf } from "../../../plugins/omnishell/test/screen-harness.ts";

type ValueControl = { value: string };

const APP = new URL("../", import.meta.url);
const SEED = 20250901;
const EPOCH = "2026-02-04T12:00:00.000Z";

const world = (over: Record<string, Row[]> = {}): Record<string, Row[]> => ({
  me: [{ id: "u-me", handle: "me", txid: "1" }],
  article: [],
  ...over,
});

const mountEditor = (tables: Record<string, Row[]> = world()) =>
  mountApp({
    appDir: APP,
    screen: "editor",
    seed: SEED,
    epoch: EPOCH,
    tables,
    cluster: { me: "u-me" },
  });

Deno.test({
  name: "editor mounts blank sheet and renders author from me region",
  sanitizeOps: false,
  sanitizeResources: false,
  async fn() {
    const m = await mountEditor();
    const writingAs = m.one(".writing-as bdi");
    assert(textOf(writingAs) === "me", `expected writing as "me", got "${textOf(writingAs)}"`);

    const title = m.one('input[name="title"]') as unknown as ValueControl;
    const body = m.one('textarea[name="body"]') as unknown as ValueControl;
    assert(title.value === "", "title input should be blank initially");
    assert(body.value === "", "body textarea should be blank initially");
  },
});

Deno.test({
  name: "submitting with required fields writes article to store",
  sanitizeOps: false,
  sanitizeResources: false,
  async fn() {
    const m = await mountEditor();
    const title = m.one('input[name="title"]') as unknown as ValueControl;
    const body = m.one('textarea[name="body"]') as unknown as ValueControl;
    title.value = "New Horizons";
    body.value = "Exploring offline persistence in omnichannel applications.";

    m.fire('form[data-form="publish-article"]', "submit");
    await m.settle();

    const write = m.store.calls.find((c) => c.table === "article" && (c.op === "create" || c.op === "add"));
    assert(write !== undefined, "expected article create/add store call");
    assert(write.row?.title === "New Horizons", `expected title "New Horizons", got "${write.row?.title}"`);
    assert(write.row?.body === "Exploring offline persistence in omnichannel applications.", "expected body to match");
  },
});

Deno.test({
  name: "empty submit is refused and does not reach the store",
  sanitizeOps: false,
  sanitizeResources: false,
  async fn() {
    const m = await mountEditor();
    m.fire('form[data-form="publish-article"]', "submit");
    await m.settle();

    // Regression: invalid client inputs must be rejected before entering offline transaction queue.
    const write = m.store.calls.find((c) => c.table === "article" && (c.op === "create" || c.op === "add"));
    assert(write === undefined, "empty submit must not write to store");
    assert(m.screen.getAttribute("data-state") === "validation-error", "screen should enter validation-error state");
  },
});
