--[[
    FSSHUB V3 - Shell GUI Module
    ============================
    DUMB UI ONLY - Safe for public repository.

    Architecture:
    - Auth Gateway: Initial screen for key verification
    - Main Menu: Unlocked after valid key received

    @module Shell
    @version 3.2.0
    @public true
]]

local Shell = {}
Shell.Version = "3.2.0"

-- Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

-- UI Refs
local _gui = nil
local _authFrame = nil
local _mainFrame = nil
local _notificationContainer = nil
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
    Success = Color3.fromRGB(50, 255, 100),
    Input = Color3.fromRGB(30, 30, 45)
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

    print("[Shell] GUI Initialized v" .. Shell.Version)
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

    -- 3. Notification Container
    _notificationContainer = Instance.new("Frame")
    _notificationContainer.Name = "NotificationContainer"
    _notificationContainer.Size = UDim2.new(0, 300, 1, -20)
    _notificationContainer.Position = UDim2.new(1, -320, 0, 10)
    _notificationContainer.BackgroundTransparency = 1
    _notificationContainer.Parent = _gui

    local notifLayout = Instance.new("UIListLayout")
    notifLayout.SortOrder = Enum.SortOrder.LayoutOrder
    notifLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    notifLayout.Padding = UDim.new(0, 10)
    notifLayout.Parent = _notificationContainer
end

--[[
    Create Auth Gateway Frame
]]
function Shell._createAuthGateway()
    _authFrame = Instance.new("Frame")
    _authFrame.Name = "AuthGateway"
    _authFrame.Size = UDim2.new(0, 320, 0, 220)
    _authFrame.Position = UDim2.new(0.5, -160, 0.5, -110)
    _authFrame.BackgroundColor3 = Colors.BgDark
    _authFrame.BorderSizePixel = 0
    _authFrame.Visible = true -- Start visible
    _authFrame.Parent = _gui

    Shell._addCorner(_authFrame, 16)
    Shell._addStroke(_authFrame, Colors.Accent, 0.3)
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

    -- Instructions
    local instructions = Instance.new("TextLabel")
    instructions.Size = UDim2.new(1, -40, 0, 30)
    instructions.Position = UDim2.new(0, 20, 0, 45)
    instructions.BackgroundTransparency = 1
    instructions.Text = "Please complete verification to continue"
    instructions.TextColor3 = Colors.TextGray
    instructions.Font = Enum.Font.RobotoMono
    instructions.TextSize = 11
    instructions.Parent = _authFrame

    -- Buttons Container
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -40, 0, 120)
    container.Position = UDim2.new(0, 20, 0, 80)
    container.BackgroundTransparency = 1
    container.Parent = _authFrame

    -- 1. Get Key Button
    local getKeyBtn = Shell._createButton(container, "GetKeyBtn", "GET KEY", Colors.Accent, 1)
    getKeyBtn.MouseButton1Click:Connect(function()
        Shell._fireEvent("getkey:request")
        -- Visual feedback
        getKeyBtn.Text = "REQUESTING..."
        task.delay(1, function() getKeyBtn.Text = "GET KEY" end)
    end)

    -- 2. Input Key Box
    local keyInput = Instance.new("TextBox")
    keyInput.Name = "KeyInput"
    keyInput.Size = UDim2.new(1, 0, 0, 35)
    keyInput.Position = UDim2.new(0, 0, 0, 45)
    keyInput.BackgroundColor3 = Colors.Input
    keyInput.TextColor3 = Colors.Text
    keyInput.PlaceholderText = "Paste Key Here..."
    keyInput.PlaceholderColor3 = Colors.TextGray
    keyInput.Text = ""
    keyInput.Font = Enum.Font.Code
    keyInput.TextSize = 13
    keyInput.Parent = container
    Shell._addCorner(keyInput, 8)
    Shell._addStroke(keyInput, Colors.BgPanel, 0.5)

    keyInput.Focused:Connect(function()
        Shell._animateStroke(keyInput, Colors.Accent, 0.5)
    end)

    keyInput.FocusLost:Connect(function()
        Shell._animateStroke(keyInput, Colors.BgPanel, 0.5)
    end)

    -- 3. Login Button
    local loginBtn = Shell._createButton(container, "LoginBtn", "LOGIN", Colors.BgPanel, 2)
    loginBtn.Position = UDim2.new(0, 0, 0, 90)
    loginBtn.TextColor3 = Colors.Accent

    loginBtn.MouseButton1Click:Connect(function()
        local key = keyInput.Text
        if #key > 5 then
            Shell._fireEvent("key:enter", key)
        else
            Shell._invalidKeyEffect()
        end
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
    Shell._addCorner(sidebar, 16)

    -- Mask for smooth integration
    local mask = Instance.new("Frame")
    mask.Size = UDim2.new(0, 20, 1, 0)
    mask.Position = UDim2.new(1, -10, 0, 0)
    mask.BackgroundColor3 = Colors.BgPanel
    mask.BorderSizePixel = 0
    mask.ZIndex = 0
    mask.Parent = sidebar

    -- Tabs
    local tabs = { "AimBot", "Visuals", "Misc", "Settings" }
    for i, tab in ipairs(tabs) do
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

    -- Buttons
    local toggle = Shell._createButton(content, "Toggle", "Enable Aimbot", Colors.BgPanel, 0)
    toggle.Size = UDim2.new(0, 200, 0, 40)
    toggle.Position = UDim2.new(0, 0, 0, 60)
    toggle.TextColor3 = Colors.Text

    -- Logout
    local logout = Shell._createButton(content, "Logout", "Log Out", Colors.Error, 0)
    logout.Size = UDim2.new(0, 100, 0, 30)
    logout.Position = UDim2.new(0, 0, 1, -40)
    logout.MouseButton1Click:Connect(function()
        _gui:Destroy()
    end)
end

--[[ Transitions & Effects ]]

function Shell.unlockMainMenu(keyData)
    if _authFrame then
        TweenService:Create(_authFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
            Position = UDim2.new(0.5, -160, 1.5, 0)
        }):Play()
        task.wait(0.5)
        _authFrame.Visible = false
    end

    if _mainFrame then
        _mainFrame.Visible = true
        _mainFrame.BackgroundTransparency = 1
        TweenService:Create(_mainFrame, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Position = UDim2.new(0.5, -250, 0.5, -175),
            BackgroundTransparency = 0
        }):Play()
    end
    Shell.notify("Welcome back! Key active.", "success")
end

function Shell._invalidKeyEffect()
    local input = _authFrame:FindFirstChild("Frame"):FindFirstChild("KeyInput")
    if input then
        -- Shake
        local pos = input.Position
        for i = 1, 6 do
            input.Position = pos + UDim2.new(0, math.random(-5, 5), 0, 0)
            task.wait(0.05)
        end
        input.Position = pos

        -- Red Border
        Shell._animateStroke(input, Colors.Error, 0)
        input.Text = ""
        input.PlaceholderText = "Invalid Key!"
        input.PlaceholderColor3 = Colors.Error

        task.delay(1.5, function()
            Shell._animateStroke(input, Colors.BgPanel, 0.5)
            input.PlaceholderText = "Paste Key Here..."
            input.PlaceholderColor3 = Colors.TextGray
        end)
    end
    Shell.notify("Invalid Key", "error")
end

function Shell._animateStroke(obj, color, alpha)
    local stroke = obj:FindFirstChild("UIStroke")
    if stroke then
        TweenService:Create(stroke, TweenInfo.new(0.3), {
            Color = color,
            Transparency = alpha
        }):Play()
    end
end

--[[ Notifications ]]

function Shell.notify(msg, type)
    if not _notificationContainer then return end

    local color = type == "error" and Colors.Error or (type == "success" and Colors.Success or Colors.Accent)

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 40)
    frame.BackgroundColor3 = Colors.BgPanel
    frame.BorderSizePixel = 0
    frame.Parent = _notificationContainer
    Shell._addCorner(frame, 6)
    Shell._addStroke(frame, color, 0.5)

    local text = Instance.new("TextLabel")
    text.Size = UDim2.new(1, -20, 1, 0)
    text.Position = UDim2.new(0, 10, 0, 0)
    text.BackgroundTransparency = 1
    text.Text = msg
    text.TextColor3 = Colors.Text
    text.Font = Enum.Font.Gotham
    text.TextSize = 14
    text.TextXAlignment = Enum.TextXAlignment.Left
    text.Parent = frame

    -- Animate In
    frame.BackgroundTransparency = 1
    text.TextTransparency = 1
    TweenService:Create(frame, TweenInfo.new(0.3), { BackgroundTransparency = 0.1 }):Play()
    TweenService:Create(text, TweenInfo.new(0.3), { TextTransparency = 0 }):Play()

    -- Cleanup
    task.delay(3, function()
        TweenService:Create(frame, TweenInfo.new(0.3), { BackgroundTransparency = 1 }):Play()
        TweenService:Create(text, TweenInfo.new(0.3), { TextTransparency = 1 }):Play()
        task.wait(0.3)
        frame:Destroy()
    end)
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
        if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end
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

--[[ Event Setup ]]

function Shell._setupEvents()
    -- key:received -> Unlock
    Shell._listenEvent("key:received", function(data)
        Shell.unlockMainMenu(data)
    end)

    -- session:status -> Auto login if completed
    Shell._listenEvent("session:status", function(data)
        if data.status == "COMPLETED" or data.status == "Session Active" or data.hasKey then
            Shell.unlockMainMenu(data)
        end
        -- We ignore other statuses (PENDING etc) to keep UI clean as requested
    end)

    -- session:url -> Notify
    Shell._listenEvent("session:url", function(data)
        if data.url then
            Shell.notify("Link copied to clipboard!", "success")
            pcall(function() setclipboard(data.url) end)
        end
    end)

    -- error -> Invalid Key Effect
    Shell._listenEvent("error", function(data)
        Shell._invalidKeyEffect()
        -- Also show specific message if needed
        -- Shell.notify(data.message, "error")
    end)
end

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

function Shell._createButton(parent, name, text, color, order)
    local btn = Instance.new("TextButton")
    btn.Name = name
    btn.Text = text
    btn.BackgroundColor3 = color
    btn.Size = UDim2.new(1, 0, 0, 40)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    btn.TextColor3 = Colors.BgDark
    btn.Parent = parent
    -- btn.LayoutOrder = order -- container uses UIListLayout
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

return Shell
