Status: archived — Cloudflare releases use guest and passkey authentication.

# Google sign-in testbed

RealWorld declares Google alongside the terminal's passkey and guest options. Every screen remains gated. Mecha handles the authorization-code redirect and token exchange; Omnishell adopts the resulting session. No Google credential belongs in `program.cue`, browser assets or source control.

## Configure

Create a **Web application** OAuth client in the Google Cloud project's Google Auth Platform, configure its consent/audience settings, and authorize the testing accounts if the project is in testing mode. Register this exact local redirect URI for the default RealWorld port:

```text
https://localhost:17995/auth/oidc/google/callback
```

For another host or port, use the actual browser origin followed by `/auth/oidc/google/callback`. Scheme, hostname, port and path must match exactly. The deployment's `ORIGIN` must agree with that browser origin; a container-internal service address is not the callback. See [Google's OpenID Connect setup](https://developers.google.com/identity/openid-connect/openid-connect#settingup).

Supply `OIDC_GOOGLE_CLIENT_ID` and `OIDC_GOOGLE_CLIENT_SECRET` in the environment of the shell launching the app. Obtain both from the OAuth client; do not use a service-account key. Keep the Google issuer preset and default scopes. Run from the monorepo root:

```sh
just sayt -d apps/realworld setup
just sayt -d apps/realworld launch
```

Trust the local development certificate as instructed by setup. Open `https://localhost:17995/`, select Google, approve the Google consent screen, and return to the app. The callback comes from the browser's origin; changing `CADDY_TLS_HOST_PORT` also requires registering the matching callback. Kubernetes releases need the same credentials in the release environment; the client secret is emitted into the dedicated OIDC Secret, not the Deployment's plain environment.

## Check the account boundary

Start at a localized route with a query, for example `/pt/search?q=market`, and confirm the callback preserves both. Confirm the identity strip and settings page load immediately: the existing `app_user` insert trigger creates `me` in the same transaction for Google, passkey and guest accounts. Create an article, sign out, sign in with the same Google account, and confirm it is still owned by that account. A different Google account must not acquire edit permissions. A guest's writing stays with its guest identity; provider sign-in does not silently merge accounts by email.

The app regression checks emitted Google configuration, runtime credential references and the provider link's return URL. It uses no real credential and cannot establish a completed Google callback. Real-provider acceptance requires the OAuth client setup above.

Disposable CI driver images set a synthetic client ID solely so nested Compose can boot the guest/passkey checks. The auth runtime still requires deployment credentials; this fixture cannot complete Google sign-in.
