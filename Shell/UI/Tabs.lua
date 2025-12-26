local Tabs = {}
local RunService = game:GetService("RunService")
local StatsService = game:GetService("Stats")

function Tabs.Build(Window, Fluent, Events, SaveManager, InterfaceManager)
    -------------------------------------------------------------------------
    -- Tab: Home (Status, MOTD, Stats)
    -------------------------------------------------------------------------
    local HomeTab = Window:AddTab({ Title = "Home", Icon = "home" })

    local StatusSection = HomeTab:AddSection("Status")

    local StatusParagraph = HomeTab:AddParagraph({
        Title = "Status",
        Content = "Waiting for Core..."
    })

    local SessionParagraph = HomeTab:AddParagraph({
        Title = "Session TTL",
        Content = "--:--:--"
    })

    local StatsSection = HomeTab:AddSection("Statistics")

    local FPSParagraph = HomeTab:AddParagraph({
        Title = "FPS",
        Content = "Calculating..."
    })

    local PingParagraph = HomeTab:AddParagraph({
        Title = "Ping",
        Content = "Calculating..."
    })

    -- [Local Logic] FPS & Ping Loop
    task.spawn(function()
        while Window do
            -- FPS
            local fps = math.floor(workspace:GetRealPhysicsFPS())
            FPSParagraph:SetDesc(tostring(fps))

            -- Ping
            local pingValue = 0
            pcall(function()
                pingValue = StatsService.Network.ServerStatsItem["Data Ping"]:GetValue()
            end)
            local ping = math.floor(pingValue)
            PingParagraph:SetDesc(tostring(ping) .. " ms")

            task.wait(1)
        end
    end)

    -- [Remote Logic] Listen for Status Updates from Core
    Events.Signals.OnStatusUpdate:Connect(function(statusData)
        if statusData.Status then
            StatusParagraph:SetDesc(statusData.Status)
        end
        if statusData.TTL then
             SessionParagraph:SetDesc(statusData.TTL)
        end
    end)


    -------------------------------------------------------------------------
    -- Tab: Universal (SpeedWalk, JumpPower, Gravity)
    -------------------------------------------------------------------------
    local UniversalTab = Window:AddTab({ Title = "Universal", Icon = "globe" })

    -- Helper to create synced toggle
    local function CreateSyncedToggle(id, title, description, default)
        local ignoreUpdate = false

        local Toggle = UniversalTab:AddToggle(id, {
            Title = title,
            Description = description,
            Default = default or false,
            Callback = function(Value)
                if ignoreUpdate then return end
                -- Emit command to Core
                Events.Emit("ToggleFeature", id, Value)
            end
        })

        -- Listen for remote state changes (Server Disables / Core Overrides)
        Events.Signals.FeatureState:Connect(function(featureId, value)
            if featureId == id then
                ignoreUpdate = true
                Toggle:SetValue(value)
                ignoreUpdate = false
            end
        end)
    end

    CreateSyncedToggle("SpeedWalk", "Speed Walk", "Enable faster movement", false)
    CreateSyncedToggle("JumpPower", "Jump Power", "Enable higher jumps", false)
    CreateSyncedToggle("Gravity", "Gravity Control", "Modify character gravity", false)


    -------------------------------------------------------------------------
    -- Tab: Settings (SaveManager, InterfaceManager)
    -------------------------------------------------------------------------
    local SettingsTab = Window:AddTab({ Title = "Settings", Icon = "settings" })

    if SaveManager then
        SaveManager:SetLibrary(Fluent)
        SaveManager:SetIgnoreIndexes({'SpeedWalk', 'JumpPower', 'Gravity'}) -- Stateless features
        SaveManager:SetFolder("FSSHUB_V3")
        SaveManager:BuildConfigSection(SettingsTab)
    end

    if InterfaceManager then
        InterfaceManager:SetLibrary(Fluent)
        InterfaceManager:BuildInterfaceSection(SettingsTab)
    end
end

return Tabs
