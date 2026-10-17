# Windows system-proxy case: CUA Node runtime

Date: 2026-10-17
Status: Edge page-read recovery verified after restart; Chrome remains unverified because it was not available to the control interface. The proxy patch's causal role is not proven.

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

## Post-restart verification

- After the user restarted Codex, `cua.getState()` succeeded and exposed the Edge extension. A second state read also succeeded.
- Five actual Edge page title and DOM reads succeeded across Baidu, Cloudflare Developer Docs, Tencent Cloud's public homepage, MDN, and Mozilla.
- Chrome was not listed by `cua.getState()`; attempting to open a Chrome tab returned that Chrome was unavailable. Chrome behavior is therefore **unverified**, not failed.
- The WeCom developer site was blocked by the browser's site-safety policy before page content was read; this is not counted as a browser-control failure or successful read.

## Result and remaining uncertainty

Edge page-control recovery is verified after a full Codex restart. The original reported failure was a CDP command timeout, not the repository's canonical `nodeRepl.fetch request failed` signature. The successful post-restart reads show the current Edge path works, but do not prove that the proxy environment patch caused the recovery. If the CDP timeout returns, investigate the local browser/CDP bridge separately and retain the exact error. Cross-browser recovery remains incomplete until Chrome is exposed and tested.

Do not report the proxy patch as the proven root cause based only on HTTP 401 reachability or Node syntax validation.
