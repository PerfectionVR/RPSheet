-- Building blocks of the combat window: buttons (UI/Button.lua), a strip of tabs
-- (UI/Tab.lua), and the small coloured square that shows something is free or used.
-- In this window what can be clicked is a button, a tab or a bar; plain text is
-- only read.
local _, ns = ...
local RPSheet = ns.addon
local UI = ns.UI
local AceGUI = LibStub("AceGUI-3.0")

local function Theme()
    return RPSheet.db.profile.theme
end

local function Click(widget, _, button)
    widget:GetUserData("onClick")(button)
end

-- A button taking `relWidth` of the window's width. `look` is "on" (the default),
-- "off" (greyed; a click may still say why) or "picked".
function UI.AddButton(parent, relWidth, text, onClick, tipTitle, tipBody, look)
    local button = AceGUI:Create("RPSheetButton")
    button:SetStyle(Theme(), look or "on")
    button:SetText(text)
    -- (a hair under the share: rounding must not push the last one of a row down)
    button:SetRelativeWidth(relWidth >= 1 and 1 or relWidth * 0.999)
    button:SetUserData("onClick", onClick)
    button:SetCallback("OnClick", Click)
    if tipTitle then UI.AttachTooltip(button, tipTitle, tipBody) end
    parent:AddChild(button)
    return button
end

-- A strip of tabs: `tabs` is a list of { name, tip }, `open` the name of the one
-- showing, `pick(name)` is called for a click on another.
function UI.AddTabStrip(parent, tabs, open, pick)
    local theme = Theme()
    for _, tab in ipairs(tabs) do
        local button = AceGUI:Create("RPSheetTab")
        button:SetStyle(theme, tab.name == open)
        button:SetText(tab.label or tab.name)
        button:SetRelativeWidth(0.999 / #tabs)
        button:SetUserData("onClick", function()
            if tab.name ~= open then pick(tab.name) end
        end)
        button:SetCallback("OnClick", Click)
        UI.AttachTooltip(button, tab.name, tab.tip)
        parent:AddChild(button)
    end
end

-- A small filled square in a line of text.
function UI.Pip(red, green, blue)
    return ("|TInterface\\Buttons\\WHITE8x8:9:9:0:0:8:8:0:8:0:8:%d:%d:%d|t"):format(red * 255, green * 255, blue * 255)
end

-- The colour of a health bar: green, then amber under half, red under a quarter.
function UI.HealthColor(hp, max)
    local part = max > 0 and hp / max or 0
    if part > 0.5 then return { 0.18, 0.55, 0.18, 1 } end
    if part > 0.25 then return { 0.72, 0.53, 0.04, 1 } end
    return { 0.70, 0.16, 0.16, 1 }
end
