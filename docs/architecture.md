# FSSHUB V3 Architecture

## Overview

FSSHUB V3 follows a split "TV Box vs Remote Control" architecture.

*   **Core (TV Box)**: Private, obfuscated, logic-heavy. Handles game interactions, anti-cheat, and API calls.
*   **Shell (Remote Control)**: Public, open-source, logic-free. Strictly visual interface.

This repository holds the **Public Shell**.

## Current Implementation

### 1. Loading Mechanism: "Raw Load"

Contrary to initial plans for local modularity, the Shell currently uses `loadstring(game:HttpGet(...))` to fetch its dependencies.

*   **Fluent UI**: Fetched from `dawid-scripts/Fluent` releases.
*   **Internal Modules**: `Events.lua`, `UI/Tabs.lua` are fetched from the raw GitHub content of *this* repository (`fsshub-shell-public`).
    *   **Implication**: Local changes to `Shell/UI/*.lua` files will not be reflected when running `Shell/init.lua` unless the `REPO` variable is manually pointed to a localhost server or the changes are pushed to `main`.

### 2. The Global Bridge

The Shell exposes itself to the Core via a global table:

```lua
getgenv().FSSHUB_SHELL = {
    Events = { ... }, -- Table of BindableEvents
    Instance = Window -- The Fluent Window instance
}
```

### 3. Event-Driven Communication ("Dumb UI")

The Shell contains **zero** game logic. It communicates purely via events.

*   **Outgoing (`ToggleFeature`)**:
    *   When a user clicks a toggle, the Shell fires `ToggleFeature` with `(featureId, state)`.
    *   The Core listens to this event and executes the actual code.
*   **Incoming (`FeatureState`)**:
    *   If the Core changes a feature state (e.g., auto-disable due to death), it fires `FeatureState`.
    *   The Shell listens to this and visually updates the toggle (without re-firing the outgoing event).

### 4. Sandbox Constraints

*   **No File System**: The Shell does not use `writefile` or `readfile` for logic (except for `SaveManager` config).
*   **No HTTP Headers**: The Shell does not make authenticated API calls. All API interaction is delegated to the Core (though currently not injected, see "Drift" below).

## Architectural Drift & Known Issues

### Dependency Injection Reverted
*   **Design**: `Shell` module should return `function(ApiClient, Session)`.
*   **Reality**: `Shell` returns a table with `Boot()`. It assumes the Core will find the events via `getgenv()`.

### Idempotency Risk
*   `Shell/Events.lua` creates new `BindableEvent` instances on every `Init`.
*   **Risk**: If the Shell is reloaded (e.g., user re-executes the script), new Event instances are created. The Core (if already running) will still be holding references to the *old* events, breaking communication.
*   **Mitigation**: Core must re-acquire `getgenv().FSSHUB_SHELL.Events` periodically or listen for a reload signal.

### Dead Code
*   The `Fluent/` directory in this repo is currently **unused** by the runtime `Shell/init.lua`. It serves as a static reference or potential future local compilation source.
