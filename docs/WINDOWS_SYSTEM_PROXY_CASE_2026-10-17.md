# Windows system-proxy case: CUA Node runtime

Date: 2026-10-17
Status: Runtime proxy patch applied; full browser-control verification pending a Codex restart.

## Observed problem

Browser discovery returned tabs, but attempts to open/read tabs timed out. One reported failure was a timeout waiting for the Chrome DevTools Protocol command `Emulation.setFocusEmulationEnabled`. This does not match the repository's canonical `nodeRepl.fetch request failed` signature.

## Diagnostic evidence

- Windows had a loopback system proxy configured, while Codex reported no `HTTP_PROXY` or `HTTPS_PROXY` environment variables and had `respect_system_proxy` enabled.
- A direct request to `https://chatgpt.com/backend-api/me` timed out. The same request through the configured local HTTP/mixed proxy returned HTTP 401. This confirms network reachability through the proxy only; it does not authenticate a user.
- The bundled Node v24 runtime also timed out on a direct `fetch()` and received HTTP 401 when run with `NODE_USE_ENV_PROXY=1` and `HTTP_PROXY`/`HTTPS_PROXY` set to the local proxy.
- The current `cua-repl.mjs` contained the expected `await cua_repl.launch()` entry point, so the repository's runtime patch helper matched this installed layout.

## Applied workaround

Ran `scripts/Fix-CodexBrowserProxy.ps1` with the locally configured HTTP/mixed proxy. It added `NODE_USE_ENV_PROXY=1`, uppercase and lowercase `HTTP_PROXY`/`HTTPS_PROXY`, and a loopback `NO_PROXY` list immediately before `cua_repl.launch()`. The helper created a timestamped backup beside the runtime file, and the bundled Node `--check` passed.

This is a reversible runtime change. Use `scripts/Restore-CodexBrowserProxyFix.ps1` or restore the timestamped backup if rollback is needed.

## Verification boundary and next step

The proxy route and Node fetch behavior are verified. The CUA runtime file passes syntax validation. The Codex desktop process has not yet been restarted, so browser recovery is **not verified**. After fully exiting Codex, including its tray/background process, reopen it and test repeated tab enumeration and real page-title/body reads in Chrome and Edge.

If those reads work, record the result as fixed. If `Emulation.setFocusEmulationEnabled` still times out, keep this proxy workaround only if other CUA network calls need it, and investigate the local browser/CDP bridge as a separate failure. Do not report a CDP timeout as fixed based only on HTTP 401 reachability or Node syntax validation.
