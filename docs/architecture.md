# FSSHUB V3 - System Architecture

## Core Philosophy: "Remote Control" vs "TV Box"

FSSHUB V3 follows a **split-repository architecture** to separate the user interface (public) from the core game logic (private).

*   **The Shell (Remote Control)**: This repository. A stateless, visual interface. It has buttons and toggles but **zero game logic**. It sends commands to the Core.
*   **The Core (TV Box)**: A private repository. It handles the heavy lifting: Aimbot calculations, ESP drawing, network bypasses, and security.

## Component Overview

### 1. The Public Shell (`Shell/`)
*   **Role**: UI Rendering & User Input.
*   **State**: **Stateless**. It does not persist feature state (e.g., Aimbot is always OFF on load). Only cosmetic settings (Theme, Keybinds) are saved.
*   **Distribution**: Hosted on GitHub. Loaded via `loadstring` by the Core.

### 2. The Private Core (Injected)
*   **Role**: Execution & Logic.
*   **Interaction**: The Core requires the Shell and injects dependencies (`ApiClient`, `Session`).

## Key Patterns

### Dependency Injection
The Shell is not standalone. It exports a `Boot` function that requires two dependencies:

```lua
-- Shell/init.lua
return {
    Boot = function(ApiClient, Session) ... end
}
```

*   **`ApiClient`**: A bridge to the Cloudflare Worker backend and the internal Game Abstraction Layer.
*   **`Session`**: Manages authentication state.

### Raw Load Mechanism
To ensure the Shell is always up-to-date and modular, `Shell/init.lua` uses `game:HttpGet` to dynamically load its own components (`Events.lua`, `UI/Tabs.lua`) from the raw GitHub content.

### Safe Toggle Pattern
UI Toggles strictly follow this flow to prevent state desync:

1.  **User Clicks Enable**:
    *   Shell calls `ApiClient.RequestFeature(id)`.
    *   **Success**: Toggle stays ON.
    *   **Failure** (Network/Auth): Toggle reverts to OFF automatically.
2.  **User Clicks Disable**:
    *   **Local Action Only**. The Shell immediately turns it off visually. No network request is required (Core polls state or event).

## Directory Breakdown

*   `Shell/`
    *   `init.lua`: Main entry point. Handles Auth/Unlock flow.
    *   `Events.lua`: Internal Signal/BindableEvent wrapper.
    *   `UI/`: Dashboard components.
*   `Fluent/`: **Reference Only**. The active Shell loads Fluent from the official source/CDN, not this local folder.

## Security Boundaries

*   **No Business Logic**: The Shell contains no pointers, offsets, or exploit-specific code.
*   **Sensitive Data**: `SaveManager` is configured to ignore `Key` and `Token` to prevent saving credentials to disk.
