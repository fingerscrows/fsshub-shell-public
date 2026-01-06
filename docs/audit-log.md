# Audit Log

This log records major architectural shifts, breaking changes, and discrepancies found between documentation and implementation.

## 2024-12-24 — Architecture & Documentation Drift

### Finding: Dependency Injection Myth
**Observation:** The `README.md` claimed `Shell/init.lua` used Dependency Injection (`return function(ApiClient, Session)`).
**Reality:** `Shell/init.lua` returns a table `Shell` with a `Boot()` function that takes *no arguments*. Dependencies are managed via a Global Event Bridge (`getgenv().FSSHUB_SHELL.Events`).
**Risk:** Developers (or the Loader) attempting to inject dependencies as per docs would fail.
**Action:** Updated `README.md` and `docs/architecture.md` to reflect the Event Bridge pattern.

### Finding: Fluent UI Loading Method
**Observation:** `CHANGELOG.md` stated "Integrated the full Fluent UI source code locally".
**Reality:** `Shell/init.lua` still uses `loadstring` to fetch Fluent from a GitHub release URL (`https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua`).
**Risk:** Misleading expectations about offline capability or version pinning.
**Action:** Documented the "Raw Load" mechanism in `docs/architecture.md`.
