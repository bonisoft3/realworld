import { parseHTML } from "npm:linkedom@0.18.4";
import { load } from "../../../plugins/omnishell/interpreter/vendor/js-yaml.js";
import { guestBox, localizeStrip } from "../../../plugins/omnishell/interpreter/chrome.js";

const app = new URL("../", import.meta.url);
const assert = (value: unknown, message: string) => { if (!value) throw new Error(message); };

Deno.test("RealWorld emits Google sign-in without embedding credentials or opening the gate", async () => {
  const shell = load(await Deno.readTextFile(new URL("shell/shell.yaml", app)));
  assert(shell.auth.required === true, "every route remains gated");
  assert(JSON.stringify(shell.auth.providers) === '["google"]', "Google must reach terminal chrome");
  assert(shell.auth.service === "/auth", "provider requests use the same-origin auth service");
  assert(!JSON.stringify(shell).includes("CLIENT_SECRET"), "no credential configuration belongs in browser assets");
  const compose = load(await Deno.readTextFile(new URL(".bayt/compose.auth.yaml", app)));
  const env = compose.services["realworld-auth"].environment;
  assert(env.OIDC_PROVIDERS === "google", "Google must reach the auth service");
  assert(env.OIDC_GOOGLE_CLIENT_ID.includes("OIDC_GOOGLE_CLIENT_ID is required"), "a missing client ID must fail configuration");
  assert(env.OIDC_GOOGLE_CLIENT_SECRET === "${OIDC_GOOGLE_CLIENT_SECRET:-}", "the secret is supplied at runtime");
  const build = JSON.parse(await Deno.readTextFile(new URL("bayt.json", app)));
  for (const name of ["ci", "ci-visual", "ci-replay", "ci-favorites"]) {
    assert(build.targets[name].dockerfile.defaultPreamble["google-check-client"].line ===
      "ENV OIDC_GOOGLE_CLIENT_ID=realworld-ci.apps.googleusercontent.com", "nested check drivers need their explicit fixture client");
  }
  assert(!JSON.stringify(compose).includes("realworld-ci.apps.googleusercontent.com"), "the synthetic client must not become a deployment default");
});

Deno.test("RealWorld's Google link keeps the localized route and search query", async () => {
  const shell = load(await Deno.readTextFile(new URL("shell/shell.yaml", app)));
  const { document } = parseHTML("<html><body><nav></nav></body></html>");
  const nav = document.querySelector("nav")!;
  nav.append(guestBox(document, shell));
  localizeStrip(nav, shell, { locale: "pt", here: "/pt/search", search: "?q=market", explicitLocale: true });
  const link = nav.querySelector('[data-provider="google"]')!;
  assert(link !== null, "Google has a provider action");
  const target = new URL(link.getAttribute("href")!, "https://localhost:17995");
  assert(target.pathname === "/auth/oidc/google/start", "the action reaches Mecha");
  assert(target.searchParams.get("return") === "/pt/search?q=market", "the callback retains locale and query");
});
