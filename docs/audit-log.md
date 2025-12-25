# DocsKeeper Audit Log

## 2025-12-25 — Architecture & Consistency Audit

### Findings

1.  **Unused Module (`Shell/Events.lua`)**
    *   **Status**: `Shell/Events.lua` implements a Signal class but is not required or used by `Shell/init.lua`.
    *   **Risk**: Low. It introduces no runtime overhead as it is not loaded, but represents dead code.
    *   **Action**: Documented in README as "Internal Module".

2.  **Hardcoded UI Logic**
    *   **Status**: `Shell/init.lua` manually constructs the Dashboard UI (Tabs, Buttons) and specifically hardcodes the "Launch AutoFarm" feature.
    *   **Drift**: This deviates from the V3 vision of a "Game-aware feature system" where features would ideally be resolved dynamically (via `FeatureResolver` and `UIGenerator`).
    *   **Risk**: High maintenance cost. Adding new features requires modifying the Shell code rather than just the configuration/Core.
    *   **Action**: Noted in Changelog. Recommendation: Transition to `UIGenerator` in future iterations.

3.  **Missing Core Files**
    *   **Status**: Files like `Core.lua`, `ModuleManager.lua`, etc., are absent from this repository.
    *   **Confirmation**: This is expected behavior for the **Public Shell** repository. These files belong to the Private Core.
    *   **Action**: Created `docs/architecture.md` to explicitly document this separation and the interface contract.
