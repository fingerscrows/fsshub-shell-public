local Signal = {}
Signal.__index = Signal

function Signal.new()
    local self = setmetatable({}, Signal)
    self._callbacks = {}
    return self
end

function Signal:Connect(callback)
    table.insert(self._callbacks, callback)

    return {
        Disconnect = function()
            for i, v in ipairs(self._callbacks) do
                if v == callback then
                    table.remove(self._callbacks, i)
                    break
                end
            end
        end
    }
end

function Signal:Fire(...)
    for _, callback in ipairs(self._callbacks) do
        if task and task.spawn then
            task.spawn(callback, ...)
        else
            coroutine.wrap(callback)(...)
        end
    end
end

-- Events Module
local Events = {
    Signal = Signal,
    -- Signals for communication with Core
    Request = Signal.new(), -- For HTTP requests proxied to Core
    Message = Signal.new(), -- General messages
}

return Events
