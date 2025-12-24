local Components = {}

-- A placeholder for component creation logic.
-- Fluent handles component creation via object methods (Window:AddTab, Tab:AddParagraph, etc.)

function Components.CreateLabel(parent, text, subText)
    -- Parent should be the Tab object
    if parent and parent.AddParagraph then
        return parent:AddParagraph({
            Title = text,
            Content = subText or ""
        })
    end
    return nil
end

return Components
