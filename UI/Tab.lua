-- "RPSheetTab": an AceGUI widget for one tab of the sheet's tab strip. The open tab
-- is a filled box with an edge in the accent colour and no line under it, so it reads
-- as joined to the page below; the others are dim boxes standing on the page's top line.
-- Fires OnClick, OnEnter and OnLeave.
local _, ns = ...
local AceGUI = LibStub("AceGUI-3.0")
local Type, Version = "RPSheetTab", 1

local GAP = 2 -- space kept free to the right, between neighbouring tabs

local methods = {
    OnAcquire = function(self)
        self:SetWidth(60)
        self:SetHeight(20)
        self:SetText("")
        self.hover:Hide()
    end,

    SetText = function(self, text)
        self.text:SetText(text)
    end,

    -- Colours, font and height from the theme; `open` marks the tab that is showing.
    SetStyle = function(self, theme, open)
        local accent, color = theme.accent, open and theme.accent or theme.muted
        self.open = open
        self.text:SetFont(ns.ThemeFont(theme), theme.fontSize, "")
        self.text:SetTextColor(color[1], color[2], color[3])
        self.text:SetShadowOffset(1, -1)
        self.text:SetShadowColor(0, 0, 0, theme.shadow and 1 or 0)
        self.fill:SetColorTexture(accent[1], accent[2], accent[3], open and 0.22 or 0.06)
        for _, edge in ipairs(self.edges) do
            edge:SetColorTexture(accent[1], accent[2], accent[3], open and 1 or 0.3)
        end
        -- The page's top line runs under every tab but the open one.
        self.base:SetColorTexture(accent[1], accent[2], accent[3], 1)
        self.base:SetShown(not open)
        self.hover:SetColorTexture(unpack(theme.highlight))
        self:SetHeight(theme.fontSize + 12)
    end,
}

local function Constructor()
    local frame = CreateFrame("Button", nil, UIParent)
    frame:Hide()

    local fill = frame:CreateTexture(nil, "BACKGROUND")
    fill:SetPoint("TOPLEFT")
    fill:SetPoint("BOTTOMRIGHT", -GAP, 0)

    local hover = frame:CreateTexture(nil, "BORDER")
    hover:SetAllPoints(fill)
    hover:SetBlendMode("ADD")

    -- Top, left and right edges, one pixel wide.
    local top, left, right = frame:CreateTexture(nil, "ARTWORK"), frame:CreateTexture(nil, "ARTWORK"), frame:CreateTexture(nil, "ARTWORK")
    top:SetPoint("TOPLEFT", fill)
    top:SetPoint("TOPRIGHT", fill)
    top:SetHeight(1)
    left:SetPoint("TOPLEFT", fill)
    left:SetPoint("BOTTOMLEFT", fill)
    left:SetWidth(1)
    right:SetPoint("TOPRIGHT", fill)
    right:SetPoint("BOTTOMRIGHT", fill)
    right:SetWidth(1)

    -- The line under the tab; it also spans the gap, so the line is unbroken.
    local base = frame:CreateTexture(nil, "ARTWORK")
    base:SetPoint("BOTTOMLEFT")
    base:SetPoint("BOTTOMRIGHT")
    base:SetHeight(1)

    local text = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    text:SetPoint("LEFT", fill, 2, 0)
    text:SetPoint("RIGHT", fill, -2, 0)
    text:SetJustifyH("CENTER")
    text:SetWordWrap(false)

    local widget = { type = Type, frame = frame, fill = fill, hover = hover, edges = { top, left, right }, base = base, text = text }
    for name, method in pairs(methods) do widget[name] = method end

    frame:SetScript("OnClick", function() widget:Fire("OnClick") end)
    frame:SetScript("OnEnter", function()
        if not widget.open then hover:Show() end
        widget:Fire("OnEnter")
    end)
    frame:SetScript("OnLeave", function()
        hover:Hide()
        widget:Fire("OnLeave")
    end)

    return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
