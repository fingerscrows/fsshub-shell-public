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
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

-- Load Internal Modules (Raw Load from Repo)
local EventsModule = loadstring(game:HttpGet(REPO .. "Events.lua"))()
local TabsModule = loadstring(game:HttpGet(REPO .. "UI/Tabs.lua"))()

function Shell.Boot(ApiClient, Session)
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

    -- === SESSION LISTENERS ===
    if Session and Session.OnExpired then
        Session.OnExpired:Connect(function()
            Window:Dialog({
                Title = "Session Expired",
                Content = "Please Re-execute.",
                Buttons = {} -- Soft lock
            })
        end)
    end

    -- === DYNAMIC UNLOCK FUNCTION ===
    function Shell.Unlock(Window, response)
        -- Transition to Main Phase
        SafeSetSubTitle("FSSHUB V3 - " .. (response.Tier or "User"))

        -- 1. Dashboard (Dynamic Content)
        -- Pass the auth response to populate User Info, MOTD, etc.
        -- Ensure response has 'Key' if we want to display it, otherwise pass KeyInput_Value if accessible.
        -- For now, we assume response contains necessary display info.
        TabsModule.CreateDashboard(Window, response)

        -- 2. Features (Universal)
        TabsModule.CreateUniversal(Window, Bridge, ApiClient, Fluent)

        -- 3. Settings Tab
        local SettingsTab = Window:AddTab({ Title = "Settings", Icon = "settings" })
        SaveManager:SetLibrary(Fluent)
        InterfaceManager:SetLibrary(Fluent)

        -- Auto-Save Configuration
        SaveManager:SetFolder("FSSHUB_Settings")
        SaveManager:SetIgnoreIndexes({ 'KeyInput', 'Token' }) -- Security

        InterfaceManager:BuildInterfaceSection(SettingsTab)
        SaveManager:BuildConfigSection(SettingsTab)

        -- Switch to Dashboard (Index 2, assuming Login is 1. Wait, if we added tabs, Login is still there?)
        -- The requirement was "Menerapkan alur Auth-Locked (Hanya tab Login yang terlihat di awal)."
        -- "Menyuntikkan tab Dashboard... setelah sukses login."
        -- Usually we might want to Destroy the Login tab or just switch away.
        -- Fluent doesn't support destroying tabs easily. We just switch.
        Window:SelectTab(2) -- Dashboard is the first injected tab, so it's at index 2 (Login is 1)

        Fluent:Notify({
            Title = "Welcome",
            Content = "System Unlocked. " .. (response.Tier or "User") .. " Access Granted.",
            Duration = 5
        })
    end

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
                Fluent:Notify({Title = "Error", Content = "Please enter a key.", Duration = 3})
                return
            end

            Fluent:Notify({Title = "Authenticating", Content = "Verifying key...", Duration = 2})

            -- AUTHENTICATE
            local success, response = ApiClient.Authenticate(trimmedKey)

            if not success then
                local err = response and response.error
                if err == "UPDATE_REQUIRED" then
                    Window:Dialog({
                        Title = "Update Required",
                        Content = "Script Update Required. Get new script at [Link].",
                        Buttons = {}
                    })
                elseif err == "SYSTEM_LOCKDOWN" then
                    Window:Dialog({
                        Title = "System Lockdown",
                        Content = "System under maintenance. Check Discord for info.",
                        Buttons = {}
                    })
                else
                    Fluent:Notify({
                        Title = "Authentication Failed",
                        Content = (response and response.message) or "Unknown Error",
                        Duration = 5
                    })
                end
            else
                -- Inject Key into response for Dashboard display if not present
                if response then response.Key = trimmedKey end

                Shell.Unlock(Window, response)
            end
        end
    })

    LoginTab:AddButton({
        Title = "Get Key",
        Description = "Copy link to get a key system",
        Callback = function()
            local keyLink = "https://link-to-your-key-system.com"
            if setclipboard then
                setclipboard(keyLink)
                Fluent:Notify({
                    Title = "Success",
                    Content = "Key link copied to clipboard!",
                    Duration = 5
                })
            else
                Fluent:Notify({
                    Title = "Error",
                    Content = "Executor does not support clipboard.",
                    Duration = 5
                })
            end
        end
    })

    Window:SelectTab(1)

    if Bridge.Signals.Notification then
        Bridge.Signals.Notification.Event:Connect(function(t, c, d)
            Fluent:Notify({ Title = t, Content = c, Duration = d or 5 })
        end)
    end

    print("🎨 Shell Loaded.")
end

return Shell