local Shell = {}

-- Helper to get global environment safely
local getgenv = getgenv or function() return _G or shared end

-- Repo Base URL for Raw Load
local REPO = "https://raw.githubusercontent.com/fingerscrows/fsshub-shell-public/main/Shell/"

-- Load Fluent & Addons (Raw Load)
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

-- Load Internal Modules (Raw Load from Repo)
local EventsModule = loadstring(game:HttpGet(REPO .. "Events.lua"))()
local TabsModule = loadstring(game:HttpGet(REPO .. "UI/Tabs.lua"))()

function Shell.Boot()
    -- Robust Singleton Check
    local existing = getgenv().FSSHUB_SHELL
    if existing then
        if existing.Window and existing.Window.Instance and existing.Window.Instance.Parent then
            -- Window is valid, just toggle
            existing.Window.Instance.Enabled = not existing.Window.Instance.Enabled
            if existing.Events and existing.Events.Notification then
                 existing.Events.Notification:Fire("FSSHUB", "Already Loaded", 5)
            end
            return existing
        else
            -- Window is destroyed, proceed to reload but cleanup first just in case
            if existing.Unload then
                existing.Unload()
            end
        end
    end

    local Window = Fluent:CreateWindow({
        Title = "FSSHUB V3", SubTitle = "Public Shell",
        TabWidth = 160, Size = UDim2.fromOffset(580, 460),
        Acrylic = true, Theme = "Dark", MinimizeKey = Enum.KeyCode.LeftControl
    })

    local Bridge = EventsModule.Init()
    Shell.Connections = {} -- Initialize connection store

    local UniversalTab = TabsModule.CreateUniversal(Window, Bridge)
    local SettingsTab = Window:AddTab({ Title = "Settings", Icon = "settings" })

    SaveManager:SetLibrary(Fluent)
    -- Config Safety: Explicitly set IgnoreIndexes
    SaveManager:SetIgnoreIndexes({ 'Key', 'Token' })
    InterfaceManager:SetLibrary(Fluent)
    InterfaceManager:BuildInterfaceSection(SettingsTab)
    SaveManager:BuildConfigSection(SettingsTab)

    Window:SelectTab(1)

    if Bridge.Signals.Notification then
        local conn = Bridge.Signals.Notification.Event:Connect(function(t, c, d)
            Fluent:Notify({ Title = t, Content = c, Duration = d or 5 })
        end)
        table.insert(Shell.Connections, conn)
    end

    -- Define Unload Function
    local function Unload()
        -- Disconnect listeners
        if Shell.Connections then
            for _, conn in ipairs(Shell.Connections) do
                conn:Disconnect()
            end
            Shell.Connections = {}
        end

        -- Destroy Window
        if Window then
            Window:Destroy()
        end

        -- Clear Global References but PRESERVE Events for stability
        local g = getgenv().FSSHUB_SHELL
        if g then
            g.Window = nil
            g.Unload = nil
            -- Events are intentionally left alone
        end

        print("FSSHUB Unloaded")
    end

    -- EXPOSE GLOBAL BRIDGE
    getgenv().FSSHUB_SHELL = {
        Events = Bridge.Signals,
        Window = Window,
        Unload = Unload
    }

    print("🎨 Shell Loaded.")
    return Shell
end

return Shell