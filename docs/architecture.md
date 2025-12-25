# Blueprint Arsitektur V3

This document outlines the architectural design of **FSSHUB V3**, specifically the separation between the **Public Shell** and the **Private Core**.

## 1. High-Level Architecture

The system is divided into two distinct repositories to maintain security and modularity:

1.  **Public Shell (`fsshub-shell-public`)**:
    *   **Role**: purely visual interface (UI).
    *   **State**: Stateless (except for cosmetic settings).
    *   **Visibility**: Open Source.
    *   **Responsibility**: Rendering the Dashboard, handling user input, and displaying status.
    *   **Dependencies**: Requires `ApiClient` and `Session` to be injected at runtime.

2.  **Private Core**:
    *   **Role**: Business logic, game-specific features, and security handling.
    *   **Visibility**: Private / Obfuscated.
    *   **Responsibility**: Authenticating users, fetching feature scripts, and executing game logic.
    *   **Modules**: `Loader.lua`, `Core.lua`, `ModuleManager.lua`, `FeatureRegistry.lua`, `FeatureResolver.lua`, `UIGenerator.lua`.

## 2. Dependency Injection Contract

The Public Shell entry point (`Shell/init.lua`) exports a function that **must** be called with the following dependencies:

```lua
-- Shell/init.lua
return function(ApiClient, Session)
    -- ...
end
```

### 2.1 ApiClient Protocol
The `ApiClient` is responsible for all network communication. Direct HTTP requests (`game:HttpGet`, `request`, etc.) are **strictly prohibited** within the Shell to ensure all traffic goes through the managed proxy.

**Method:** `ApiClient.RequestFeature(featureId: string)`

**Returns:** `(networkOk: boolean, data: table)`

**Response Schema (`data`):**
| Field | Type | Description |
| :--- | :--- | :--- |
| `status` | `integer` | HTTP-like status code. |
| `chunk` | `string` | (Optional) The Lua bytecode/source to execute if status is 200. |

**Status Codes:**
*   **`200` (OK)**: Request successful. Feature script is provided in `data.chunk`.
*   **`401` (Unauthorized)**: Session expired. UI should prompt re-injection.
*   **`403` (Forbidden)**: User does not have the required tier (e.g., Free vs Premium).
*   **`500+` (Error)**: Server or generic error.

### 2.2 Session Object
The `Session` object provides user session metadata.

**Properties:**
*   `Expire`: `integer` (Unix Timestamp) - When the current session token expires.

## 3. Sandboxing & Security

### 3.1 Execution Environment
When the Shell receives code from the Core (via `ApiClient`):
*   It **must** be executed within a `task.spawn` block to prevent yielding the UI thread.
*   It **must** be restricted to a local scope.
*   It **must NOT** assign values to global environments (`getgenv`, `shared`, `_G`).

### 3.2 State Management
*   **Cosmetic Settings**: Theme, Window Position, and Keybinds are managed by `SaveManager` and stored locally.
*   **Feature State**: Game features (e.g., AutoFarm enabled) are **stateless** in the UI. They must default to `OFF` when the script reloads. `SaveManager` is configured to ignore these indexes.

## 4. Module Boundaries

### Shell (Public)
*   `Shell/init.lua`: Main dashboard logic.
*   `Shell/Events.lua`: Signal implementation (currently available for internal use).
*   `Fluent/`: The UI Library source.

### Core (Private - External)
*   `Loader`: Bootstrapper that initializes `ApiClient` and `Session`, then requires the Shell.
*   `ModuleManager`: Manages the lifecycle of loaded features.
*   `UIGenerator`: (Planned) Automates UI creation from schemas (currently `Shell/init.lua` uses hardcoded UI).
