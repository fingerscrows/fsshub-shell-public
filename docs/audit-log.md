# DocsKeeper Audit Log

## 2025-01-18 — Architecture Audit
**Finding**: `Shell/init.lua` does not follow the Dependency Injection pattern described in the original plan.
**Risk**: Documentation (`README.md`) stated it accepts `ApiClient` and `Session`, but it actually initializes its own Bridge.
**Action**: Updated `docs/architecture.md` to reflect the actual Event Bridge pattern. Updated `README.md` to match code behavior.

**Finding**: Authentication uses `TryLogin` event instead of direct `ApiClient` call.
**Risk**: This is a "Legacy" or "Remote Control" pattern. It works but adds an event hop.
**Action**: Documented this flow in `docs/architecture.md`.

**Finding**: Missing core modules (`Core.lua`, `ModuleManager.lua`) in this repository.
**Context**: This is strictly the **Public UI Shell**.
**Action**: Clarified module boundaries in `docs/architecture.md`.
