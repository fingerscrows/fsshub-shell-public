local Events = {}

-- Store internal BindableEvents
local Bindables = {
    Command = Instance.new("BindableEvent"),
    StatusUpdate = Instance.new("BindableEvent"),
    FeatureState = Instance.new("BindableEvent")
}

-- Public Interface for the Shell
Events.Signals = {
    OnStatusUpdate = Bindables.StatusUpdate.Event,
    FeatureState = Bindables.FeatureState.Event
}

-- Function to send commands to the Core (Shell -> Core)
function Events.Emit(commandName, ...)
    Bindables.Command:Fire(commandName, ...)
end

-- Bridge Interface for the Core (Exposed via Global)
-- The Core will use these to:
-- 1. Listen to 'Command' (Shell -> Core)
-- 2. Fire 'StatusUpdate' and 'FeatureState' (Core -> Shell)
Events._bridge = Bindables

return Events
