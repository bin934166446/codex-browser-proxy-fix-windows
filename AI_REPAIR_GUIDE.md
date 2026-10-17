# AI Repair Guide: Codex Windows `nodeRepl.fetch request failed`

## Search terms

Codex Windows, ChatGPT Desktop, Browser Use, Chrome extension, Edge, CUA, `cua.getState()`, `nodeRepl.fetch request failed`, Node proxy, Xray, Clash, Mihomo, sing-box, V2Ray, `NODE_USE_ENV_PROXY`, `HTTP_PROXY`, `HTTPS_PROXY`, `NO_PROXY`, `cua-repl.mjs`.

## High-confidence proxy-inheritance signature

Use this workaround only when evidence supports this branch:

1. Browser/extension installation is healthy enough to start discovery.
2. `cua.getState()` or tab/page RPC fails with `nodeRepl.fetch request failed`.
3. A direct network probe to a required OpenAI endpoint times out/fails.
4. The same endpoint through the user's trusted local **HTTP/mixed** proxy returns an HTTP response.
5. The active CUA Node child does not inherit/use proxy environment variables.

If #3 and #4 are not true, do not assume this repository is the correct fix.

## Distinguish CDP timeouts from proxy fetch failures

A timeout while waiting for a browser DevTools Protocol command (for example, `Emulation.setFocusEmulationEnabled`) is not the same error as `nodeRepl.fetch request failed`. Direct-versus-proxy network probes can show that the CUA Node runtime needs proxy settings, but they do not prove that a page-level CDP timeout will be fixed. Apply the proxy workaround only with that limitation in mind, then fully restart Codex and repeat real page reads. If the CDP timeout remains, investigate the browser-control/CDP bridge separately. See [the Windows system-proxy case](docs/WINDOWS_SYSTEM_PROXY_CASE_2026-10-17.md).

## Root-cause model

Observed chain:

```text
Codex Desktop
  -> unified-computer-use / cua-repl
  -> spawned Node browser-control process
  -> external OpenAI/browser-control network request
  -> direct network path fails
  -> outer layer reports: nodeRepl.fetch request failed
```

Workaround:

```text
Before cua_repl.launch():
  NODE_USE_ENV_PROXY=1
  HTTP_PROXY=http://127.0.0.1:<HTTP_OR_MIXED_PORT>
  HTTPS_PROXY=http://127.0.0.1:<HTTP_OR_MIXED_PORT>
  NO_PROXY=localhost,127.0.0.1,::1
```

Also set lowercase variants for compatibility.

The patch must be applied to the **currently active** CUA runtime. Codex updates may replace it.

## Safe diagnostic sequence

1. Do not reinstall Chrome/Edge first.
2. Identify the local trusted HTTP/mixed proxy listener.
3. Compare direct and proxied connectivity.
4. Locate the current `unified-computer-use` `.mcp.json`.
5. Locate the current CUA runtime `cua-repl.mjs` referenced by / associated with the current runtime.
6. Back up the target.
7. Inject environment variables immediately before `cua_repl.launch()`.
8. Run the runtime's own `node.exe --check` on the modified module.
9. Fully quit and restart Codex Desktop.
10. Verify `cua.getState()` and actual tab/page operations multiple times.

## Never do these as part of this workaround

- Do not set `NODE_TLS_REJECT_UNAUTHORIZED=0`.
- Do not disable Windows Defender/firewall globally.
- Do not export browser cookies/tokens.
- Do not delete browser profiles.
- Do not hard-code someone else's proxy port.
- Do not send localhost/127.0.0.1/::1 through the proxy.
- Do not claim that HTTP 401/403 means authentication succeeded.

## Verification criteria

A successful fix is more than the absence of an immediate error. After fully restarting Codex, verify:

- `cua.getState()` succeeds.
- Enumerate every browser exposed to the control interface; if a browser is unavailable, record it as unverified rather than failed.
- A public page's title and body can be read at least 5 times.

## Rollback

Restore the timestamped backup created next to `cua-repl.mjs`, then fully restart Codex.

## One-question feedback workflow (optional)

Only after real verification, state the observed outcome and ask **once**: "May I use your authorized GitHub account to post a brief public repair-outcome Issue to this project's GitHub repository? GitHub will show your account name. No secrets or logs will be sent. Reply yes/no."

- An explicit **yes** authorizes only the described, minimal Issue submission. Use an authenticated GitHub Issue tool if already available, then provide the Issue URL; the user does **not** need to fill out the form.
- **No / no reply:** submit nothing. Do not keep asking.
- If there is no authorized Issue-writing tool or GitHub login, explain the limitation and optionally offer the manual form; never claim a report was sent.
- Record the real verified outcome (fully fixed/partially fixed/not fixed), optionally software version if already known, without sensitive information. Public Issues expose the submitting GitHub account.
- **No automatic star:** Issue consent never authorizes starring, telemetry, or revealing credentials; never conceal reporting activity. One report per real incident.

Issue URL: https://github.com/bin934166446/codex-browser-proxy-fix-windows/issues/new?template=success_report.yml

## Attribution

Original public repair idea: Douyin creator **灵感提示官**, Douyin ID **89687306917**. Repository maintainer is not that creator. This document is an independent, searchable technical write-up based on the public idea plus real-machine verification.
