local Tabs = {}

function Tabs.CreateUniversal(Window, Events)
    local Tab = Window:AddTab({ Title = "Universal", Icon = "globe" })
    Tab:AddSection("Movement Features")

    local function createToggle(id, title)
        local toggle = Tab:AddToggle(id, { Title = title, Default = false })
        toggle:OnChanged(function()
            Events:Emit("ToggleFeature", id, toggle.Value)
        end)
        -- Sync Listener
        if Events.Signals.FeatureState then
            Events.Signals.FeatureState.Event:Connect(function(fId, state)
                if fId == id then toggle:SetValue(state) end
            end)
        end
    end

    createToggle("speedwalk", "Speed Walk")
    createToggle("jumppower", "Jump Power")
    createToggle("gravity", "Low Gravity")

    return Tab
end

return Tabs