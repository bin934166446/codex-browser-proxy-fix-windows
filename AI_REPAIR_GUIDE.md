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

A successful fix is more than the absence of an immediate error. Verify:

- `cua.getState()` succeeds.
- Chrome tab enumeration succeeds.
- Edge tab enumeration succeeds if used.
- A public page's title and body can be read.
- Repeat at least 5 times.
- Fully restart Codex and repeat.

## Rollback

Restore the timestamped backup created next to `cua-repl.mjs`, then fully restart Codex.

## Attribution

Original public repair idea: Douyin creator **灵感提示官**, Douyin ID **89687306917**. Repository maintainer is not that creator. This document is an independent, searchable technical write-up based on the public idea plus real-machine verification.
