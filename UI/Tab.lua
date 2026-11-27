-- "RPSheetTab": an AceGUI widget for one tab of a strip of tabs. A tab is its name
-- on a hairline; the open one is in the text colour on a thicker line in the accent
-- colour, the others are muted.
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
        local tokens = ns.Tokens(theme)
        local color = open and tokens.text or tokens.muted
        self.open = open
        self.text:SetFont(ns.ThemeFont(theme), theme.fontSize, "")
        self.text:SetTextColor(color[1], color[2], color[3])
        self.text:SetShadowOffset(1, -1)
        self.text:SetShadowColor(0, 0, 0, theme.shadow and 1 or 0)
        -- No box: a hairline runs under the whole strip, and the open tab stands on a
        -- thicker line in the accent colour.
        self.fill:SetColorTexture(0, 0, 0, 0)
        for _, edge in ipairs(self.edges) do edge:SetColorTexture(0, 0, 0, 0) end
        local line = open and tokens.accent or tokens.line
        self.underline:SetColorTexture(line[1], line[2], line[3], open and 1 or line[4])
        self.underline:SetHeight(open and 2 or 1)
        self.underline:Show()
        self.hover:SetColorTexture(unpack(tokens.hover))
        self:SetHeight(theme.fontSize + 14)
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
    local underline = frame:CreateTexture(nil, "ARTWORK")
    underline:SetPoint("BOTTOMLEFT")
    underline:SetPoint("BOTTOMRIGHT")
    underline:SetHeight(1)

    local text = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    text:SetPoint("LEFT", fill, 2, 0)
    text:SetPoint("RIGHT", fill, -2, 0)
    text:SetJustifyH("CENTER")
    text:SetWordWrap(false)

    local widget = { type = Type, frame = frame, fill = fill, hover = hover, edges = { top, left, right }, underline = underline, text = text }
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
