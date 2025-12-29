local Shell = {}

-- Helper to get global environment safely
local getgenv = getgenv or function() return _G or shared end

-- Repo Base URL for Raw Load
local REPO = "https://raw.githubusercontent.com/fingerscrows/fsshub-shell-public/main/Shell/"

-- Load Fluent & Addons (Raw Load)
local success, result = pcall(function()
    local raw = game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua")
    return loadstring(raw)()
end)

if not success then
    warn("❌ Fluent UI Load Failed: " .. tostring(result))
    return
end
local Fluent = result
local SaveManager = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

-- Load Internal Modules (Raw Load from Repo)
local EventsModule = loadstring(game:HttpGet(REPO .. "Events.lua"))()
local TabsModule = loadstring(game:HttpGet(REPO .. "UI/Tabs.lua"))()
local RemoteConfig = loadstring(game:HttpGet(REPO .. "RemoteConfig.lua"))()
local SessionWatchdog = loadstring(game:HttpGet(REPO .. "SessionWatchdog.lua"))()

function Shell.Boot()
    -- === THEME SETUP ===
    Fluent.Options.Accent = Color3.fromRGB(0, 255, 255) -- Cyan Neon

    -- === INITIAL WINDOW (LOGIN ONLY) ===
    local Window = Fluent:CreateWindow({
        Title = "FSSHUB V3",
        SubTitle = "Login Phase",
        TabWidth = 160,
        Size = UDim2.fromOffset(580, 460),
        Acrylic = true,
        Theme = "Dark",
        MinimizeKey = Enum.KeyCode.LeftControl
    })

    -- Prevent "attempt to index nil" by guarding SubTitle updates
    local function SafeSetSubTitle(text)
        pcall(function()
            if Window and Window.SetDialogTitle then
                Window:SetDialogTitle(text)
            else
                Window.SubTitle = text
            end
        end)
    end

    local Bridge = EventsModule.Init()
    -- EXPOSE GLOBAL BRIDGE
    getgenv().FSSHUB_SHELL = { Events = Bridge.Signals, Instance = Window }

    -- Store pending key for AuthResult callback
    local pendingKey = nil

    -- === DYNAMIC UNLOCK FUNCTION ===
    function Shell.Unlock(Window, tier, key, features)
        -- Transition to Main Phase
        SafeSetSubTitle("FSSHUB V3 - " .. (tier or "User"))

        local response = { Tier = tier, Key = key }

        -- 1. Dashboard (Dynamic Content)
        TabsModule.CreateDashboard(Window, response)

        -- 2. Features (Universal) - Now uses Bridge for feature requests
        TabsModule.CreateUniversal(Window, Bridge, Fluent, features or {})

        -- 3. Settings Tab
        local SettingsTab = Window:AddTab({ Title = "Settings", Icon = "settings" })
        SaveManager:SetLibrary(Fluent)
        InterfaceManager:SetLibrary(Fluent)

        -- Auto-Save Configuration
        SaveManager:SetFolder("FSSHUB_Settings")
        SaveManager:SetIgnoreIndexes({ 'KeyInput', 'Token' }) -- Security

        InterfaceManager:BuildInterfaceSection(SettingsTab)
        SaveManager:BuildConfigSection(SettingsTab)

        -- Switch to Dashboard
        Window:SelectTab(2)

        -- Start session watchdog
        if SessionWatchdog then
            SessionWatchdog.Start()
        end

        -- Show MOTD if available
        local motd = RemoteConfig and RemoteConfig.GetMOTD()
        if motd then
            Fluent:Notify({
                Title = "Message of the Day",
                Content = motd,
                Duration = 8
            })
        end

        Fluent:Notify({
            Title = "Welcome",
            Content = "System Unlocked. " .. (tier or "User") .. " Access Granted.",
            Duration = 5
        })
    end

    -- === FETCH REMOTE CONFIG ===
    if RemoteConfig then
        RemoteConfig.Fetch()
        if RemoteConfig.IsMaintenance() then
            Fluent:Notify({
                Title = "⚠️ Maintenance",
                Content = RemoteConfig.GetMOTD() or "System under maintenance",
                Duration = 10
            })
        end
    end

    -- === AUTH RESULT LISTENER (From Core) ===
    Bridge.Signals.AuthResult.Event:Connect(function(success, tierOrError, features)
        if success then
            -- Refresh config on auth success
            if RemoteConfig then RemoteConfig.Fetch() end
            Shell.Unlock(Window, tierOrError, pendingKey, features)
        else
            Fluent:Notify({
                Title = "Authentication Failed",
                Content = tierOrError or "Unknown Error",
                Duration = 5
            })
        end
    end)

    -- === LOGIN TAB ===
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
            -- TRIM INPUT
            local trimmedKey = string.gsub(KeyInput_Value, "^%s*(.-)%s*$", "%1")

            if trimmedKey == "" then
                Fluent:Notify({ Title = "Error", Content = "Please enter a key.", Duration = 3 })
                return
            end

            Fluent:Notify({ Title = "Authenticating", Content = "Verifying key...", Duration = 2 })

            -- Store key for AuthResult callback
            pendingKey = trimmedKey

            -- Fire TryLogin event to Core (Core will call ApiClient.Authenticate)
            Bridge.Signals.TryLogin:Fire(trimmedKey)
        end
    })

    LoginTab:AddButton({
        Title = "Get Key",
        Description = "Get a session-bound key from server",
        Callback = function()
            Fluent:Notify({
                Title = "Getting Key Link",
                Content = "Requesting secure key URL...",
                Duration = 2
            })

            -- V3: Request session-bound key link from Core
            Bridge.Signals.GetKeyLink:Fire()
        end
    })

    -- V3: Handle KeyLinkResult from Core
    Bridge.Signals.KeyLinkResult.Event:Connect(function(success, urlOrError)
        if success then
            if setclipboard then
                setclipboard(urlOrError)
                Fluent:Notify({
                    Title = "Success",
                    Content = "Key link copied to clipboard!",
                    Duration = 5
                })
            else
                Fluent:Notify({
                    Title = "Key Link",
                    Content = urlOrError,
                    Duration = 15
                })
            end
        else
            Fluent:Notify({
                Title = "Error",
                Content = urlOrError or "Failed to get key link",
                Duration = 5
            })
        end
    end)

    Window:SelectTab(1)

    if Bridge.Signals.Notification then
        Bridge.Signals.Notification.Event:Connect(function(t, c, d)
            Fluent:Notify({ Title = t, Content = c, Duration = d or 5 })
        end)
    end

    print("🎨 Shell Loaded.")
end

return Shell
