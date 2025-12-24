local Tabs = {}
local Components = require(script.Parent.Components)

-- Standard Tabs Configuration
function Tabs.CreateDashboard(Window)
    local Tab = Window:AddTab({ Title = "Dashboard", Icon = "home" })

    Tab:AddSection("Status")

    -- FPS Label
    local FPSLabel = Components.CreateLabel(Tab, "FPS: 60", "Frames Per Second")

    -- MOTD Label
    local MOTDLabel = Components.CreateLabel(Tab, "MOTD: Welcome User", "Message of the Day")

    -- Session Time Label
    local SessionLabel = Components.CreateLabel(Tab, "Session: 00:00:00", "Time Elapsed")

    return {
        Tab = Tab,
        Elements = {
            FPS = FPSLabel,
            MOTD = MOTDLabel,
            Session = SessionLabel
        }
    }
end

function Tabs.CreateSettings(Window)
    local Tab = Window:AddTab({ Title = "Settings", Icon = "settings" })

    -- SaveManager and InterfaceManager Placeholder
    -- Standard Fluent usage requires external modules for these managers.
    -- Example usage if they were available:
    -- SaveManager:SetLibrary(Fluent)
    -- InterfaceManager:SetLibrary(Fluent)
    -- SaveManager:BuildConfigSection(Tab)
    -- InterfaceManager:BuildInterfaceSection(Tab)

    Tab:AddSection("Configuration")

    Tab:AddParagraph({
        Title = "Manager Missing",
        Content = "SaveManager and InterfaceManager modules are not linked."
    })

    Tab:AddButton({
        Title = "Save Configuration (Mock)",
        Description = "Save current settings",
        Callback = function()
            -- Mock save
            print("Settings saved.")
        end
    })

    return Tab
end

return Tabs
