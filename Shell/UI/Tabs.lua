local Tabs = {}

function Tabs.CreateUniversal(Window, Events, ApiClient, Fluent)
    local Tab = Window:AddTab({ Title = "Universal", Icon = "globe" })
    Tab:AddSection("Movement Features")

    local function createToggle(id, title)
        local toggle = Tab:AddToggle(id, { Title = title, Default = false })
        local isProgrammatic = false

        toggle:OnChanged(function()
            if isProgrammatic then return end

            local success, _ = ApiClient.RequestFeature(id, toggle.Value)
            if not success then
                isProgrammatic = true
                toggle:SetValue(not toggle.Value)
                isProgrammatic = false

                if Fluent then
                    Fluent:Notify({
                        Title = "Connection Failed",
                        Content = "Failed to toggle feature. Please check your connection.",
                        Duration = 3
                    })
                end
            end
        end)

        -- Sync Listener
        if Events.Signals.FeatureState then
            Events.Signals.FeatureState.Event:Connect(function(fId, state)
                if fId == id then
                    isProgrammatic = true
                    toggle:SetValue(state)
                    isProgrammatic = false
                end
            end)
        end
    end

    createToggle("speedwalk", "Speed Walk")
    createToggle("jumppower", "Jump Power")
    createToggle("gravity", "Low Gravity")

    return Tab
end

return Tabs