-- Building blocks for the sheet's contents: themed text rows, headings and bars.
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
local function ShowTooltip(widget)
    local body = widget:GetUserData("tipBody")
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

-- The small "[?]" in front of a row that can explain its number. Clicking it shows
-- the maths; clicking the rest of the row does what the row normally does.
local EXPLAIN_MARK = "|cff8f8f8f[?]|r "
local EXPLAIN_TIP = "\n\n|cff8f8f8fClick the [?] in front to see how this number is worked out.|r"

-- True if the mouse is over the mark at the start of the row.
local function OverMark(label)
    local left = label.frame:GetLeft()
    if not left then return false end
    local x = GetCursorPosition() / label.frame:GetEffectiveScale()
    return x - left <= Theme().fontSize * 1.7
end

-- A click on a row: on its mark (or with Alt) the explanation, otherwise what the row does.
local function ClickLabel(label, _, button)
    local explain, onClick = label:GetUserData("explain"), label:GetUserData("onClick")
    if explain and (OverMark(label) or IsAltKeyDown()) then
        explain()
    elseif onClick then
        onClick(button)
    end
end

local function ClickBar(bar, _, button)
    bar:GetUserData("onClick")(button)
end

-- Sets a row's text, keeping the mark in front if it has one.
function UI.SetText(label, text)
    label:SetText(label:GetUserData("explains") and (EXPLAIN_MARK .. text) or text)
end

-- A row of text taking `relWidth` of the window's width (1 = full, 0.5 = half).
-- With `onClick(mouseButton)` it highlights under the mouse and can be clicked.
-- With `explain()` it gets a "[?]" in front that calls it.
function UI.AddLabel(parent, relWidth, text, onClick, tipTitle, tipBody, explain)
    local theme = Theme()
    local label = AceGUI:Create("InteractiveLabel")
    StyleLabel(label, theme, theme.text)
    label:SetRelativeWidth(relWidth)
    label:SetUserData("explains", explain ~= nil)
    UI.SetText(label, text)
    if onClick or explain then
        label.highlight:SetColorTexture(unpack(theme.highlight))
        label:SetUserData("onClick", onClick)
        label:SetUserData("explain", explain)
        label:SetCallback("OnClick", ClickLabel)
    end
    if tipTitle then AttachTooltip(label, tipTitle, explain and ((tipBody or "") .. EXPLAIN_TIP) or tipBody) end
    parent:AddChild(label)
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
