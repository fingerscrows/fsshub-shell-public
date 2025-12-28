local Tabs = {}

function Tabs.CreateDashboard(Window, data)
    local Tab = Window:AddTab({ Title = "Dashboard", Icon = "home" })

    -- MOTD Section
    Tab:AddSection("Message of the Day")
    Tab:AddParagraph({
        Title = "System Message",
        Content = (data and (data.MOTD or data.Flags)) or "Welcome to FSSHUB V3 Shell."
    })

    -- User Info Section
    Tab:AddSection("User Information")
    Tab:AddParagraph({
        Title = "Credentials",
        Content = string.format("Tier: %s\nKey: %s",
            (data and data.Tier) or "Unknown",
            (data and data.Key and string.sub(data.Key, 1, 15) .. "...") or "Hidden"
        )
    })

    -- Session Stats Section
    Tab:AddSection("Session Statistics")
    Tab:AddParagraph({
        Title = "Status",
        Content = string.format("Connection: %s\nFeatures Available: %d",
            (data and data.Status) or "Active",
            (data and data.Features and #data.Features) or 0
        )
    })

    return Tab
end

-- V3: Server-driven feature rendering
function Tabs.CreateUniversal(Window, Bridge, Fluent, features)
    local Tab = Window:AddTab({ Title = "Features", Icon = "zap" })

    -- Track toggles for FeatureState event
    local toggles = {}
    -- FIXED: isProgrammatic scope - moved outside function, keyed by feature id
    local isProgrammatic = {}

    -- Safe Toggle Pattern Implementation
    local function CreateSafeToggle(section, id, title, description)
        local Toggle = section:AddToggle(id, {
            Title = title,
            Description = description or "",
            Default = false
        })
        toggles[id] = Toggle
        isProgrammatic[id] = false

        Toggle:OnChanged(function()
            if isProgrammatic[id] then return end

            local Value = Toggle.Value
            -- Fire ToggleFeature event to Core
            Bridge.Signals.ToggleFeature:Fire(id, Value)
        end)
    end

    -- Listen for FeatureState events (server-side revert)
    Bridge.Signals.FeatureState.Event:Connect(function(featureId, state)
        local toggle = toggles[featureId]
        if toggle and toggle.Value ~= state then
            -- Programmatic revert (avoid triggering OnChanged)
            isProgrammatic[featureId] = true
            toggle:SetValue(state)
            isProgrammatic[featureId] = false
        end
    end)

    -- V3: Render features from server list
    if features and #features > 0 then
        -- Group features by category
        local categories = {}
        for _, feature in ipairs(features) do
            local cat = feature.category or "General"
            if not categories[cat] then
                categories[cat] = {}
            end
            table.insert(categories[cat], feature)
        end

        -- Create sections for each category
        for catName, catFeatures in pairs(categories) do
            local Section = Tab:AddSection(catName)
            for _, feature in ipairs(catFeatures) do
                CreateSafeToggle(Section, feature.id, feature.name, feature.description)
            end
        end
    else
        -- Fallback: No features available
        Tab:AddSection("No Features")
        Tab:AddParagraph({
            Title = "Notice",
            Content = "No features available for your tier or game not authorized."
        })
    end

    return Tab
end

-- Legacy CreateUniversal for backward compatibility
function Tabs.CreateUniversalLegacy(Window, Bridge, Fluent)
    local Tab = Window:AddTab({ Title = "Universal", Icon = "globe" })
    local Section = Tab:AddSection("Movement Dynamics")
    local toggles = {}
    local isProgrammatic = {}

    local function CreateSafeToggle(id, title, description)
        local Toggle = Section:AddToggle(id, {
            Title = title,
            Description = description,
            Default = false
        })
        toggles[id] = Toggle
        isProgrammatic[id] = false

        Toggle:OnChanged(function()
            if isProgrammatic[id] then return end
            Bridge.Signals.ToggleFeature:Fire(id, Toggle.Value)
        end)
    end

    Bridge.Signals.FeatureState.Event:Connect(function(featureId, state)
        if toggles[featureId] and toggles[featureId].Value ~= state then
            isProgrammatic[featureId] = true
            toggles[featureId]:SetValue(state)
            isProgrammatic[featureId] = false
        end
    end)

    CreateSafeToggle("speedwalk", "Speed Walk", "Increases movement speed significantly.")
    CreateSafeToggle("jumppower", "Jump Power", "Boosts jump height for better navigation.")
    CreateSafeToggle("gravity", "Gravity Control", "Alters gravity.")

    return Tab
end

return Tabs
