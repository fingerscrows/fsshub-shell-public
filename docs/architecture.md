# FSSHUB V3 - Architecture

## Overview
FSSHUB V3 follows a split "Remote Control" architecture.

*   **Public Shell (Remote Control)**: This repository. Strictly UI logic (Buttons, Toggles, Key Input). Stateless.
*   **Private Core (TV Box)**: Hosted privately. Contains logic, security, obfuscation, and API handlers.

## Integration Flow

### 1. Initialization
The Shell is loaded via a raw `loadstring` by the Core (Loader).
It does **NOT** accept injected dependencies (`ApiClient`, `Session`). instead, it creates a `BindableEvent` bridge.

### 2. Communication (The Bridge)
`Shell/Events.lua` creates a set of `BindableEvent` instances.
*   `Shell -> Core`: `ToggleFeature(id, state)`, `TryLogin(key)`
*   `Core -> Shell`: `AuthResult(success, msg)`, `FeatureState(id, state)`, `Notification(title, msg)`

### 3. Authentication
1.  User inputs key in Shell.
2.  Shell fires `TryLogin(key)`.
3.  Core receives event, calls `ApiClient.Authenticate(key)`.
4.  Core fires `AuthResult` back to Shell.
5.  Shell unlocks Dashboard if success.

### 4. Feature Toggles
1.  User clicks Toggle.
2.  Shell fires `ToggleFeature(id, state)`.
3.  Core receives event, calls `ApiClient.RequestFeature(id)`.
4.  If API fails or Logic fails, Core fires `FeatureState(id, oldState)` to revert UI.

## Module Boundaries

| Module | Responsibility | Access |
| :--- | :--- | :--- |
| `Shell/init.lua` | Main Entry, Auth Window, Bridge Creation | Public |
| `Shell/Events.lua` | Signal Factory (BindableEvents) | Public |
| `Shell/UI/Tabs.lua` | Dashboard & Universal Tab Content | Public |
| `Core` | Game Logic, API Communication, Security | **Private** |

## Data Flow
**Core** is the source of truth. The Shell merely reflects the state of the Core.
UI Toggles are optimistic but revertible via `FeatureState` event.
