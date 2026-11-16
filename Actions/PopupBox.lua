-- Finds the text box of one of the game's popups (StaticPopup_Show with hasEditBox),
-- for the boxes that ask for coins, an amount of damage or healing, or a worth of
-- materials. The game has reached that box in several ways over the years: a method
-- (the accessors that came with the popup rework of 11.2), the child keys EditBox and
-- editBox, and the global name "<popup name>EditBox". When none of them answers, the
-- popup's children are searched for the edit box itself.
local _, ns = ...

local function IsEditBox(frame)
    return type(frame) == "table" and type(frame.GetText) == "function" and type(frame.SetText) == "function"
        and (type(frame.GetObjectType) ~= "function" or frame:GetObjectType() == "EditBox")
end

-- The first edit box among the children of `frame`, looking one level further down
-- too (the box can sit in a container of its own).
local function Search(frame, depth)
    if type(frame) ~= "table" or type(frame.GetChildren) ~= "function" then return end
    for _, child in ipairs({ frame:GetChildren() }) do
        if IsEditBox(child) then return child end
    end
    if depth > 0 then
        for _, child in ipairs({ frame:GetChildren() }) do
            local found = Search(child, depth - 1)
            if found then return found end
        end
    end
end

function ns.PopupEditBox(dialog)
    if type(dialog) ~= "table" then return end
    if type(dialog.GetEditBox) == "function" then
        local ok, box = pcall(dialog.GetEditBox, dialog)
        if ok and IsEditBox(box) then return box end
    end
    for _, key in ipairs({ "EditBox", "editBox" }) do
        local box = dialog[key]
        if IsEditBox(box) then return box end
    end
    local name = type(dialog.GetName) == "function" and dialog:GetName()
    if type(name) == "string" and IsEditBox(_G[name .. "EditBox"]) then return _G[name .. "EditBox"] end
    return Search(dialog, 1)
end
