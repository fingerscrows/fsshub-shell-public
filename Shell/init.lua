local Events = require(script.Events)
local WindowModule = require(script.UI.Window)
local TabsModule = require(script.UI.Tabs)

-- Main Entry Point
return function(ApiClient)
    -- Inisialisasi Window
    local Window, Fluent = WindowModule.Create()

    -- Setup Tabs
    local Dashboard = TabsModule.CreateDashboard(Window)
    local Settings = TabsModule.CreateSettings(Window)

    -- Select default tab
    Window:SelectTab(1)

    -- Notify readiness
    Fluent:Notify({
        Title = "FSSHub Loaded",
        Content = "Shell UI initialized successfully.",
        Duration = 5
    })

    -- Example of using ApiClient if needed (via Events)
    -- Events.Request:Fire("CheckAuth")

    return Window
end
