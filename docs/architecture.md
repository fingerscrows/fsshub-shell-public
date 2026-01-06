# FSSHUB V3 - Shell Architecture

## Overview
The FSSHUB Shell is a **Stateless UI Layer** ("Remote Control") that interfaces with a private **Core** ("TV Box") via a strict Event Bridge. It is designed to be loaded remotely and executed in a restricted environment (Roblox Executors).

## Core Concepts

### 1. Stateless Design
The Shell holds no game logic. It is responsible only for:
- Rendering the UI (using Fluent).
- capturing User Input.
- Sending signals to the Core.
- Receiving updates from the Core (Notifications, Feature States).

### 2. The "Remote Control" Analogy
- **Shell (Remote Control):** You press a button ("Toggle Speed"). It sends a signal. It doesn't know *how* speed is changed, only that the user requested it.
- **Core (TV Box):** Receives the signal. Checks if the user is allowed to do that. Changes the speed. Sends a signal back to the Shell to light up the LED (Toggle On).

### 3. Event Bridge Pattern
Communication between Shell and Core is handled entirely via `BindableEvent` instances, managed by `Shell/Events.lua`.

**Outgoing Signals (Shell -> Core):**
- `TryLogin(key)`: User attempted to log in.
- `GetKeyLink()`: User requested a key link.
- `ToggleFeature(id, state)`: User toggled a feature.

**Incoming Signals (Core -> Shell):**
- `AuthResult(success, data)`: Login response.
- `KeyLinkResult(success, url)`: Key link response.
- `FeatureState(id, state)`: Server-side state enforcement (e.g., reverting a toggle if failed).
- `Notification(title, content, duration)`: System notifications.

### 4. Raw Load & Deployment
The Shell is designed to be loaded via `loadstring(game:HttpGet(...))`.
- **Repo URL:** `https://raw.githubusercontent.com/fingerscrows/fsshub-shell-public/main/Shell/`
- **Modules:** `init.lua` loads internal dependencies (`Events.lua`, `UI/Tabs.lua`, etc.) using this Raw URL.
- **Libraries:** External libraries (Fluent, SaveManager) are also loaded via `loadstring`.

## Directory Structure

### `Shell/`
- **`init.lua`**: The entry point. Initializes the Window, Bridge, and Login Tab.
- **`Events.lua`**: Creates and manages the `BindableEvent` bridge.
- **`UI/`**:
    - **`Tabs.lua`**: Logic for creating Dashboard and Feature tabs.
    - **`Components.lua`**: Helper for UI components (currently minimal).
- **`RemoteConfig.lua`**: Fetches MOTD and maintenance status.
- **`SessionWatchdog.lua`**: Monitors session validity (if applicable).

## Integration Contract
The private **Loader** is responsible for:
1. Setting up the environment.
2. Loading the Core.
3. Loading `Shell/init.lua`.
4. Calling `Shell.Boot()`.

Unlike previous versions, `Shell.Boot()` does **not** accept arguments. Communication is established purely through the `getgenv().FSSHUB_SHELL.Events` table which the Core connects to.
