# Changelog

## Unreleased

- Recorded the Edge URL-confidence safety block and verified a supported browser-tab API can read and safely interact with the already-open Edge page. This restores the webpage task path but does not repair the Windows Computer Use gate or implicate the proxy patch. See [the incident record](docs/URL_CONFIDENCE_GATE_CASE_2026-10-22.md).
- Documented a Windows case where the CUA Node runtime needs the configured system proxy, including the distinction between proxy fetch failures and browser CDP timeouts. After restart, five Edge page reads succeeded; Chrome was unavailable to the control interface, and the proxy patch's causal role remains unproven.

## 0.1.0 - 2026-09-27

- Initial public documentation.
- Added Chinese and English README files.
- Added AI-focused repair guide with exact error strings and decision tree.
- Added safe diagnostic, patch, and restore PowerShell helpers.
- Added explicit attribution to Douyin creator 灵感提示官 (ID 89687306917).
