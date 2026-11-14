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
local function StyleLabel(label, color, sizeOffset)
    local theme = Theme()
    label:SetFont(ns.ThemeFont(theme), theme.fontSize + (sizeOffset or 0), "")
    label.label:SetTextColor(color[1], color[2], color[3])
    label.label:SetShadowOffset(1, -1)
    label.label:SetShadowColor(0, 0, 0, theme.shadow and 1 or 0)
end

local function AttachTooltip(widget, title, body)
    widget:SetCallback("OnEnter", function(self)
        GameTooltip:SetOwner(self.frame, "ANCHOR_RIGHT")
        GameTooltip:AddLine(title)
        if body and body ~= "" then GameTooltip:AddLine(body, 1, 1, 1, true) end
        GameTooltip:Show()
    end)
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

-- Sets a row's text, keeping the mark in front if it has one.
function UI.SetText(label, text)
    label:SetText(label:GetUserData("explains") and (EXPLAIN_MARK .. text) or text)
end

-- A row of text taking `relWidth` of the window's width (1 = full, 0.5 = half).
-- With `onClick(mouseButton)` it highlights under the mouse and can be clicked.
-- With `explain()` it gets a "[?]" in front that calls it.
function UI.AddLabel(parent, relWidth, text, onClick, tipTitle, tipBody, explain)
    local label = AceGUI:Create("InteractiveLabel")
    StyleLabel(label, Theme().text)
    label:SetRelativeWidth(relWidth)
    label:SetUserData("explains", explain ~= nil)
    UI.SetText(label, text)
    if onClick or explain then
        label.highlight:SetColorTexture(unpack(Theme().highlight))
        label:SetCallback("OnClick", function(_, _, button)
            if explain and (OverMark(label) or IsAltKeyDown()) then
                explain()
            elseif onClick then
                onClick(button)
            end
        end)
    end
    if tipTitle then AttachTooltip(label, tipTitle, (tipBody or "") .. (explain and EXPLAIN_TIP or "")) end
    parent:AddChild(label)
    return label
end

-- A section title with a blank line above it.
function UI.AddHeading(parent, text)
    local heading = AceGUI:Create("InteractiveLabel")
    StyleLabel(heading, Theme().accent, 1)
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
    bar:SetCallback("OnClick", function(_, _, button) onClick(button) end)
    AttachTooltip(bar, tipTitle, tipBody)
    parent:AddChild(bar)
    return bar
end
