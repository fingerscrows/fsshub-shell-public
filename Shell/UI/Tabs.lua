local Tabs = {}

function Tabs.CreateUniversal(Window, Bridge, ApiClient, Fluent)
    local Tab = Window:AddTab({ Title = "Universal", Icon = "globe" })
    local Section = Tab:AddSection("Main Features")

    -- Safe Toggle Pattern Implementation
    local function CreateSafeToggle(id, title)
        local Toggle = Section:AddToggle(id, { Title = title, Default = false })
        local isProgrammatic = false

        Toggle:OnChanged(function()
            if isProgrammatic then return end

            local Value = Toggle.Value

            -- SAFE TOGGLE LOGIC
            if Value == false then
                -- Disable: Local Action Only (Guard Network Call)
                return
            end

            -- Enable: Network Action
            local success, _ = ApiClient.RequestFeature(id)

            -- FAILURE HANDLING
            if not success then
                isProgrammatic = true
                Toggle:SetValue(false) -- Revert
                isProgrammatic = false -- Recursion Guard

                Fluent:Notify({
                    Title = "Connection Failed",
                    Content = "Failed to enable " .. title,
                    Duration = 3
                })
            end
        end)
    end

    -- Feature Implementations
    CreateSafeToggle("speed_hack", "Speed Hack")
    CreateSafeToggle("jump_power", "Jump Power")
    CreateSafeToggle("esp_master", "ESP")

    return Tab
end

return Tabs