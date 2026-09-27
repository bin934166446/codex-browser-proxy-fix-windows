# Codex Browser Proxy Fix for Windows

A community workaround for a Windows Codex / ChatGPT Desktop Browser Use failure where Chrome, Edge, or the in-app browser may be detected but browser-control calls fail with:

```text
nodeRepl.fetch request failed
```

This project documents a reproducible proxy-inheritance failure mode and provides conservative PowerShell helpers to diagnose, patch, and restore the active Codex CUA (`cua-repl`) runtime.

> **Not an official OpenAI fix.** Codex updates can replace the runtime and remove the patch. Use only a trusted local HTTP/mixed proxy that you are authorized to use.

## When this workaround is relevant

Typical symptoms:

- Windows Codex Desktop can see Chrome/Edge or the browser extension is installed correctly.
- Native Messaging / basic computer-control plumbing appears healthy.
- `cua.getState()`, tab enumeration, or page operations fail with `nodeRepl.fetch request failed`.
- Direct access from the CUA Node process to required OpenAI endpoints times out or fails.
- The same endpoint is reachable through a local HTTP/mixed proxy such as Xray, Clash/Mihomo, sing-box, or V2Ray.

This workaround is **not** a universal fix for every `nodeRepl.fetch request failed`. Other root causes exist. Run the diagnostic first.

## Verified mechanism

Node.js can use `HTTP_PROXY`, `HTTPS_PROXY`, and `NO_PROXY` when environment-proxy support is enabled. Modern Node versions support `NODE_USE_ENV_PROXY=1` / `--use-env-proxy`.

In the reproduced Windows failure, the Codex CUA runtime did not effectively pass the local proxy environment to the Node browser-control child process. Injecting the proxy variables immediately before `cua_repl.launch()` allowed the spawned process to inherit them. After a full Codex restart, `cua.getState()`, Chrome tab enumeration, and page reading recovered.

## Quick start

Open PowerShell **without Administrator rights unless your installation specifically requires it**.

### 1. Diagnose

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\scripts\Diagnose-CodexBrowserProxy.ps1 -ProxyUrl http://127.0.0.1:10808
```

Replace `10808` with your own local **HTTP/mixed proxy** port.

A useful signal is:

- direct request: timeout/failure
- proxied request: receives any normal HTTP response (for example 401/403)

A 401/403 only proves network reachability; it does **not** prove authentication.

### 2. Apply the patch

```powershell
.\scripts\Fix-CodexBrowserProxy.ps1 -ProxyUrl http://127.0.0.1:10808 -Apply
```

The script:

1. Finds the currently active `unified-computer-use` plugin metadata.
2. Finds the active/latest CUA runtime `cua-repl.mjs`.
3. Creates a timestamped backup.
4. Injects only the proxy environment block before `cua_repl.launch()`.
5. Runs `node --check` against the modified module.
6. Restores automatically if syntax validation fails.

### 3. Fully restart Codex

Do **not** only open a new chat. Fully exit Codex, including its tray/background process, then reopen it.

### 4. Verify

Test in this order:

```text
cua.getState()
list Chrome/Edge tabs
read a public page title/body
repeat several times
```

If Browser Use works after restart, the proxy-inheritance failure mode was likely involved.

## Restore

```powershell
.\scripts\Restore-CodexBrowserProxyFix.ps1
```

The restore helper locates the newest timestamped backup next to the patched runtime and restores it.

## Important limitations

- Codex updates may create a new CUA runtime path, so the patch can disappear after an update.
- The exact runtime path varies by Codex version. Do not copy another person's absolute path.
- The proxy port is machine-specific. Do not blindly copy `10808`, `7890`, `7897`, or any other example port.
- Keep `localhost,127.0.0.1,::1` in `NO_PROXY` so local IPC/browser-control traffic does not get sent through the external proxy.
- Use an HTTP/HTTPS-compatible local proxy endpoint. SOCKS-only endpoints are not what this helper is designed for.
- This repository does not disable TLS verification, browser security, Windows security, or Codex sandboxing.

## Verified real-world case

See [docs/VERIFIED_CASE.md](docs/VERIFIED_CASE.md) for the sanitized 2026-09-27 reproduction and successful repair.

## Human-readable guide

See [docs/HUMAN_GUIDE.md](docs/HUMAN_GUIDE.md).

## AI / LLM quick diagnosis

See [AI_REPAIR_GUIDE.md](AI_REPAIR_GUIDE.md). It intentionally contains the exact error strings, decision tree, safe patch point, verification criteria, and rollback instructions so coding assistants can quickly locate the fix.

## Source / credit

The original public repair idea was learned from a Douyin tutorial by:

- **Creator:** 灵感提示官
- **Douyin ID:** `89687306917`

The maintainer of this repository is **not** that Douyin account and is not claiming authorship of the original repair discovery. This repository independently organizes the publicly demonstrated idea into searchable documentation, diagnostics, rollback guidance, and helper scripts, with additional real-machine verification.

If the original creator wants the credit wording adjusted, please open an issue.

## Related public reports

The `nodeRepl.fetch request failed` symptom has multiple public Codex reports, including proxy-related reproductions. This project covers only the proxy-inheritance variant.

## License

MIT for the original documentation and helper scripts in this repository. The credit above refers to the public repair idea; no third-party video, transcript, or proprietary code is redistributed here.

## Technical references

- Node.js built-in environment proxy support (`NODE_USE_ENV_PROXY`, `HTTP_PROXY`, `HTTPS_PROXY`, `NO_PROXY`): https://nodejs.org/api/cli.html#--use-env-proxy
- Node.js built-in proxy support details: https://nodejs.org/api/http.html#built-in-proxy-support
- Public Codex issue with the same Windows/proxy workaround family: https://github.com/openai/codex/issues/44364
- Other `nodeRepl.fetch request failed` Windows reports show that this error can have additional causes: https://github.com/openai/codex/issues/47123
