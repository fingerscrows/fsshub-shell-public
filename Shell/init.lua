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

    -- === LOGIN GATING ===
    local LoginTab = Window:AddTab({ Title = "Login", Icon = "key" })
    local KeyInput_Value = ""

    LoginTab:AddInput("KeyInput", {
        Title = "License Key",
        Default = "",
        Placeholder = "FSSHUB-XXXX-...",
        Numeric = false,
        Finished = false,
        Callback = function(Value)
            KeyInput_Value = Value
        end
    })

    LoginTab:AddButton({
        Title = "Verify Key",
        Description = "Authenticate with Core",
        Callback = function()
            if Bridge.Signals.TryLogin then
                Bridge.Signals.TryLogin:Fire(KeyInput_Value)
            end
        end
    })

    LoginTab:AddButton({
        Title = "Get Key",
        Description = "Copy Key Link",
        Callback = function()
            if setclipboard then
                setclipboard("https://link-to-key-system.com")
            end
            Fluent:Notify({
                Title = "Key System",
                Content = "Link copied to clipboard",
                Duration = 5
            })
        end
    })

    Window:SelectTab(1)

    -- === UNLOCK LOGIC ===
    function Shell.Unlock(tier)
        -- Create Main Dashboard
        local UniversalTab = TabsModule.CreateUniversal(Window, Bridge)
        local SettingsTab = Window:AddTab({ Title = "Settings", Icon = "settings" })

        SaveManager:SetLibrary(Fluent)
        InterfaceManager:SetLibrary(Fluent)
        InterfaceManager:BuildInterfaceSection(SettingsTab)
        SaveManager:BuildConfigSection(SettingsTab)

        -- Update Title (Cosmetic)
        pcall(function()
            local newTitle = "FSSHUB V3 - Welcome, " .. tostring(tier)
            Window.Title = newTitle
            if Window.SetDialogTitle then Window:SetDialogTitle(newTitle) end
        end)

        -- Switch to Universal Tab (Index 2, since Login is 1)
        Window:SelectTab(2)
    end

    -- === AUTH LISTENERS ===
    if Bridge.Signals.AuthResult then
        Bridge.Signals.AuthResult.Event:Connect(function(success, tierOrMsg)
            if success then
                Shell.Unlock(tierOrMsg)
                Fluent:Notify({ Title = "Authentication", Content = "Login Successful!", Duration = 3 })
            else
                Fluent:Notify({ Title = "Authentication Failed", Content = tostring(tierOrMsg), Duration = 5 })
            end
        end)
    end

    if Bridge.Signals.Notification then
        Bridge.Signals.Notification.Event:Connect(function(t, c, d)
            Fluent:Notify({ Title = t, Content = c, Duration = d or 5 })
        end)
    end

    print("🎨 Shell Loaded.")
end

return Shell