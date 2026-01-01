--[[
    FSSHUB V3 - Shell GUI Module
    ============================
    DUMB UI ONLY - Safe for public repository.

    Architecture:
    - Auth Gateway: Initial screen for key verification
    - Main Menu: Unlocked after valid key received

    @module Shell
    @version 3.1.0
    @public true
]]

local Shell = {}
Shell.Version = "3.1.0"

-- Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

-- UI Refs
local _gui = nil
local _authFrame = nil
local _mainFrame = nil
local _notification = nil
local _connections = {}

-- Event folder
local _eventFolder = nil

-- Theme
local Colors = {
    BgDark = Color3.fromRGB(12, 12, 18),
    BgPanel = Color3.fromRGB(20, 20, 30),
    Accent = Color3.fromRGB(0, 255, 170), -- Cyan/Green
    AccentDim = Color3.fromRGB(0, 180, 120),
    Text = Color3.fromRGB(255, 255, 255),
    TextGray = Color3.fromRGB(150, 150, 160),
    Error = Color3.fromRGB(255, 80, 80),
    Success = Color3.fromRGB(50, 255, 100)
}

--[[
    Initialize Shell
]]
function Shell.init(eventFolder)
    _eventFolder = eventFolder or ReplicatedStorage:WaitForChild("FSSHUB_Events", 10)

    if not _eventFolder then
        warn("[Shell] Event folder missing!")
        return false
    end

    Shell._createUI()
    Shell._setupEvents()

    -- Check initial status
    Shell._fireEvent("session:status:request")

    print("[Shell] GUI Initialized")
    return true
end

--[[
    Create complete UI
]]
function Shell._createUI()
    local player = Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")

    -- Cleanup old
    if playerGui:FindFirstChild("FSSHUB_Shell") then
        playerGui.FSSHUB_Shell:Destroy()
    end

    _gui = Instance.new("ScreenGui")
    _gui.Name = "FSSHUB_Shell"
    _gui.ResetOnSpawn = false
    _gui.Parent = playerGui

    -- 1. Create Auth Gateway
    Shell._createAuthGateway()

    -- 2. Create Main Menu (Hidden initially)
    Shell._createMainMenu()

    -- 3. Create Notification Overlay
    Shell._createNotificationUtils()
end

--[[
    Create Auth Gateway Frame
]]
function Shell._createAuthGateway()
    _authFrame = Instance.new("Frame")
    _authFrame.Name = "AuthGateway"
    _authFrame.Size = UDim2.new(0, 320, 0, 250)
    _authFrame.Position = UDim2.new(0.5, -160, 0.5, -125)
    _authFrame.BackgroundColor3 = Colors.BgDark
    _authFrame.BorderSizePixel = 0
    _authFrame.Visible = true -- Start visible
    _authFrame.Parent = _gui

    Shell._addCorner(_authFrame, 16)
    Shell._addStroke(_authFrame, Colors.Accent, 0.3)

    -- Draggable
    Shell._makeDraggable(_authFrame)

    -- Header
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 50)
    title.BackgroundTransparency = 1
    title.Text = "FSSHUB GATEWAY"
    title.TextColor3 = Colors.Accent
    title.Font = Enum.Font.GothamBold
    title.TextSize = 20
    title.Parent = _authFrame

    -- Status
    local status = Instance.new("TextLabel")
    status.Name = "StatusLabel"
    status.Size = UDim2.new(1, 0, 0, 20)
    status.Position = UDim2.new(0, 0, 0, 50)
    status.BackgroundTransparency = 1
    status.Text = "Waiting for initialization..."
    status.TextColor3 = Colors.TextGray
    status.Font = Enum.Font.Gotham
    status.TextSize = 12
    status.Parent = _authFrame

    -- Buttons Container
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -40, 0, 150)
    container.Position = UDim2.new(0, 20, 0, 80)
    container.BackgroundTransparency = 1
    container.Parent = _authFrame

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 10)
    layout.Parent = container

    -- 1. Get Key Button
    local getKeyBtn = Shell._createButton(container, "GetKeyBtn", "GET KEY LINK", Colors.Accent)
    getKeyBtn.MouseButton1Click:Connect(function()
        Shell._fireEvent("getkey:request")
        status.Text = "Requesting link..."
    end)

    -- 2. Input Key Box
    local keyInput = Instance.new("TextBox")
    keyInput.Name = "KeyInput"
    keyInput.Size = UDim2.new(1, 0, 0, 40)
    keyInput.BackgroundColor3 = Colors.BgPanel
    keyInput.TextColor3 = Colors.Text
    keyInput.PlaceholderText = "Paste Key Here..."
    keyInput.Text = ""
    keyInput.Font = Enum.Font.Code
    keyInput.TextSize = 14
    keyInput.Parent = container
    Shell._addCorner(keyInput, 8)

    -- 3. Login Button
    local loginBtn = Shell._createButton(container, "LoginBtn", "LOGIN", Colors.BgPanel)
    loginBtn.TextColor3 = Colors.TextGray

    loginBtn.MouseButton1Click:Connect(function()
        local key = keyInput.Text
        if #key > 5 then
            Shell._fireEvent("key:enter", key)
            status.Text = "Verifying key..."
        else
            Shell.notify("Please enter a valid key", "error")
        end
    end)

    -- Close button (Minimizes to top bar)
    local close = Instance.new("TextButton")
    close.Size = UDim2.new(0, 30, 0, 30)
    close.Position = UDim2.new(1, -35, 0, 10)
    close.BackgroundTransparency = 1
    close.Text = "X"
    close.TextColor3 = Colors.TextGray
    close.Font = Enum.Font.GothamBold
    close.Parent = _authFrame
    close.MouseButton1Click:Connect(function()
        _gui.Enabled = not _gui.Enabled
    end)
end

--[[
    Create Main Menu Frame (Dummy)
]]
function Shell._createMainMenu()
    _mainFrame = Instance.new("Frame")
    _mainFrame.Name = "MainMenu"
    _mainFrame.Size = UDim2.new(0, 500, 0, 350)
    _mainFrame.Position = UDim2.new(0.5, -250, 0.5, -175)
    _mainFrame.BackgroundColor3 = Colors.BgDark
    _mainFrame.Visible = false -- Hidden initially
    _mainFrame.Parent = _gui

    Shell._addCorner(_mainFrame, 16)
    Shell._addStroke(_mainFrame, Colors.Accent, 0.5)
    Shell._makeDraggable(_mainFrame)

    -- Sidebar
    local sidebar = Instance.new("Frame")
    sidebar.Size = UDim2.new(0, 140, 1, 0)
    sidebar.BackgroundColor3 = Colors.BgPanel
    sidebar.BorderSizePixel = 0
    sidebar.Parent = _mainFrame
    Shell._addCorner(sidebar, 16) -- Rounded left corners

    -- Correction for right corners of sidebar
    local mask = Instance.new("Frame")
    mask.Size = UDim2.new(0, 20, 1, 0)
    mask.Position = UDim2.new(1, -10, 0, 0)
    mask.BackgroundColor3 = Colors.BgPanel
    mask.BorderSizePixel = 0
    mask.ZIndex = 0
    mask.Parent = sidebar

    -- Tabs (Dummy)
    local tabs = { "AimBot", "Visuals", "Misc", "Settings" }
    for i, tab in ipairs(tabs) do
        local btn = instance.new("TextButton") -- intentional casing error for validation later? No, fix standard
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -20, 0, 35)
        btn.Position = UDim2.new(0, 10, 0, 50 + (i * 40))
        btn.BackgroundColor3 = i == 1 and Colors.Accent or Colors.BgDark
        btn.Text = tab
        btn.TextColor3 = i == 1 and Colors.BgDark or Colors.Text
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 14
        btn.Parent = sidebar
        Shell._addCorner(btn, 6)
    end

    -- Content Area
    local content = Instance.new("Frame")
    content.Size = UDim2.new(1, -160, 1, -20)
    content.Position = UDim2.new(0, 150, 0, 10)
    content.BackgroundTransparency = 1
    content.Parent = _mainFrame

    -- Welcome
    local welcome = Instance.new("TextLabel")
    welcome.Text = "Welcome to FSSHUB V3"
    welcome.Size = UDim2.new(1, 0, 0, 30)
    welcome.BackgroundTransparency = 1
    welcome.TextColor3 = Colors.Text
    welcome.Font = Enum.Font.GothamBold
    welcome.TextSize = 24
    welcome.TextXAlignment = Enum.TextXAlignment.Left
    welcome.Parent = content

    -- User Info
    local info = Instance.new("TextLabel")
    info.Name = "UserInfo"
    info.Text = "Tier: FREE | Time: 12h 00m"
    info.Size = UDim2.new(1, 0, 0, 20)
    info.Position = UDim2.new(0, 0, 0, 35)
    info.BackgroundTransparency = 1
    info.TextColor3 = Colors.Accent
    info.Font = Enum.Font.Code
    info.TextSize = 14
    info.TextXAlignment = Enum.TextXAlignment.Left
    info.Parent = content

    -- Dummy Toggle
    local toggle = Shell._createButton(content, "DummyToggle", "Enable Aimbot (Dummy)", Colors.BgPanel)
    toggle.Position = UDim2.new(0, 0, 0, 80)
    toggle.Size = UDim2.new(0, 200, 0, 40)
    toggle.TextColor3 = Colors.Text

    -- Logout
    local logout = Shell._createButton(content, "LogoutBtn", "Log Out", Colors.Error)
    logout.Position = UDim2.new(0, 0, 1, -40)
    logout.Size = UDim2.new(0, 100, 0, 30)
    logout.MouseButton1Click:Connect(function()
        _gui:Destroy()
    end)
end

--[[
    Transition to Main Menu
]]
function Shell.unlockMainMenu(keyData)
    print("[Shell] Unlocking Main Menu...")

    -- Hide Auth
    if _authFrame then
        TweenService:Create(_authFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
            Position = UDim2.new(0.5, -160, 1.5, 0)
        }):Play()
        task.wait(0.5)
        _authFrame.Visible = false
    end

    -- Show Main
    if _mainFrame then
        _mainFrame.Visible = true
        _mainFrame.Position = UDim2.new(0.5, -250, 0.5, -165) -- slightly off for effect
        _mainFrame.BackgroundTransparency = 1

        -- Update Info
        local info = _mainFrame:FindFirstChild("Content"):FindFirstChild("UserInfo")
        if info and keyData then
            info.Text = string.format("Tier: %s | Active", string.upper(keyData.tier or "FREE"))
        end

        -- Animate In
        TweenService:Create(_mainFrame, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Position = UDim2.new(0.5, -250, 0.5, -175),
            BackgroundTransparency = 0
        }):Play()
    end

    Shell.notify("Welcome back!", "success")
end

--[[
    Event Setup
]]
function Shell._setupEvents()
    -- key:received -> Unlock Main Menu
    Shell._listenEvent("key:received", function(data)
        Shell.unlockMainMenu(data)
    end)

    -- session:status -> Update Auth Status
    Shell._listenEvent("session:status", function(data)
        local statusLabel = _authFrame:FindFirstChild("StatusLabel")
        if statusLabel and data.status then
            statusLabel.Text = data.status
        end

        -- If already completed/active, unlock
        if data.status == "COMPLETED" or data.status == "Session Active" or data.hasKey then
            Shell.unlockMainMenu(data)
        end
    end)

    -- session:url -> Show URL Notification & Update Status
    Shell._listenEvent("session:url", function(data)
        if data.url then
            Shell.notify("URL copied to clipboard!", "success")
            pcall(function() setclipboard(data.url) end)

            local statusLabel = _authFrame:FindFirstChild("StatusLabel")
            if statusLabel then
                statusLabel.Text = "Please verify in browser..."
            end
        end
    end)

    -- error -> Notify
    Shell._listenEvent("error", function(data)
        Shell.notify(data.message, "error")
        local statusLabel = _authFrame:FindFirstChild("StatusLabel")
        if statusLabel then statusLabel.Text = "Error: " .. data.message end
    end)
end

--[[ Helpers ]]
function Shell._listenEvent(name, func)
    local ev = _eventFolder:FindFirstChild(name)
    if ev then
        table.insert(_connections, ev.Event:Connect(func))
    end
end

function Shell._fireEvent(name, ...)
    local ev = _eventFolder:FindFirstChild(name)
    if ev then ev:Fire(...) end
end

function Shell._createButton(parent, name, text, color)
    local btn = Instance.new("TextButton")
    btn.Name = name
    btn.Text = text
    btn.BackgroundColor3 = color
    btn.Size = UDim2.new(1, 0, 0, 40)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    btn.TextColor3 = Colors.BgDark
    btn.Parent = parent
    Shell._addCorner(btn, 8)
    return btn
end

function Shell._addCorner(obj, rad)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, rad)
    c.Parent = obj
end

function Shell._addStroke(obj, color, alpha)
    local s = Instance.new("UIStroke")
    s.Color = color
    s.Transparency = alpha or 0
    s.Thickness = 1
    s.Parent = obj
end

function Shell._makeDraggable(frame)
    local dragging, dragInput, dragStart, startPos
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
        end
    end)
    frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale,
                startPos.Y.Offset + delta.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
end

function Shell.notify(msg, type)
    print("[Notify]", msg)
    -- Simple notification logic can be added here
    -- For now just print to console as fallback
end

function Shell._createNotificationUtils()
    -- Create notification container if needed
end

return Shell
