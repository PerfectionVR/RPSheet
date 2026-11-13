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

-- A row of text taking `relWidth` of the window's width (1 = full, 0.5 = half).
-- With `onClick(mouseButton)` it highlights under the mouse and can be clicked.
function UI.AddLabel(parent, relWidth, text, onClick, tipTitle, tipBody)
    local label = AceGUI:Create("InteractiveLabel")
    StyleLabel(label, Theme().text)
    label:SetRelativeWidth(relWidth)
    label:SetText(text)
    if onClick then
        label.highlight:SetColorTexture(unpack(Theme().highlight))
        label:SetCallback("OnClick", function(_, _, button) onClick(button) end)
    end
    if tipTitle then AttachTooltip(label, tipTitle, tipBody) end
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
