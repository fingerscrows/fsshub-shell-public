# FSSHUB V3 - Stateless UI Shell

## Overview

This repository contains the **Stateless UI Shell** for **FSSHUB V3**, built using the **Fluent UI Library**. It serves as the visual interface for the FSSHUB system, providing a sleek "Cyber/Neon" aesthetic and a modular dashboard structure.

This project is strictly the **UI layer**. It does not contain the core game logic, which is loaded dynamically from the private core repository.

## Dependency Injection (Important)

**⚠️ This Shell cannot run standalone.**

The `Shell/init.lua` module is designed to be required and executed by a private **Loader**. It follows a **Dependency Injection** pattern where the Loader must inject the following instances:

*   **`ApiClient`**: Handles all network communication with the Cloudflare Worker backend.
*   **`Session`**: Manages the current user's session data and authentication state.

**Entry Point Signature:**
```lua
return function(ApiClient, Session)
    -- UI Logic starts here
end
```

Attempting to run `Shell/init.lua` directly without these dependencies will result in errors.

## Directory Structure

*   **`Fluent/`**: Contains the full source code of the Fluent UI Library.
    *   `src/`: The core library modules (renamed from `Fluent-1.1.0` to support modular requiring).
*   **`Shell/`**: Contains the specific dashboard logic for FSSHUB.
    *   `init.lua`: The main entry point that constructs the UI, handles tabs, and connects events.
    *   `Events.lua`: A lightweight Signal class for internal UI event handling.

## Customization

### Theme
The UI uses a **Cyber Neon** theme by default. You can customize this in `Shell/init.lua` within the `Fluent:Construct` options:

```lua
Fluent:Construct({
    Title = "FSS HUB V3",
    Theme = "Dark", -- Base theme
    Accent = Color3.fromRGB(0, 255, 255), -- Neon Cyan Accent
    -- ...
})
```

### Adding Buttons
To add new functionality, locate the relevant Tab section in `Shell/init.lua` (e.g., `Tabs.Main`).

Example:
```lua
Tabs.Main:AddButton({
    Title = "New Feature",
    Description = "Description of the feature",
    Callback = function()
        -- Handle click
    end
})
```

## Credits

*   **Fluent UI Library**: Created by [dawid-scripts](https://github.com/dawid-scripts). Used as the foundation for the UI interface.
*   **FSSHUB Team**: For the V3 Architecture and implementation.
