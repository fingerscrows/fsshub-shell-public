--[[
    FSSHUB V3 - Session Watchdog
    ============================
    Background session validation.
    Pings server every 60s, force logout if revoked.
]]

local SessionWatchdog = {}

local PING_INTERVAL = 60 -- seconds
local Running = false
local WatchdogThread = nil

-- Get FSSHUB_LOADER and Shell from global
local function getGlobals()
    local genv = getgenv and getgenv() or _G or shared
    return genv.FSSHUB_LOADER, genv.FSSHUB_SHELL
end

-- Force logout and cleanup
local function forceLogout(reason)
    local Loader, Shell = getGlobals()

    if Shell and Shell.Events then
        Shell.Events.Notification:Fire("Session", reason or "Session ended", 10)
    end

    -- Transition to AUTH_REQUIRED
    if Loader and Loader.StateMachine then
        pcall(function()
            Loader.StateMachine.Transition("AUTH_REQUIRED")
        end)
    end

    -- Clear saved key
    if Loader and Loader.SafeDelete then
        Loader.SafeDelete()
    end

    print("[Watchdog] Session ended: " .. tostring(reason))
end

-- Ping server to validate session
local function pingSession()
    local Loader = getGlobals()
    if not Loader or not Loader.ApiClient then return true end

    local success, result = pcall(function()
        return Loader.ApiClient.ValidateSession()
    end)

    if not success then
        -- Network error, don't force logout
        warn("[Watchdog] Ping failed (network)")
        return true
    end

    return result == true
end

-- Start watchdog
function SessionWatchdog.Start()
    if Running then return end
    Running = true

    WatchdogThread = task.spawn(function()
        while Running do
            task.wait(PING_INTERVAL)

            if not Running then break end

            local valid = pingSession()
            if not valid then
                forceLogout("Session revoked by server")
                SessionWatchdog.Stop()
                break
            end
        end
    end)

    print("[Watchdog] Started")
end

-- Stop watchdog
function SessionWatchdog.Stop()
    Running = false
    if WatchdogThread then
        pcall(function() task.cancel(WatchdogThread) end)
        WatchdogThread = nil
    end
    print("[Watchdog] Stopped")
end

-- Check if running
function SessionWatchdog.IsRunning()
    return Running
end

return SessionWatchdog
