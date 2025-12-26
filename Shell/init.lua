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
    local Window = Fluent:CreateWindow({
        Title = "FSSHUB V3", SubTitle = "Public Shell",
        TabWidth = 160, Size = UDim2.fromOffset(580, 460),
        Acrylic = true, Theme = "Dark", MinimizeKey = Enum.KeyCode.LeftControl
    })

    local Bridge = EventsModule.Init()
    -- EXPOSE GLOBAL BRIDGE
    getgenv().FSSHUB_SHELL = { Events = Bridge.Signals, Instance = Window }

    local UniversalTab = TabsModule.CreateUniversal(Window, Bridge)
    local SettingsTab = Window:AddTab({ Title = "Settings", Icon = "settings" })

    SaveManager:SetLibrary(Fluent)
    InterfaceManager:SetLibrary(Fluent)
    InterfaceManager:BuildInterfaceSection(SettingsTab)
    SaveManager:BuildConfigSection(SettingsTab)

    Window:SelectTab(1)

    if Bridge.Signals.Notification then
        Bridge.Signals.Notification.Event:Connect(function(t, c, d)
            Fluent:Notify({ Title = t, Content = c, Duration = d or 5 })
        end)
    end
    print("🎨 Shell Loaded.")
end

return Shell