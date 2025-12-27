# DocsKeeper Audit Log

This log records major architectural shifts, security interventions, and breaking changes detected by the DocsKeeper agent.

## 2026-01-18 — Initial Audit & Documentation Creation
*   **Finding**: Repository lacked structured architecture documentation (`docs/`).
*   **Action**: Created `docs/architecture.md` to define the "Remote Control" vs "TV Box" philosophy and document the Raw Load mechanism.
*   **Risk**: `Shell/Events.lua` creates new BindableEvents on every `Init()`. If the Shell is reloaded without cleanup, this could cause memory leaks or disconnected signals in the Core. This is a known limitation.
*   **Clarification**: Confirmed that the local `Fluent/` folder is effectively dead code in production, as `Shell/init.lua` loads Fluent via `game:HttpGet`.
