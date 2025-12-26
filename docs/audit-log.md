# Audit Log

This journal tracks major architectural discoveries, risks, and interventions by DocsKeeper.

## [2025-05-20] - Architecture Audit & Cleanup

### Findings

1.  **Dependency Injection Mismatch**:
    *   **Docs**: Claimed `Shell/init.lua` accepted `ApiClient` and `Session` via dependency injection.
    *   **Code**: `Shell/init.lua` is a standalone module using `loadstring` for all dependencies and exposing a global bridge.
    *   **Action**: Updated `README.md` and `docs/architecture.md` to reflect the raw-load reality.

2.  **Dead Code Detected**:
    *   **Observation**: The `Fluent/` folder is present in the repo but completely bypassed by `Shell/init.lua`, which loads Fluent from `dawid-scripts` URL.
    *   **Action**: Documented this in `docs/architecture.md`. Marked as "Reference only".

3.  **Idempotency Risk in Events**:
    *   **Observation**: `Shell/Events.lua` creates new `BindableEvent` instances every time `Init()` is called. It does not check if they already exist in `getgenv()`.
    *   **Risk**: Re-executing the script breaks connections with the Core if the Core is already running.
    *   **Action**: Logged risk in `docs/architecture.md`.

4.  **Workflow Friction**:
    *   **Observation**: `Shell/init.lua` loads internal modules (`UI/Tabs.lua`) from `raw.githubusercontent.com`.
    *   **Impact**: Developers cannot test local changes to UI modules without pushing to main or setting up a local server.

### Status
*   Documentation now matches the "Raw Load" / "Global Bridge" architecture.
*   No code changes made (strictly auditing).
