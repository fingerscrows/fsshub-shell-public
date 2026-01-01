--[[
    FSSHUB V3 - Shell GUI Module
    ============================
    DUMB UI ONLY - Safe for public repository.

    This module ONLY handles:
    - Rendering UI elements
    - Listening to events from Core
    - Firing events to Core on user actions

    NO business logic, NO API calls, NO validation.
    All logic is handled by Core (served from private Worker).

    @module Shell
    @version 3.0.0
    @public true
]]

local Shell = {}
Shell.Version = "3.0.0"

-- Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- UI References (set after creation)
local _gui = nil
local _mainFrame = nil
local _statusLabel = nil
local _keyDisplay = nil
local _urlDisplay = nil
local _featureContainer = nil

-- Event folder reference
local _eventFolder = nil

-- Connection storage for cleanup
local _connections = {}

-- UI Color Scheme (Cyberpunk theme)
local Colors = {
    Background = Color3.fromRGB(15, 15, 25),
    Panel = Color3.fromRGB(25, 25, 40),
    Primary = Color3.fromRGB(0, 255, 200),
    Secondary = Color3.fromRGB(255, 50, 100),
    Text = Color3.fromRGB(255, 255, 255),
    TextMuted = Color3.fromRGB(150, 150, 170),
    Success = Color3.fromRGB(50, 255, 100),
    Error = Color3.fromRGB(255, 80, 80),
    Input = Color3.fromRGB(35, 35, 55),
}

--[[
    Initialize Shell GUI

    @param eventFolder Instance - FSSHUB_Events folder (created by Core)
]]
function Shell.init(eventFolder)
    _eventFolder = eventFolder or ReplicatedStorage:WaitForChild("FSSHUB_Events", 10)

    if not _eventFolder then
        warn("[Shell] Event folder not found - Core not initialized?")
        return false
    end

    -- Create UI
    Shell._createUI()

    -- Setup event listeners
    Shell._setupEventListeners()

    -- Request initial status
    Shell._fireEvent("session:status:request")

    print("[Shell] Initialized v" .. Shell.Version)
    return true
end

--[[
    Create all UI elements
]]
function Shell._createUI()
    local player = Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")

    -- Main ScreenGui
    _gui = Instance.new("ScreenGui")
    _gui.Name = "FSSHUB_Shell"
    _gui.ResetOnSpawn = false
    _gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    _gui.Parent = playerGui

    -- Main Container Frame
    _mainFrame = Instance.new("Frame")
    _mainFrame.Name = "MainFrame"
    _mainFrame.Size = UDim2.new(0, 350, 0, 400)
    _mainFrame.Position = UDim2.new(0.5, -175, 0.5, -200)
    _mainFrame.BackgroundColor3 = Colors.Background
    _mainFrame.BorderSizePixel = 0
    _mainFrame.Parent = _gui

    -- Corner radius
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = _mainFrame

    -- Border stroke
    local stroke = Instance.new("UIStroke")
    stroke.Color = Colors.Primary
    stroke.Thickness = 2
    stroke.Transparency = 0.5
    stroke.Parent = _mainFrame

    -- Header
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 50)
    header.BackgroundColor3 = Colors.Panel
    header.BorderSizePixel = 0
    header.Parent = _mainFrame

    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 12)
    headerCorner.Parent = header

    -- Title
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, -60, 1, 0)
    title.Position = UDim2.new(0, 15, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "FSSHUB V3"
    title.TextColor3 = Colors.Primary
    title.TextSize = 20
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = header

    -- Close button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "CloseBtn"
    closeBtn.Size = UDim2.new(0, 30, 0, 30)
    closeBtn.Position = UDim2.new(1, -40, 0.5, -15)
    closeBtn.BackgroundColor3 = Colors.Secondary
    closeBtn.Text = "X"
    closeBtn.TextColor3 = Colors.Text
    closeBtn.TextSize = 16
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.Parent = header

    local closeBtnCorner = Instance.new("UICorner")
    closeBtnCorner.CornerRadius = UDim.new(0, 6)
    closeBtnCorner.Parent = closeBtn

    closeBtn.MouseButton1Click:Connect(function()
        Shell.toggle()
    end)

    -- Content container
    local content = Instance.new("Frame")
    content.Name = "Content"
    content.Size = UDim2.new(1, -30, 1, -70)
    content.Position = UDim2.new(0, 15, 0, 60)
    content.BackgroundTransparency = 1
    content.Parent = _mainFrame

    local contentLayout = Instance.new("UIListLayout")
    contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
    contentLayout.Padding = UDim.new(0, 10)
    contentLayout.Parent = content

    -- Status Display
    _statusLabel = Shell._createLabel(content, "StatusLabel", "Status: Initializing...", 1)

    -- URL Display (hidden initially)
    _urlDisplay = Shell._createLabel(content, "URLDisplay", "", 2)
    _urlDisplay.TextWrapped = true
    _urlDisplay.Visible = false

    -- Key Display (hidden initially)
    _keyDisplay = Shell._createLabel(content, "KeyDisplay", "", 3)
    _keyDisplay.TextColor3 = Colors.Success
    _keyDisplay.TextSize = 14
    _keyDisplay.Visible = false

    -- Get Key Button
    local getKeyBtn = Shell._createButton(content, "GetKeyBtn", "🔑 Get Key", 4)
    getKeyBtn.MouseButton1Click:Connect(function()
        Shell._fireEvent("getkey:request")
        _statusLabel.Text = "Status: Requesting key..."
    end)

    -- Separator
    local sep = Instance.new("Frame")
    sep.Name = "Separator"
    sep.Size = UDim2.new(1, 0, 0, 1)
    sep.BackgroundColor3 = Colors.TextMuted
    sep.BackgroundTransparency = 0.7
    sep.BorderSizePixel = 0
    sep.LayoutOrder = 5
    sep.Parent = content

    -- Key Input Section
    local inputLabel = Shell._createLabel(content, "InputLabel", "Or enter key manually:", 6)
    inputLabel.TextSize = 12
    inputLabel.TextColor3 = Colors.TextMuted

    local keyInput = Instance.new("TextBox")
    keyInput.Name = "KeyInput"
    keyInput.Size = UDim2.new(1, 0, 0, 35)
    keyInput.BackgroundColor3 = Colors.Input
    keyInput.BorderSizePixel = 0
    keyInput.Text = ""
    keyInput.PlaceholderText = "FSSHUB-XXXX-XXXX-XXXX-XXXX"
    keyInput.PlaceholderColor3 = Colors.TextMuted
    keyInput.TextColor3 = Colors.Text
    keyInput.TextSize = 12
    keyInput.Font = Enum.Font.Code
    keyInput.LayoutOrder = 7
    keyInput.ClearTextOnFocus = false
    keyInput.Parent = content

    local inputCorner = Instance.new("UICorner")
    inputCorner.CornerRadius = UDim.new(0, 6)
    inputCorner.Parent = keyInput

    -- Verify Button
    local verifyBtn = Shell._createButton(content, "VerifyBtn", "✓ Verify Key", 8)
    verifyBtn.BackgroundColor3 = Colors.Success
    verifyBtn.MouseButton1Click:Connect(function()
        local key = keyInput.Text
        if key and key ~= "" then
            Shell._fireEvent("key:enter", key)
            _statusLabel.Text = "Status: Verifying key..."
        end
    end)

    -- Feature Container (for toggle buttons)
    _featureContainer = Instance.new("Frame")
    _featureContainer.Name = "FeatureContainer"
    _featureContainer.Size = UDim2.new(1, 0, 0, 100)
    _featureContainer.BackgroundTransparency = 1
    _featureContainer.LayoutOrder = 10
    _featureContainer.Visible = false
    _featureContainer.Parent = content

    local featureLayout = Instance.new("UIListLayout")
    featureLayout.SortOrder = Enum.SortOrder.LayoutOrder
    featureLayout.Padding = UDim.new(0, 5)
    featureLayout.Parent = _featureContainer

    print("[Shell] UI Created")
end

--[[
    Create a styled label
]]
function Shell._createLabel(parent, name, text, order)
    local label = Instance.new("TextLabel")
    label.Name = name
    label.Size = UDim2.new(1, 0, 0, 25)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Colors.Text
    label.TextSize = 14
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.LayoutOrder = order
    label.Parent = parent
    return label
end

--[[
    Create a styled button
]]
function Shell._createButton(parent, name, text, order)
    local btn = Instance.new("TextButton")
    btn.Name = name
    btn.Size = UDim2.new(1, 0, 0, 40)
    btn.BackgroundColor3 = Colors.Primary
    btn.BorderSizePixel = 0
    btn.Text = text
    btn.TextColor3 = Colors.Background
    btn.TextSize = 14
    btn.Font = Enum.Font.GothamBold
    btn.LayoutOrder = order
    btn.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = btn

    -- Hover effect
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2), {
            BackgroundTransparency = 0.2
        }):Play()
    end)

    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2), {
            BackgroundTransparency = 0
        }):Play()
    end)

    return btn
end

--[[
    Setup event listeners (Core -> Shell)
]]
function Shell._setupEventListeners()
    -- Session URL received
    Shell._listenEvent("session:url", function(data)
        if data and data.url then
            _urlDisplay.Text = "Open: " .. data.url
            _urlDisplay.Visible = true
            _statusLabel.Text = "Status: Waiting for verification..."

            -- Try to copy to clipboard
            pcall(function()
                setclipboard(data.url)
            end)
        end
    end)

    -- Session status update
    Shell._listenEvent("session:status", function(data)
        if data then
            if data.hasKey then
                _statusLabel.Text = "Status: Key Active (" .. (data.tier or "free") .. ")"
                _statusLabel.TextColor3 = Colors.Success
                _featureContainer.Visible = true

                -- Request feature list
                Shell._fireEvent("feature:list:request")
            else
                _statusLabel.Text = "Status: " .. (data.status or "Unknown")
            end
        end
    end)

    -- Key received
    Shell._listenEvent("key:received", function(data)
        if data and data.key then
            _keyDisplay.Text = "Key: " .. data.key
            _keyDisplay.Visible = true
            _urlDisplay.Visible = false
            _statusLabel.Text = "Status: Key Active!"
            _statusLabel.TextColor3 = Colors.Success
            _featureContainer.Visible = true

            -- Request feature list
            Shell._fireEvent("feature:list:request")
        end
    end)

    -- Feature list received
    Shell._listenEvent("feature:list", function(data)
        if data and data.features then
            Shell._populateFeatures(data.features)
        end
    end)

    -- Feature status update
    Shell._listenEvent("feature:status", function(data)
        if data and data.id then
            Shell._updateFeatureButton(data.id, data.running)
        end
    end)

    -- Error received
    Shell._listenEvent("error", function(data)
        if data and data.message then
            _statusLabel.Text = "Error: " .. data.message
            _statusLabel.TextColor3 = Colors.Error
        end
    end)

    -- Notification received
    Shell._listenEvent("notification", function(data)
        if data and data.message then
            print("[Shell] " .. data.message)
        end
    end)

    -- Force logout
    Shell._listenEvent("session:force_logout", function(data)
        _statusLabel.Text = "Logged out: " .. (data and data.reason or "Session ended")
        _statusLabel.TextColor3 = Colors.Error
        _keyDisplay.Visible = false
        _featureContainer.Visible = false
    end)
end

--[[
    Listen to event from Core
]]
function Shell._listenEvent(eventName, callback)
    if not _eventFolder then return end

    local event = _eventFolder:FindFirstChild(eventName)
    if event then
        local conn = event.Event:Connect(function(...)
            pcall(callback, ...)
        end)
        table.insert(_connections, conn)
    end
end

--[[
    Fire event to Core
]]
function Shell._fireEvent(eventName, ...)
    if not _eventFolder then return end

    local event = _eventFolder:FindFirstChild(eventName)
    if event then
        event:Fire(...)
    end
end

--[[
    Populate feature toggle buttons
]]
function Shell._populateFeatures(features)
    -- Clear existing
    for _, child in ipairs(_featureContainer:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end

    -- Create buttons
    for i, feature in ipairs(features) do
        local btn = Instance.new("TextButton")
        btn.Name = "Feature_" .. feature.id
        btn.Size = UDim2.new(1, 0, 0, 30)
        btn.BackgroundColor3 = feature.running and Colors.Success or Colors.Panel
        btn.BorderSizePixel = 0
        btn.Text = (feature.running and "● " or "○ ") .. feature.name
        btn.TextColor3 = Colors.Text
        btn.TextSize = 12
        btn.Font = Enum.Font.Gotham
        btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.LayoutOrder = i
        btn.Parent = _featureContainer

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 6)
        corner.Parent = btn

        btn.MouseButton1Click:Connect(function()
            Shell._fireEvent("feature:toggle", feature.id)
        end)
    end

    -- Adjust container size
    _featureContainer.Size = UDim2.new(1, 0, 0, #features * 35)
end

--[[
    Update feature button state
]]
function Shell._updateFeatureButton(featureId, running)
    local btn = _featureContainer:FindFirstChild("Feature_" .. featureId)
    if btn then
        btn.BackgroundColor3 = running and Colors.Success or Colors.Panel
        local name = btn.Text:gsub("^[●○] ", "")
        btn.Text = (running and "● " or "○ ") .. name
    end
end

--[[
    Toggle GUI visibility
]]
function Shell.toggle()
    if _mainFrame then
        _mainFrame.Visible = not _mainFrame.Visible
    end
end

--[[
    Show GUI
]]
function Shell.show()
    if _mainFrame then
        _mainFrame.Visible = true
    end
end

--[[
    Hide GUI
]]
function Shell.hide()
    if _mainFrame then
        _mainFrame.Visible = false
    end
end

--[[
    Cleanup and destroy Shell
]]
function Shell.destroy()
    -- Disconnect all events
    for _, conn in ipairs(_connections) do
        if conn.Connected then
            conn:Disconnect()
        end
    end
    _connections = {}

    -- Destroy GUI
    if _gui then
        _gui:Destroy()
        _gui = nil
    end

    print("[Shell] Destroyed")
end

return Shell
