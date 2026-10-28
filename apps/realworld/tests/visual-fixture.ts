const base = Deno.env.get("APP_URL");
if (!base) throw new Error("APP_URL is required");

async function json(path: string, init: RequestInit) {
  const response = await fetch(`${base}${path}`, init);
  const body = await response.text();
  if (!response.ok) throw new Error(`${path}: ${response.status} ${body}`);
  return JSON.parse(body);
}

const { token } = await json("/auth/guest", {
  method: "POST",
  headers: { "content-type": "application/json" },
  body: "{}",
});
for (const [title, created_at] of [
  ["A community of readers", "2026-01-02T12:00:00.000000Z"],
  ["A community of writers", "2026-01-01T12:00:00.000000Z"],
]) {
  await json("/crud/article", {
    method: "POST",
    headers: {
      authorization: `Bearer ${token}`,
      "content-type": "application/json",
      prefer: "return=representation",
    },
    body: JSON.stringify({ title, created_at, description: "A story for the community.", body: "A story worth reading.", tags: "community" }),
  });
}
