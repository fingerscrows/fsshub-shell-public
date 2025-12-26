local Window = {}

-- Requires Fluent from Root (Shell/UI/Window.lua -> UI -> Shell -> Root -> Fluent)
local Fluent = require(script.Parent.Parent.Parent.Fluent.src)

function Window.Create()
    local Win = Fluent:CreateWindow({
        Title = "FSSHUB V3",
        SubTitle = "Universal",
        TabWidth = 160,
        Size = UDim2.fromOffset(580, 460),
        Acrylic = true,
        Theme = "Dark",
        MinimizeKey = Enum.KeyCode.LeftControl
    })

    -- Enforce Cyber/Neon Accent (Neon Cyan)
    if Fluent.Options then
        Fluent.Options.Accent = Color3.fromRGB(0, 255, 255)
    end

    return Win, Fluent
end

return Window
