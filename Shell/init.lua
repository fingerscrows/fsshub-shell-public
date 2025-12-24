local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")

-- Require Fluent source as per instruction
local Fluent = require(script.Parent.Parent.Fluent.src)
local Signal = require(script.Parent.Events)

-- Main Entry Point
return function(ApiClient, Session)
    local Window = Fluent:CreateWindow({
        Title = "FSSHUB V3",
        SubTitle = "Cyber Dashboard",
        TabWidth = 160,
        Size = UDim2.fromOffset(580, 460),
        Acrylic = true,
        Theme = "Dark", -- or "Amethyst"
        MinimizeKey = Enum.KeyCode.LeftControl
    })

    -- Set Cyber/Neon Accent
    -- Since we want to customize the accent for the 'Cyber' theme effect,
    -- we can modify the theme properties directly if Fluent exposes them,
    -- or use Options if available.
    -- Fluent 1.1.0 typically loads themes from ModuleScripts.
    -- Here we attempt to override the Accent color after window creation or via Options if supported.
    -- Based on typical Fluent usage, we can try to update the theme manually.

    local success, themeModule = pcall(function()
        return require(script.Parent.Parent.Fluent.src.Themes.Dark)
    end)

    if success and themeModule then
        themeModule.Accent = Color3.fromRGB(0, 255, 255)
        -- Re-apply theme if possible, though modifying the table *after* require
        -- might not affect already loaded instances unless we call SetTheme again
        -- or if Fluent re-reads the table.
        -- A more robust way is to define a custom theme or modify the global options if Fluent supports it.
        Fluent:SetTheme("Dark")
    end

    -- If Fluent allows option overrides:
    if Fluent.Options then
         -- Some versions allow Fluent.Options.Accent = ...
         -- We leave this as a best-effort integration.
    end

    -- Tabs
    local Tabs = {
        Dashboard = Window:AddTab({ Title = "Dashboard", Icon = "layout-dashboard" }),
        Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
    }

    -- Dashboard Features
    local Section = Tabs.Dashboard:AddSection("Status")

    local FPSParagraph = Tabs.Dashboard:AddParagraph({
        Title = "FPS",
        Content = "Calculating..."
    })

    local PingParagraph = Tabs.Dashboard:AddParagraph({
        Title = "Ping",
        Content = "Calculating..."
    })

    local SessionParagraph = Tabs.Dashboard:AddParagraph({
        Title = "Session TTL",
        Content = "Calculating..."
    })

    -- Vault Integration
    Tabs.Dashboard:AddButton({
        Title = "Vault: AutoFarm",
        Description = "Request autofarm feature from Core",
        Callback = function()
            Window:Dialog({
                Title = "Request Feature",
                Content = "Requesting AutoFarm from Vault...",
                Buttons = {
                    {
                        Title = "Confirm",
                        Callback = function()
                            if ApiClient then
                                ApiClient.RequestFeature("autofarm")
                                Fluent:Notify({
                                    Title = "Request Sent",
                                    Content = "Feature request sent to core.",
                                    Duration = 3
                                })
                            else
                                Fluent:Notify({
                                    Title = "Error",
                                    Content = "ApiClient not available.",
                                    Duration = 3
                                })
                            end
                        end
                    },
                    {
                        Title = "Cancel",
                        Callback = function()
                            -- Do nothing
                        end
                    }
                }
            })
        end
    })

    -- Update Loop (FPS, Ping, TTL)
    task.spawn(function()
        while Window do
            -- FPS
            local fps = math.floor(workspace:GetRealPhysicsFPS())
            FPSParagraph:SetDesc(tostring(fps))

            -- Ping
            local ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
            PingParagraph:SetDesc(tostring(ping) .. " ms")

            -- TTL
            if Session and Session.Expire then
                local timeLeft = Session.Expire - os.time()
                if timeLeft > 0 then
                    local hours = math.floor(timeLeft / 3600)
                    local minutes = math.floor((timeLeft % 3600) / 60)
                    local seconds = timeLeft % 60
                    SessionParagraph:SetDesc(string.format("%02d:%02d:%02d", hours, minutes, seconds))
                else
                    SessionParagraph:SetDesc("Expired")
                end
            else
                SessionParagraph:SetDesc("N/A")
            end

            task.wait(1)
        end
    end)

    Window:SelectTab(1)

    Fluent:Notify({
        Title = "FSSHUB V3",
        Content = "Shell initialized successfully.",
        Duration = 5
    })

    return Window
end
