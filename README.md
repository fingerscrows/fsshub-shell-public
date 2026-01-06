# FSSHUB V3 - Stateless UI Shell

## Overview

This repository contains the **Stateless UI Shell** for **FSSHUB V3**, built using the **Fluent UI Library**. It serves as the visual interface for the FSSHUB system, providing a sleek "Cyber/Neon" aesthetic and a modular dashboard structure.

This project is strictly the **UI layer**. It does not contain the core game logic, which is loaded dynamically from the private core repository.

## Architecture

**The "Remote Control" Pattern**

This Shell operates as a "Remote Control" for the private Core ("TV Box").
- **Stateless:** The Shell does not execute game logic (e.g., it doesn't run the `SpeedHack` loop).
- **Event-Driven:** It sends signals (e.g., "Toggle Speed") to the Core via a **Bridge**.
- **Reactive:** It listens for signals from the Core (e.g., "Auth Success", "Feature State Update") to update the UI.

For more details, see [docs/architecture.md](docs/architecture.md).

## Integration & Boot

**⚠️ This Shell cannot run standalone.**

It is designed to be loaded by a private **Loader** script.

**Boot Process:**
1. **Raw Load:** The Loader fetches `Shell/init.lua` via `loadstring`.
2. **Boot:** The Loader calls `Shell.Boot()`.
3. **Bridge:** The Shell exposes `getgenv().FSSHUB_SHELL`. The Core connects to the events in `FSSHUB_SHELL.Events` to handle logic.

**Entry Point:**
```lua
local Shell = loadstring(game:HttpGet(".../Shell/init.lua"))()
Shell.Boot() -- Initializes UI and Event Bridge
```

## Directory Structure

*   **`Shell/`**: Contains the source code for the Shell.
    *   `init.lua`: Main entry point.
    *   `Events.lua`: Defines the Event Bridge (Signal system).
    *   `UI/`: UI Components and Tab logic.
    *   `RemoteConfig.lua`: Handling of dynamic MOTD/Maintenance checks.
*   **`Fluent/`**: Local copy of the UI library (Reference/Dev). *Note: Runtime loads Fluent remotely.*

## Customization

### Theme
The UI uses a **Cyber Neon** theme by default. You can customize this in `Shell/init.lua`.

### Adding Features
Features are dynamically rendered based on the data received from the Core during the `Unlock` phase. See `Shell/UI/Tabs.lua`.

## Credits

*   **Fluent UI Library**: Created by [dawid-scripts](https://github.com/dawid-scripts).
*   **FSSHUB Team**: V3 Architecture.
