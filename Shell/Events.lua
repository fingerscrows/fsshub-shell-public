local Events = {}

-- Helper to get global environment safely
local getgenv = getgenv or function() return _G or shared end

function Events.Init()
    local container = {}
    local signals = { "ToggleFeature" } -- Outgoing
    local listeners = { "Notification", "FeatureState" } -- Incoming

    container.Signals = {}

    -- Check for existing events in global table to ensure Idempotency
    local existingEvents = nil
    local globalShell = getgenv().FSSHUB_SHELL
    if globalShell and globalShell.Events then
        existingEvents = globalShell.Events
    end

    for _, name in pairs(signals) do
        if existingEvents and existingEvents[name] then
            container.Signals[name] = existingEvents[name]
        else
            local be = Instance.new("BindableEvent")
            be.Name = name
            container.Signals[name] = be
        end
    end

    for _, name in pairs(listeners) do
        if existingEvents and existingEvents[name] then
            container.Signals[name] = existingEvents[name]
        else
            local be = Instance.new("BindableEvent")
            be.Name = name
            container.Signals[name] = be
        end
    end

    function container:Emit(name, ...)
        if self.Signals[name] then self.Signals[name]:Fire(...) end
    end

    return container
end

return Events