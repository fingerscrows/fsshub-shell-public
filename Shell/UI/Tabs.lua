local Tabs = {}

function Tabs.CreateDashboard(Window, data)
    local Tab = Window:AddTab({ Title = "Dashboard", Icon = "home" })

    -- MOTD Section
    local MotdSection = Tab:AddSection("Message of the Day")
    Tab:AddParagraph({
        Title = "System Message",
        Content = (data and (data.MOTD or data.Flags)) or "Welcome to FSSHUB V3 Shell."
    })

    -- User Info Section
    local UserSection = Tab:AddSection("User Information")
    Tab:AddParagraph({
        Title = "Credentials",
        Content = string.format("Tier: %s\nKey: %s",
            (data and data.Tier) or "Unknown",
            (data and data.Key) or "Hidden"
        )
    })

    -- Session Stats Section
    local StatsSection = Tab:AddSection("Session Statistics")
    -- Note: Uptime is dynamic, so we just show the start time or static status for now.
    -- A real implementation might use a loop to update a label, but standard Fluent Paragraphs are static.
    -- We will display the connection status.
    Tab:AddParagraph({
        Title = "Status",
        Content = string.format("Connection: %s\nUptime: %s",
            (data and data.Status) or "Active",
            "Just Started"
        )
    })

    return Tab
end

function Tabs.CreateUniversal(Window, Bridge, Fluent)
    local Tab = Window:AddTab({ Title = "Universal", Icon = "globe" })

    -- Legacy Aesthetics: Verbose Section Name
    local Section = Tab:AddSection("Movement Dynamics")

    -- Track toggles for FeatureState event
    local toggles = {}

    -- Safe Toggle Pattern Implementation
    local function CreateSafeToggle(id, title, description)
        local Toggle = Section:AddToggle(id, {
            Title = title,
            Description = description,
            Default = false
        })
        toggles[id] = Toggle
        local isProgrammatic = false

        Toggle:OnChanged(function()
            if isProgrammatic then return end

            local Value = Toggle.Value

            -- Fire ToggleFeature event to Core
            -- Core will handle the API request and respond via FeatureState if it fails
            Bridge.Signals.ToggleFeature:Fire(id, Value)
        end)
    end

    -- Listen for FeatureState events (server-side revert)
    Bridge.Signals.FeatureState.Event:Connect(function(featureId, state)
        local toggle = toggles[featureId]
        if toggle and toggle.Value ~= state then
            -- Programmatic revert (avoid triggering OnChanged)
            local isProgrammatic = true
            toggle:SetValue(state)
            isProgrammatic = false
        end
    end)

    -- Feature Implementations
    CreateSafeToggle("speedwalk", "Speed Walk", "Increases movement speed significantly.")
    CreateSafeToggle("jumppower", "Jump Power", "Boosts jump height for better navigation.")
    CreateSafeToggle("gravity", "Gravity Control", "Alters gravity to allow floating or heavy falling.")

    return Tab
end

return Tabs
