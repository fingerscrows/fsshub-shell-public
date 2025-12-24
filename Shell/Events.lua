local Signal = {}
Signal.__index = Signal

function Signal.new()
    local self = setmetatable({}, Signal)
    self._callbacks = {}
    return self
end

function Signal:Connect(callback)
    assert(type(callback) == "function", "Callback must be a function")
    table.insert(self._callbacks, callback)

    local connection = {
        Connected = true
    }

    function connection:Disconnect()
        if not connection.Connected then return end
        connection.Connected = false

        for i, v in ipairs(self._callbacks) do
            if v == callback then
                table.remove(self._callbacks, i)
                break
            end
        end
    end

    return connection
end

function Signal:Fire(...)
    for _, callback in ipairs(self._callbacks) do
        task.spawn(callback, ...)
    end
end

function Signal:Wait()
    local thread = coroutine.running()

    local connection
    connection = self:Connect(function(...)
        connection:Disconnect()
        task.spawn(thread, ...)
    end)

    return coroutine.yield()
end

function Signal:Destroy()
    self._callbacks = {}
end

return Signal
