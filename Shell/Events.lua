local Events = {}

function Events.Init()
    local container = {}
    local signals = { "ToggleFeature" } -- Outgoing
    local listeners = { "Notification", "FeatureState" } -- Incoming

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