--[[
    FSSHUB V3 - Remote Config
    =========================
    Fetches server-driven configuration on Shell start.
    Controls: MOTD, maintenance, theme, feature visibility.
]]

local RemoteConfig = {}

local Config = {
    motd = nil,
    maintenance = false,
    theme = "dark",
    accent = "cyan",
    features = {}
}

-- Get FSSHUB_LOADER from global
local function getLoader()
    local genv = getgenv and getgenv() or _G or shared
    return genv.FSSHUB_LOADER
end

-- Fetch remote config from server
function RemoteConfig.Fetch()
    local Loader = getLoader()
    if not Loader or not Loader.ApiClient then
        warn("[RemoteConfig] No ApiClient available")
        return Config
    end

    -- Use existing /control/status for basic config
    local success, statusData = pcall(function()
        return Loader.ApiClient.GetStatus()
    end)

    if success and statusData then
        Config.maintenance = statusData.maintenance or false
        Config.motd = statusData.motd
    end

    -- Fetch features if session exists
    if Loader.Session and Loader.Session.GetSessionId() then
        local featSuccess, features = pcall(function()
            return Loader.ApiClient.GetFeatures()
        end)

        if featSuccess and features then
            Config.features = features
        end
    end

    return Config
end

-- Get current config (cached)
function RemoteConfig.Get()
    return Config
end

-- Check if feature is enabled server-side
function RemoteConfig.IsFeatureEnabled(featureId)
    for _, feat in ipairs(Config.features) do
        if feat.id == featureId then
            return feat.enabled ~= false
        end
    end
    return false
end

-- Get MOTD
function RemoteConfig.GetMOTD()
    return Config.motd
end

-- Check maintenance mode
function RemoteConfig.IsMaintenance()
    return Config.maintenance
end

return RemoteConfig
