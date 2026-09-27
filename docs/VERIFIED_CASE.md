# Verified real-world case

Date: 2026-09-27

This repository was assembled after a real Windows Codex Desktop failure was reproduced and repaired.

## Symptom

Browser control repeatedly failed in both Microsoft Edge and Google Chrome with:

```text
cua.getState() -> nodeRepl.fetch request failed
```

Observed at the same time:

- Chrome/Edge were running normally.
- Browser extension / Native Messaging checks were healthy.
- Basic Windows Computer Use plumbing such as `ping/list_apps` worked.
- Restarting Codex did not fix the problem.
- Reinstalling the browser extension did not address the root cause.

## Network test

The machine used a local Xray proxy:

```text
127.0.0.1:10808
```

A controlled probe to an OpenAI endpoint showed:

```text
Direct: timed out
Proxy:  HTTP 401 response
```

The `401` was intentionally treated only as proof that the network path through the proxy was reachable. It was not treated as proof of authentication.

## Patch

The active Codex CUA runtime was located from the current `unified-computer-use` plugin metadata. Immediately before `cua_repl.launch()`, the runtime was given:

```text
NODE_USE_ENV_PROXY=1
HTTP_PROXY=http://127.0.0.1:10808
HTTPS_PROXY=http://127.0.0.1:10808
NO_PROXY=localhost,127.0.0.1,::1
```

Lower-case proxy variable variants were also supplied for compatibility.

The file was backed up first and validated with the runtime's own:

```text
node.exe --check cua-repl.mjs
```

## Result after a full Codex restart

- `cua.getState()`: PASS
- Chrome tab enumeration: PASS
- Public page title/body read: PASS, repeated five times
- Existing logged-in browser tab read: PASS
- No browser cookies, passwords, tokens, or user profile data were modified

This proves the workaround for this **specific proxy-inheritance failure mode**. It does not prove that every occurrence of `nodeRepl.fetch request failed` has the same root cause.
