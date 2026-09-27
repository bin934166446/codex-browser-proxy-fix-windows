# Troubleshooting

## Patch says it cannot find `cua-repl.mjs`

Codex changed its runtime layout, the Browser/Computer Use component has not been installed yet, or this workaround no longer matches the current version. Do not guess a path. Open an issue with the Codex version and sanitized directory layout.

## Direct and proxied tests both fail

Fix the proxy/network first. This repository cannot make a dead proxy endpoint work.

## Direct and proxied tests both succeed

Your Browser Use failure may have another cause. Do not patch blindly. Check public Codex issues for Browser route, Native Messaging, IPC, runtime, or extension-specific failures.

## Proxy test returns 401 or 403

That is useful as a **reachability** signal. It does not mean you are authenticated. The diagnostic intentionally avoids using browser cookies or user tokens.

## Browser still fails after patch

Confirm all of the following:

- You patched the current Runtime, not an old one.
- You used an HTTP/mixed proxy URL, not a SOCKS-only listener.
- `node --check` passed.
- You completely exited Codex and reopened it.
- The proxy listener is still active.
- `NO_PROXY` includes `localhost,127.0.0.1,::1`.

Then collect sanitized logs and open an issue.

## Codex updated and the fix disappeared

Run the diagnostic and patch helper again. A new runtime directory is expected after some updates.
