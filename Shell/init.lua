local Events = require(script.Events)
local WindowModule = require(script.UI.Window)
local TabsModule = require(script.UI.Tabs)

-- Requires Fluent Addons (Shell/init.lua -> Shell -> Root -> Fluent -> Addons)
local SaveManager = require(script.Parent.Fluent.Addons.SaveManager)
local InterfaceManager = require(script.Parent.Fluent.Addons.InterfaceManager)

-- Helper to get global environment safely
local function getGlobal()
    return (getgenv and getgenv()) or _G or shared
end

-- Main Entry Point
-- Arg 'ApiClient' and 'Session' are accepted for signature compatibility
-- but NOT used for logic, strictly adhering to "Dumb Shell" rules.
return function(ApiClient, Session)
    -- 1. Initialize Window
    local Window, Fluent = WindowModule.Create()

    -- 2. Build Tabs (Home, Universal, Settings)
    -- Passes Events for wiring, and Managers for Settings tab
    TabsModule.Build(Window, Fluent, Events, SaveManager, InterfaceManager)

    -- 3. Select Default Tab
    Window:SelectTab(1)

    -- 4. Expose Bridge to Global Environment
    -- The Private Core will look for this global to attach its listeners.
    local G = getGlobal()
    if G then
        G.FSSHUB_SHELL = {
            Events = Events._bridge
        }
    end

    -- 5. Notify Load
    Fluent:Notify({
        Title = "FSSHUB V3",
        Content = "Shell initialized. Waiting for Core...",
        Duration = 5
    })

    -- 6. Load Autoload Config (if any)
    if SaveManager then
        SaveManager:LoadAutoloadConfig()
    end

    return Window
end
