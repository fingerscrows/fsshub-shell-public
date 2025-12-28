local Events = {}

function Events.Init()
    local container = {}

    -- Outgoing signals (Shell → Core)
    local signals = {
        "ToggleFeature", -- Feature toggle request
        "TryLogin",      -- Auth with key
        "GetKeyLink"     -- V3: Request session-bound key URL
    }

    -- Incoming signals (Core → Shell)
    local listeners = {
        "Notification",  -- Display notification
        "FeatureState",  -- Feature state update (revert toggle)
        "AuthResult",    -- Auth success/failure
        "KeyLinkResult", -- V3: Key link URL result
        "StateChange"    -- V3: State machine transition
    }

    container.Signals = {}

    for _, name in pairs(signals) do
        local be = Instance.new("BindableEvent")
        be.Name = name
        container.Signals[name] = be
    end

    for _, name in pairs(listeners) do
        local be = Instance.new("BindableEvent")
        be.Name = name
        container.Signals[name] = be
    end

    function container:Emit(name, ...)
        if self.Signals[name] then self.Signals[name]:Fire(...) end
    end

    return container
end

return Events
