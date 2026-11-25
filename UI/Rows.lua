-- Building blocks for the sheet's contents: themed text rows, headings and bars. A
-- row that does something when clicked is a button (UI.AddRowButton, UI/Parts.lua).
local _, ns = ...
local RPSheet = ns.addon
local Util = ns.Util
local AceGUI = LibStub("AceGUI-3.0")

local UI = {}
ns.UI = UI

-- Colour codes for secondary and highlighted text inside a row. Set from the theme.
UI.GREY, UI.ACCENT = "|cff909090", "|cffffd100"
UI.GREEN = "|cff80ff80" -- effect lines in tooltips, which keep the game's own colours

function UI.SetColors(theme)
    UI.GREY, UI.ACCENT = Util.HexCode(theme.muted), Util.HexCode(theme.accent)
end

local function Theme()
    return RPSheet.db.profile.theme
end

-- Font, colours and shadow from the theme. AceGUI resets all of these when it reuses a label.
local function StyleLabel(label, theme, color, sizeOffset)
    label:SetFont(ns.ThemeFont(theme), theme.fontSize + (sizeOffset or 0), "")
    label.label:SetTextColor(color[1], color[2], color[3])
    label.label:SetShadowOffset(1, -1)
    label.label:SetShadowColor(0, 0, 0, theme.shadow and 1 or 0)
end

-- What a row shows and does is kept on the row itself (its user data, which AceGUI
-- clears when the row is released), so all rows share these handlers instead of each
-- getting functions of its own every time the sheet is rebuilt.
-- A tooltip's body may be a function that gives the text: it is only called here, when
-- the mouse is over the row, so rebuilding the sheet doesn't pay for the tooltips of
-- rows nobody hovers. (EXPLAIN_TIP: the "?" part of a row's button.)
local EXPLAIN_TIP = "\n\n|cff8f8f8fClick the ? in front to see how this number is worked out.|r"
-- (a roll's row, UI.AddRollLabel, also explains on a right-click)
local EXPLAIN_RIGHT_TIP = "\n\n|cff8f8f8fRight-click, or click the ? in front, to see how this number is worked out.|r"
-- (a row that does nothing else explains wherever it is clicked)
local EXPLAIN_ONLY_TIP = "\n\n|cff8f8f8fClick to see how this number is worked out.|r"

local function ExplainTip(onClick, right)
    return (not onClick and EXPLAIN_ONLY_TIP) or (right and EXPLAIN_RIGHT_TIP) or EXPLAIN_TIP
end

local function ShowTooltip(widget)
    local body = widget:GetUserData("tipBody")
    if type(body) == "function" then
        body = body()
        if widget:GetUserData("explain") then
            body = (body or "") .. ExplainTip(widget:GetUserData("onClick"), widget:GetUserData("rightExplains"))
        end
    end
    GameTooltip:SetOwner(widget.frame, "ANCHOR_RIGHT")
    GameTooltip:AddLine(widget:GetUserData("tipTitle"))
    if body and body ~= "" then GameTooltip:AddLine(body, 1, 1, 1, true) end
    GameTooltip:Show()
end

local function AttachTooltip(widget, title, body)
    widget:SetUserData("tipTitle", title)
    widget:SetUserData("tipBody", body)
    widget:SetCallback("OnEnter", ShowTooltip)
    widget:SetCallback("OnLeave", GameTooltip_Hide)
end

UI.AttachTooltip = AttachTooltip

-- Sets a row's text.
function UI.SetText(label, text)
    label:SetText(text)
end

-- A row of text taking `relWidth` of the window's width (1 = full, 0.5 = half).
-- With `onClick(mouseButton)` it is a button instead of text. With `explain()` that
-- button has a "?" part in front that calls it; with only `explain()` the whole
-- button does.
-- `tipBody` is the tooltip's text, or a function that gives it when the row is hovered:
-- use a function where the text takes work (lists, explanations, spell and item text).
-- `look` is the button's, when it isn't a row's own (UI/Button.lua): "off" for a
-- switch that is off.
function UI.AddLabel(parent, relWidth, text, onClick, tipTitle, tipBody, explain, look)
    local theme = Theme()
    local label
    if onClick or explain then
        label = UI.AddRowButton(parent, relWidth, text, onClick, explain, look)
    else
        label = AceGUI:Create("InteractiveLabel")
        StyleLabel(label, theme, theme.text)
        label:SetRelativeWidth(relWidth)
        label:SetText(text)
        parent:AddChild(label)
    end
    if tipTitle then
        -- (a function's text gets the line about the "?" when it is shown)
        local fixed = type(tipBody) ~= "function"
        AttachTooltip(label, tipTitle, fixed and explain and ((tipBody or "") .. ExplainTip(onClick)) or tipBody)
    end
    return label
end

-- A row that rolls a d20 (a check, save, skill, tool, initiative, spell attack): a
-- left-click rolls, a right-click shows how the number is worked out, as the "?"
-- does, and the tooltip says so. `explain()` is required.
local function ClickRoll(button, roll, explain)
    if button == "RightButton" then explain() else roll() end
end

function UI.AddRollLabel(parent, relWidth, text, roll, tipTitle, tipBody, explain)
    local body = tipBody
    if type(body) ~= "function" then body = function() return tipBody end end
    local label = UI.AddLabel(parent, relWidth, text, function(button) ClickRoll(button, roll, explain) end,
        tipTitle, body, explain)
    label:SetUserData("rightExplains", true)
    return label
end

-- Sets out the rows of a window that was just filled or resized. A row learns its
-- height only when the layout gives it its width, after the layout has read the height
-- it had before, so one pass can leave a row lying over the next one. The second pass
-- sets the rows out with the heights they have now.
function UI.SetOut(body)
    body:DoLayout()
    body:DoLayout()
end

-- A section title with a blank line above it.
function UI.AddHeading(parent, text)
    local heading = AceGUI:Create("InteractiveLabel")
    local theme = Theme()
    StyleLabel(heading, theme, theme.accent, 1)
    heading.frame:EnableMouse(false)
    heading:SetFullWidth(true)
    heading:SetText("\n" .. text)
    parent:AddChild(heading)
end

-- A filled bar (see Bar.lua) taking half the window's width.
function UI.AddBar(parent, color, onClick, tipTitle, tipBody)
    local bar = AceGUI:Create("RPSheetBar")
    bar:SetStyle(Theme(), color)
    bar:SetRelativeWidth(0.5)
    bar:SetUserData("onClick", onClick)
    bar:SetCallback("OnClick", ClickBar)
    AttachTooltip(bar, tipTitle, tipBody)
    parent:AddChild(bar)
    return bar
end
