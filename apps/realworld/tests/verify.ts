import { airlock } from "../../../plugins/pronto/verify/airlock.ts";
import type { JourneyItem } from "../../../plugins/pronto/verify/browser-sweep.ts";

type Seed = { slug: string; title: string; created_at: string; author_id: string; handle: string; tag: string };
let seed: Seed;

async function navigate(page: any, base: string, path: string, screen: string) {
  const response = await page.goto(`${base}${path}`, { waitUntil: "domcontentloaded", timeout: 45_000 });
  if (!response || response.status() !== 200) throw new Error(`${screen}: navigation failed`);
  await ready(page, screen);
}

async function ready(page: any, screen: string) {
  await page.waitForFunction((name: string) => {
    const shell = document.querySelector("#app .shell-screen:not([hidden])");
    if (!shell || shell.hasAttribute("data-served") || shell.hasAttribute("data-entering")) return false;
    const view = shell.querySelector(".screen");
    if (!view || view.getAttribute("data-screen") !== name) return false;
    if (view.getAttribute("data-state") === "network-error") throw new Error("screen reported network-error");
    return view.getAttribute("data-state") !== "loading" && !view.querySelector("[data-hydrating], [data-state='loading']");
  }, screen, { timeout: 45_000 });
}

async function readRows(page: any, base: string, path: string, token: string) {
  const response = await page.request.get(`${base}/crud/${path}`, { headers: { Authorization: `Bearer ${token}` } });
  if (!response.ok()) throw new Error(`fixture read failed: ${response.status()}`);
  return await response.json();
}

const home: JourneyItem = {
  screen: "home",
  async run(page, ctx) {
    const base = String(ctx?.baseUrl);
    const response = await page.goto(`${base}/`, { waitUntil: "domcontentloaded" });
    if (!response || response.status() !== 200) throw new Error("home: navigation failed");
    await page.locator(".login-guest").click();
    await ready(page, "home");
    const session = await page.evaluate(() => JSON.parse(sessionStorage.getItem("pronto-token") ?? "null"));
    if (!session?.token || !session.user?.guest) throw new Error("guest sign-in did not establish a session");
    const articles = await readRows(page, base, "article?select=id,slug,title,created_at,author_id&id=eq.d3b00001-0000-4000-8000-000000000001", session.token);
    const article = articles[0];
    if (!article?.slug || !article?.title || !article?.created_at || !article?.author_id) throw new Error("no seeded article to verify");
    const authors = await readRows(page, base, `app_user?select=handle&id=eq.${encodeURIComponent(article.author_id)}`, session.token);
    const tags = await readRows(page, base, `article_tag?select=tag&article_id=eq.${encodeURIComponent(article.id)}&limit=1`, session.token);
    if (!authors[0]?.handle || !tags[0]?.tag) throw new Error("seeded article lacks its author or a tag");
    seed = { ...article, handle: authors[0].handle, tag: tags[0].tag };
    await page.locator(".screen[data-screen=home] .preview-title").first().waitFor({ state: "visible", timeout: 45_000 });
  },
};

const pathJourney = (screen: string, path: () => string, witness?: () => string): JourneyItem => ({
  screen,
  async run(page, ctx) {
    if (!seed) throw new Error("home did not resolve the seed");
    await navigate(page, String(ctx?.baseUrl), path(), screen);
    if (witness) await page.getByText(witness(), { exact: true }).first().waitFor({ state: "visible", timeout: 45_000 });
  },
});
const enc = encodeURIComponent;

const edit = airlock<{ id: string; token: string; base: string }>({
  screen: "edit-article",
  accepts: "accept-edit-own-article",
  async execute(page, ctx) {
    const base = String(ctx?.baseUrl);
    const session = JSON.parse(String(ctx?.token));
    if (!session?.token) throw new Error("edit requires the guest session");
    const state = { id: crypto.randomUUID(), token: session.token, base };
    ctx?.recordState?.(state);
    const created = await page.request.post(`${base}/crud/article`, {
      headers: { Authorization: `Bearer ${state.token}`, "Content-Type": "application/json", Prefer: "return=representation" },
      data: { id: state.id, title: "Verification draft", body: "A temporary piece for the edit journey." },
    });
    if (!created.ok()) throw new Error(`fixture create failed: ${created.status()}`);
    await navigate(page, base, `/editor/${state.id}`, "edit-article");
    const title = page.locator('[data-form="revise-article"] input[name="title"]');
    await title.waitFor({ state: "visible", timeout: 45_000 });
    if (await title.inputValue() !== "Verification draft") throw new Error("editor did not load the guest's article");
    await title.fill("Verification revision");
    await page.locator('[data-form="revise-article"] button[type="submit"]').click();
    await page.waitForFunction(() => document.querySelector('[data-form="revise-article"] input[name="title"]')?.getAttribute("value") === "Verification revision" || document.querySelector(".landing-title")?.textContent === "Verification revision", undefined, { timeout: 45_000 });
    let saved = false;
    for (let attempt = 0; attempt < 40; attempt++) {
      const rows = await readRows(page, base, `article?select=title&id=eq.${state.id}`, state.token);
      if (rows[0]?.title === "Verification revision") { saved = true; break; }
      await new Promise((resolve) => setTimeout(resolve, 250));
    }
    if (!saved) throw new Error("editor did not persist the revision");
    return state;
  },
  async rollback(state) {
    if (!state) return;
    const response = await fetch(`${state.base}/crud/article?id=eq.${state.id}`, { method: "DELETE", headers: { Authorization: `Bearer ${state.token}` } });
    if (!response.ok) throw new Error(`fixture cleanup failed: ${response.status}`);
    const check = await fetch(`${state.base}/crud/article?select=id&id=eq.${state.id}`, { headers: { Authorization: `Bearer ${state.token}` } });
    if (!check.ok || (await check.json()).length !== 0) throw new Error("fixture article remains after cleanup");
  },
});

export const journeys = [
  home,
  pathJourney("feed", () => "/feed"),
  pathJourney("reading-list", () => "/reading-list"),
  pathJourney("editor", () => "/editor"),
  pathJourney("settings", () => "/settings"),
  pathJourney("older", () => `/older/${enc(seed.created_at)}`),
  pathJourney("feed-older", () => `/feed/older/${enc(seed.created_at)}`),
  pathJourney("article", () => `/article/${enc(seed.slug)}`, () => seed.title),
  edit,
  pathJourney("profile", () => `/profile/${enc(seed.handle)}`),
  pathJourney("profile-favorites", () => `/profile/${enc(seed.handle)}/favorites`),
  pathJourney("tag", () => `/tag/${enc(seed.tag)}`, () => seed.title),
  pathJourney("search", () => `/search/${enc("wonder")}`, () => seed.title),
];
