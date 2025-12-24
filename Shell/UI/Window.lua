local Window = {}

-- Requires Fluent from Root (Shell/UI/Window.lua -> UI -> Shell -> Root -> Fluent)
-- Adjust path if necessary. Based on user request "script.Parent.Parent.Fluent" from Init,
-- From Window (Shell/UI/Window.lua), it is script.Parent.Parent.Parent.Fluent
local Fluent = require(script.Parent.Parent.Parent.Fluent)

function Window.Create()
    local Win = Fluent:CreateWindow({
        Title = "FSSHub Shell",
        SubTitle = "by Jules",
        TabWidth = 160,
        Size = UDim2.fromOffset(580, 460),
        Acrylic = true,
        Theme = "Aqua", -- Request: Cyber/Neon (Cyan Accent, Dark Background). Aqua is closest default.
        MinimizeKey = Enum.KeyCode.LeftControl
    })

    return Win, Fluent
end

return Window
