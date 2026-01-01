--[[
    FSSHUB V3 - EventBridge Module
    ==============================
    Communication bridge between Core and GUI Shell.

    Architecture:
    - GUI Shell is stateless, only displays what Core sends
    - All logic decisions happen in Core
    - Events are bidirectional via BindableEvents

    @module EventBridge
    @version 3.0.0
]]

local Session       -- Forward declaration
local FeatureLoader -- Forward declaration
local ApiClient     -- Forward declaration

local EventBridge = {}
EventBridge.__index = EventBridge

-- Private: Event connections
local _connections = {}
local _eventFolder = nil

-- Event names
EventBridge.Events = {
    -- Shell -> Core
    FEATURE_TOGGLE = "feature:toggle",
    FEATURE_LIST_REQUEST = "feature:list:request",
    SESSION_STATUS_REQUEST = "session:status:request",
    KEY_ENTER = "key:enter",
    GET_KEY_REQUEST = "getkey:request",

    -- Core -> Shell
    FEATURE_LIST = "feature:list",
    FEATURE_STATUS = "feature:status",
    SESSION_STATUS = "session:status",
    SESSION_URL = "session:url",
    KEY_RECEIVED = "key:received",
    FORCE_LOGOUT = "session:force_logout",
    ERROR = "error",
    NOTIFICATION = "notification",
}

--[[
    Initialize EventBridge with module references

    @param modules table - { Session, FeatureLoader, ApiClient }
    @param eventFolder Instance - Folder containing BindableEvents
]]
function EventBridge.init(modules, eventFolder)
    Session = modules.Session
    FeatureLoader = modules.FeatureLoader
    ApiClient = modules.ApiClient

    _eventFolder = eventFolder or EventBridge._createEventFolder()

    -- Setup event listeners
    EventBridge._setupListeners()

    print("[EventBridge] Initialized")
end

--[[
    Create event folder with all BindableEvents
    Checks if already exists first (from Loader)

    @return Instance - Event folder
]]
function EventBridge._createEventFolder()
    local folder = game:GetService("ReplicatedStorage"):FindFirstChild("FSSHUB_Events")

    if not folder then
        folder = Instance.new("Folder")
        folder.Name = "FSSHUB_Events"
        folder.Parent = game:GetService("ReplicatedStorage")
    end

    -- Create all events if missing
    for name, eventName in pairs(EventBridge.Events) do
        if not folder:FindFirstChild(eventName) then
            local event = Instance.new("BindableEvent")
            event.Name = eventName
            event.Parent = folder
        end
    end

    return folder
end

--[[
    Get event by name

    @param eventName string - Event name from EventBridge.Events
    @return BindableEvent|nil - Event instance or nil
]]
function EventBridge.getEvent(eventName)
    if not _eventFolder then
        return nil
    end
    return _eventFolder:FindFirstChild(eventName)
end

--[[
    Fire event to Shell

    @param eventName string - Event name
    @param ... any - Event arguments
]]
function EventBridge.fire(eventName, ...)
    local event = EventBridge.getEvent(eventName)
    if event then
        event:Fire(...)
    else
        warn("[EventBridge] Event not found: " .. eventName)
    end
end

--[[
    Setup listeners for Shell -> Core events
]]
function EventBridge._setupListeners()
    -- Feature toggle request
    EventBridge._listen(EventBridge.Events.FEATURE_TOGGLE, function(featureId)
        EventBridge._handleFeatureToggle(featureId)
    end)

    -- Feature list request
    EventBridge._listen(EventBridge.Events.FEATURE_LIST_REQUEST, function()
        EventBridge._handleFeatureListRequest()
    end)

    -- Session status request
    EventBridge._listen(EventBridge.Events.SESSION_STATUS_REQUEST, function()
        EventBridge._handleSessionStatusRequest()
    end)

    -- Key enter request
    EventBridge._listen(EventBridge.Events.KEY_ENTER, function(key)
        EventBridge._handleKeyEnter(key)
    end)

    -- Get key request (start auth flow)
    EventBridge._listen(EventBridge.Events.GET_KEY_REQUEST, function()
        EventBridge._handleGetKeyRequest()
    end)
end

--[[
    Listen to event from Shell

    @param eventName string - Event name
    @param callback function - Handler function
]]
function EventBridge._listen(eventName, callback)
    local event = EventBridge.getEvent(eventName)
    if event then
        local connection = event.Event:Connect(function(...)
            -- Wrap in pcall for safety
            local success, err = pcall(callback, ...)
            if not success then
                warn("[EventBridge] Handler error for " .. eventName .. ": " .. tostring(err))
                EventBridge.fire(EventBridge.Events.ERROR, {
                    source = eventName,
                    message = tostring(err)
                })
            end
        end)
        table.insert(_connections, connection)
    end
end

--[[
    Handle feature toggle request from Shell

    @param featureId string - Feature ID to toggle
]]
function EventBridge._handleFeatureToggle(featureId)
    if not featureId then
        EventBridge.fire(EventBridge.Events.ERROR, {
            message = "Feature ID required"
        })
        return
    end

    -- Get or create feature instance
    local feature = FeatureLoader.get(featureId) or FeatureLoader.new(featureId)
    local isRunning, err = feature:toggle()

    -- Send status update to Shell
    EventBridge.fire(EventBridge.Events.FEATURE_STATUS, {
        id = featureId,
        running = isRunning,
        error = err,
    })
end

--[[
    Handle feature list request from Shell
]]
function EventBridge._handleFeatureListRequest()
    if not ApiClient then
        EventBridge.fire(EventBridge.Events.ERROR, {
            message = "Not initialized"
        })
        return
    end

    local data, err = ApiClient.getFeatureList(game.PlaceId)

    if data and data.success then
        -- Add running status to each feature
        local features = {}
        for _, f in ipairs(data.features or {}) do
            local active = FeatureLoader.get(f.id)
            table.insert(features, {
                id = f.id,
                name = f.name,
                description = f.description,
                tier = f.tier,
                running = active and active:isRunning() or false,
            })
        end

        EventBridge.fire(EventBridge.Events.FEATURE_LIST, {
            features = features,
            tier = data.tier,
            count = #features,
        })
    else
        EventBridge.fire(EventBridge.Events.ERROR, {
            message = err or "Failed to fetch features"
        })
    end
end

--[[
    Handle session status request from Shell
]]
function EventBridge._handleSessionStatusRequest()
    local session = Session and Session.getActive()

    if session then
        local keyData = session:getKeyData()

        EventBridge.fire(EventBridge.Events.SESSION_STATUS, {
            active = true,
            status = session:getStatus(),
            hasKey = keyData ~= nil,
            tier = keyData and keyData.tier or nil,
            streakCount = keyData and keyData.streakCount or 0,
        })
    else
        EventBridge.fire(EventBridge.Events.SESSION_STATUS, {
            active = false,
            status = "NONE",
        })
    end
end

--[[
    Handle key enter from Shell

    @param key string - Key entered by user
]]
function EventBridge._handleKeyEnter(key)
    if not key or key == "" then
        EventBridge.fire(EventBridge.Events.ERROR, {
            message = "Key required"
        })
        return
    end

    -- TODO: Implement key validation via Worker
    -- For now, just notify
    EventBridge.fire(EventBridge.Events.NOTIFICATION, {
        type = "info",
        message = "Key validation not yet implemented"
    })
end

--[[
    Handle get key request (start auth flow)
]]
function EventBridge._handleGetKeyRequest()
    if not ApiClient then
        EventBridge.fire(EventBridge.Events.ERROR, {
            message = "Not initialized"
        })
        return
    end

    local data, err = ApiClient.initSession()

    if data and data.success then
        -- Create session
        local session = Session.new(data)

        -- Send URL to Shell for display
        EventBridge.fire(EventBridge.Events.SESSION_URL, {
            url = data.url,
            expiresIn = data.expires_in,
        })

        -- Start waiting for key in background
        task.spawn(function()
            local success = session:waitForKey()

            if success then
                local keyData = session:getKeyData()
                EventBridge.fire(EventBridge.Events.KEY_RECEIVED, {
                    key = keyData.key,
                    tier = keyData.tier,
                    expiresAt = keyData.expireAt,
                    streakCount = keyData.streakCount,
                })

                -- Start heartbeat for force logout detection
                session:startHeartbeat(30, function(reason)
                    EventBridge.fire(EventBridge.Events.FORCE_LOGOUT, {
                        reason = reason
                    })
                    FeatureLoader.stopAll()
                end)
            else
                EventBridge.fire(EventBridge.Events.ERROR, {
                    message = "Key verification timeout or expired"
                })
            end
        end)
    else
        EventBridge.fire(EventBridge.Events.ERROR, {
            message = err or "Failed to start session"
        })
    end
end

--[[
    Send force logout event and cleanup

    @param reason string - Logout reason (expired/banned)
]]
function EventBridge.forceLogout(reason)
    print("[EventBridge] Force logout: " .. tostring(reason))

    -- Stop all features
    FeatureLoader.stopAll()

    -- Destroy session
    local session = Session and Session.getActive()
    if session then
        session:destroy()
    end

    -- Notify Shell
    EventBridge.fire(EventBridge.Events.FORCE_LOGOUT, {
        reason = reason
    })
end

--[[
    Disconnect all event listeners
]]
function EventBridge.disconnect()
    for _, connection in ipairs(_connections) do
        if connection.Connected then
            connection:Disconnect()
        end
    end
    _connections = {}

    -- Clean up event folder
    if _eventFolder then
        _eventFolder:Destroy()
        _eventFolder = nil
    end

    print("[EventBridge] Disconnected")
end

return EventBridge
