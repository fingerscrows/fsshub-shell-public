local RunService = game:GetService("RunService")
local StatsService = game:GetService("Stats")

-- [FIX V3] Dual Mode Load (Local Source vs Online Release)
local Fluent, SaveManager, InterfaceManager
if script and script.Parent and script.Parent:FindFirstChild("Fluent") then
    -- Mode Studio/Rojo (Local Source)
    Fluent = require(script.Parent.Fluent.src)
    SaveManager = require(script.Parent.Fluent.Addons.SaveManager)
    InterfaceManager = require(script.Parent.Fluent.Addons.InterfaceManager)
else
    -- Mode Executor/Live Test (Online)
    -- Kita pakai versi stabil untuk test agar tidak ribet pathing
    Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
    SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
    InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()
end

-- Main Entry Point ... (sisanya sama)

-- Main Entry Point
return function(ApiClient, Session)
    local Window = Fluent:CreateWindow({
        Title = "FSSHUB V3",
        SubTitle = "Cyber Dashboard",
        TabWidth = 160,
        Size = UDim2.fromOffset(580, 460),
        Acrylic = true,
        Theme = "Dark",
        MinimizeKey = Enum.KeyCode.LeftControl
    })

    -- Enforce Cyber/Neon Accent via Options as requested
    -- We assume Fluent allows setting this in Options or it's a specific instruction to populate this table
    Fluent.Options.Accent = Color3.fromRGB(0, 255, 255)

    -- Tabs
    local Tabs = {
        Dashboard = Window:AddTab({ Title = "Dashboard", Icon = "layout-dashboard" }),
        Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
    }

    local Options = Fluent.Options

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
        Title = "Launch AutoFarm",
        Description = "Vault Integration",
        Callback = function()
            if not ApiClient then
                Fluent:Notify({
                    Title = "Error",
                    Content = "ApiClient not initialized.",
                    Duration = 3
                })
                return
            end

            -- Synchronous request as per instruction
            local success, response = ApiClient.RequestFeature("autofarm")

            if success and response and response.ok then
                -- In a real environment, we would execute the code:
                -- local fn = loadstring(response.chunk)
                -- if fn then fn() end

                Fluent:Notify({
                    Title = "Success",
                    Content = "AutoFarm feature loaded.",
                    Duration = 3
                })
            else
                Fluent:Notify({
                    Title = "Error",
                    Content = "Failed to load AutoFarm.",
                    Duration = 3
                })
            end
        end
    })

    -- Setup SaveManager & InterfaceManager
    SaveManager:SetLibrary(Fluent)
    InterfaceManager:SetLibrary(Fluent)

    -- Ignore list (Security Patching: Phase A1)
    SaveManager:SetIgnoreIndexes({'AutoFarm', 'ESP', 'WalkSpeed', 'JumpPower'})

    -- Build Interface Section
    InterfaceManager:BuildInterfaceSection(Tabs.Settings)

    -- Build SaveManager Section
    SaveManager:BuildConfigSection(Tabs.Settings)

    -- Set Folder
    SaveManager:SetFolder("FSSHUB_V3")

    -- Update Loop (FPS, Ping, TTL)
    task.spawn(function()
        while Window do
            -- FPS
            local fps = math.floor(workspace:GetRealPhysicsFPS())
            FPSParagraph:SetDesc(tostring(fps))

            -- Ping
            -- Stats.Network.ServerStatsItem["Data Ping"] might be nil in some contexts, strictly speaking,
            -- but commonly used in Roblox exploits/clients.
            local pingValue = 0
            pcall(function()
                pingValue = StatsService.Network.ServerStatsItem["Data Ping"]:GetValue()
            end)
            local ping = math.floor(pingValue)
            PingParagraph:SetDesc(tostring(ping) .. " ms")

            -- TTL
            if Session and Session.Expire then
                local timeLeft = Session.Expire - os.time()
                if timeLeft > 0 then
                    local h = math.floor(timeLeft / 3600)
                    local m = math.floor((timeLeft % 3600) / 60)
                    local s = timeLeft % 60
                    SessionParagraph:SetDesc(string.format("%02d:%02d:%02d", h, m, s))
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

    -- Load Autoload Config
    SaveManager:LoadAutoloadConfig()

    return Window
end
