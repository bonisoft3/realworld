import { load } from "../../../plugins/omnishell/interpreter/vendor/js-yaml.js";

Deno.test("RealWorld's gated door uses guest and passkey without social credentials", async () => {
  const shell = load(await Deno.readTextFile(new URL("../shell/shell.yaml", import.meta.url)));
  if (shell.auth.required !== true || shell.auth.mode !== "passkey" || shell.auth.service !== "/auth") {
    throw new Error("the door must require authentication through the passkey-capable local auth service");
  }
  if (shell.auth.providers?.length || JSON.stringify(shell).includes("CLIENT_SECRET")) {
    throw new Error("Cloudflare's door must not offer social providers or embed credentials");
  }
});
