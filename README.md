# FSSHUB V3 - Stateless UI Shell

> **📘 Architecture Documentation**: Please read [docs/architecture.md](docs/architecture.md) for a detailed technical breakdown.

## Overview

This repository contains the **Stateless UI Shell** for **FSSHUB V3**, built using the **Fluent UI Library**. It serves as the visual interface (the "Remote Control") for the FSSHUB system.

**Important**: This project is strictly the **UI layer**. It does not contain the core game logic, which is loaded dynamically from the private core repository (the "TV Box").

## Directory Structure

*   **`Shell/`**: The active source code.
    *   `init.lua`: The main entry point (injected by Loader).
    *   `Events.lua`: Signal wrapper.
    *   `UI/`: Dashboard components.
*   **`Fluent/`**: **Reference Only**. The production Shell loads the Fluent library dynamically from its official source to ensure the latest version. This folder is kept for development reference.
*   **`docs/`**: Architecture and Audit logs.

## Dependency Injection (Usage)

**⚠️ This Shell cannot run standalone.**

The `Shell/init.lua` module must be required by the private **Loader**, which injects the `ApiClient` and `Session` dependencies.

```lua
-- Example Loader Usage
local Shell = loadstring(game:HttpGet(".../Shell/init.lua"))()
Shell.Boot(ApiClient, Session)
```

## Customization & Theme

The UI uses a **Cyber Neon** theme (`Dark` base + `Cyan` accent).
To modify the theme or add buttons, edit `Shell/init.lua` and `Shell/UI/Tabs.lua`.

**Note**: Feature toggles use the **Safe Toggle Pattern**. They will automatically revert if the `ApiClient` fails to enable the feature on the Core.

## Credits

*   **Fluent UI Library**: [dawid-scripts](https://github.com/dawid-scripts)
*   **FSSHUB Team**: V3 Architecture
