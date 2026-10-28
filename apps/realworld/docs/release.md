# Cloudflare release

RealWorld releases its application and database to Cloudflare Workers. The reference mirror keeps the app at `apps/realworld`; Copybara moves its generated workflow to the repository root and adjusts its working directories.

Configure `CLOUDFLARE_API_TOKEN`, `CLOUDFLARE_ACCOUNT_ID`, and a stable `JWT_SECRET` as mirror repository secrets. Missing deployment credentials fail the workflow. A plain `v*` tag or manual `cd` dispatch builds and publishes the app, then runs `sayt verify@cloudflare` against the origin returned by the publisher. A monorepo `apps/realworld/v*` tag first syncs the mirror and forwards its version tag.

Guest and passkey sessions are supported. Google sign-in is not enabled on this target. The edge runs the SQL projection drain; container development keeps its CDC workers. Favorite ownership is enforced by a SQL trigger on both tiers.

The demo migration creates six illustrated articles by three explicitly fictional authors. It creates no credentials, never overwrites an existing article, and does not recreate deleted articles on replay. Images load from Unsplash through the app's declared HTTPS image capability. New deployments import the seed; upgrades apply only unapplied migrations and preserve live user data.

[[release-journal.html|Browser evidence]] · [[../ir.html|Application contract]]
