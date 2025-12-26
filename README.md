# FSSHUB V3 - Stateless UI Shell

## Overview

This repository contains the **Stateless UI Shell** for **FSSHUB V3**, built using the **Fluent UI Library**. It serves as the visual interface for the FSSHUB system.

**Role**: "Remote Control"
*   This project is strictly the **UI layer**.
*   It does **not** contain core game logic or anti-cheat bypasses.
*   It communicates with the private Core via BindableEvents.

## Architecture

### Loading Mechanism
The Shell is designed to be loaded dynamically via `loadstring`. It fetches its dependencies (Fluent, Addons) and internal modules directly from GitHub to ensure users always receive the latest interface updates without script restarts.

```lua
local Shell = loadstring(game:HttpGet(".../Shell/init.lua"))()
Shell.Boot()
```

### The Global Bridge
Upon booting, the Shell exposes its Event Bus to the global environment, allowing the private Core to attach listeners.

```lua
getgenv().FSSHUB_SHELL = {
    Events = { ... }, -- BindableEvents for communication
    Instance = Window -- The Fluent Window instance
}
```

### Communication Protocol
*   **Shell -> Core**: Emits `ToggleFeature(id, state)` when a user interacts with the UI.
*   **Core -> Shell**: Emits `FeatureState(id, state)` to update the UI visually if the feature is toggled externally (e.g., by game logic).

## Directory Structure

*   **`Shell/`**: The runtime code.
    *   `init.lua`: Main entry point. Sets up the Window and Global Bridge.
    *   `Events.lua`: Signal management.
    *   `UI/`: Dashboard modules (Tabs, Components). loaded via Raw URL by `init.lua`.
*   **`Fluent/`**: Source code reference for the UI library. (Note: Runtime currently loads Fluent from remote URL, not this local folder).

## Customization

### Theme
The UI uses a **Cyber Neon** theme.
*   **Base**: Dark
*   **Accent**: Neon Cyan (`0, 255, 255`)

### Adding Features
To add a button/toggle:
1.  Edit `Shell/UI/Tabs.lua`.
2.  Add the element.
3.  Ensure it emits `ToggleFeature`.

*Note: Since the script loads from GitHub Raw, you must push changes to see them in-game, or modify the `REPO` variable in `Shell/init.lua` for local testing.*

## Credits
*   **Fluent UI Library**: [dawid-scripts](https://github.com/dawid-scripts).
