# FSSHUB V3 - Stateless UI Shell

## Overview

This repository contains the **Stateless UI Shell** for **FSSHUB V3**, built using the **Fluent UI Library**. It serves as the visual interface for the FSSHUB system, providing a sleek "Cyber/Neon" aesthetic and a modular dashboard structure.

This project is strictly the **UI layer**. It does not contain the core game logic, which is loaded dynamically from the private core repository.

## Architecture & Integration

**⚠️ This Shell cannot run standalone.**

The `Shell/init.lua` module is designed to be required and executed by a private **Loader**.

**Entry Point Signature:**
```lua
local Shell = loadstring(...)()
Shell.Boot()
```

### Communication Bridge
The Shell operates as a "Remote Control" for the private Core. It uses `BindableEvent` instances (defined in `Shell/Events.lua`) to communicate:

*   **Outgoing**: `TryLogin`, `ToggleFeature`
*   **Incoming**: `AuthResult`, `FeatureState`, `Notification`

See [docs/architecture.md](docs/architecture.md) for the full architectural breakdown.

## Directory Structure

*   **`Fluent/`**: Contains the full source code of the Fluent UI Library.
*   **`Shell/`**: Contains the specific dashboard logic for FSSHUB.
    *   `init.lua`: The main entry point that constructs the UI.
    *   `Events.lua`: A lightweight Signal class.
    *   `UI/`: Tab implementations (Dashboard, Universal).

## Customization

### Theme
The UI uses a **Cyber Neon** theme by default. You can customize this in `Shell/init.lua` within the `Fluent:Construct` options.

### Adding Buttons
To add new functionality, locate the relevant Tab section in `Shell/UI/Tabs.lua` or `Shell/init.lua`.

## Credits

*   **Fluent UI Library**: Created by [dawid-scripts](https://github.com/dawid-scripts). Used as the foundation for the UI interface.
*   **FSSHUB Team**: For the V3 Architecture and implementation.
