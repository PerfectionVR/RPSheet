-- Building blocks of every window: buttons (UI/Button.lua), a strip of tabs
-- (UI/Tab.lua), and the small coloured square that shows something is free or used.
-- In all of them what can be clicked is a button, a tab or a bar; plain text is
-- only read.
local _, ns = ...
local RPSheet = ns.addon
local UI = ns.UI
local AceGUI = LibStub("AceGUI-3.0")

local function Theme()
    return RPSheet.db.profile.theme
end

local function Click(widget, _, button)
    local onClick = widget:GetUserData("onClick")
    if onClick then onClick(button) end
end

-- A click on a row of a sheet: what the row does, or, when it only has a number to
-- explain or Alt is held, how that number is worked out. Its "?" always explains.
local function ClickRow(widget, _, button)
    local explain, onClick = widget:GetUserData("explain"), widget:GetUserData("onClick")
    if explain and (not onClick or IsAltKeyDown()) then
        explain()
    elseif onClick then
        onClick(button)
    end
end

local function ClickMark(widget)
    widget:GetUserData("explain")()
end

-- A row of a sheet that can be clicked (UI.AddLabel makes one when it is given
-- something to do): a button in the "row" look, with a "?" part when it can explain
-- its number.
function UI.AddRowButton(parent, relWidth, text, onClick, explain, look)
    local button = AceGUI:Create("RPSheetButton")
    -- A row whose whole text is in the accent colour is something to do, not an entry
    -- of a list ("Short rest", "Take damage"): that is a button, in its own colours.
    local action = not look and not explain and text:sub(1, #UI.ACCENT) == UI.ACCENT and text:match("^|c%x%x%x%x%x%x%x%x([^|]+)|r$")
    if action then
        look, text = "on", action
    elseif look == "off" then
        look = "rowoff"
    end
    button:SetStyle(Theme(), look or "row")
    button:SetMark(explain ~= nil)
    button:SetText(text)
    button:SetRelativeWidth(relWidth >= 1 and 1 or relWidth * 0.999)
    button:SetUserData("onClick", onClick)
    button:SetUserData("explain", explain)
    button:SetCallback("OnClick", ClickRow)
    button:SetCallback("OnMarkClick", ClickMark)
    parent:AddChild(button)
    return button
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

-- A strip of tabs: `tabs` is a list of { name, label, tip }, `open` the name of the
-- one showing (nil: none of them), `pick(name)` is called for a click on another. Returns the tabs made, in order.
function UI.AddTabStrip(parent, tabs, open, pick)
    local theme, made = Theme(), {}
    for _, tab in ipairs(tabs) do
        local button = AceGUI:Create("RPSheetTab")
        made[#made + 1] = button
        button:SetStyle(theme, tab.name == open)
        button:SetText(tab.label or tab.name)
        button:SetRelativeWidth(0.999 / #tabs)
        button:SetUserData("onClick", function()
            if tab.name ~= open then pick(tab.name) end
        end)
        button:SetCallback("OnClick", Click)
        if tab.tip then UI.AttachTooltip(button, tab.name, tab.tip) end
        parent:AddChild(button)
    end
    return made
end

-- A small filled square in a line of text.
function UI.Pip(red, green, blue)
    return ("|TInterface\\Buttons\\WHITE8x8:9:9:0:0:8:8:0:8:0:8:%d:%d:%d|t"):format(red * 255, green * 255, blue * 255)
end

-- A count of a few things as squares, the ones left in the accent colour and the
-- ones used faint: "2 of 4" is two lit and two faint. nil for more than `most`
-- (6 when left out), which no longer read at a glance.
function UI.Pips(value, max, most)
    if max < 1 or max > (most or 6) then return nil end
    local theme = Theme()
    local lit, faint = theme.accent, theme.muted
    local parts = {}
    for index = 1, max do
        local color = index <= value and lit or faint
        local dim = index <= value and 1 or 0.45
        parts[index] = UI.Pip(color[1] * dim, color[2] * dim, color[3] * dim)
    end
    return table.concat(parts, " ")
end

-- The colour of a health bar: green, then amber under half, red under a quarter.
function UI.HealthColor(hp, max)
    local part = max > 0 and hp / max or 0
    if part > 0.5 then return { 0.18, 0.55, 0.18, 1 } end
    if part > 0.25 then return { 0.72, 0.53, 0.04, 1 } end
    return { 0.70, 0.16, 0.16, 1 }
end
