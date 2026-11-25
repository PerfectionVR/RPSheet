-- "RPSheetButton": an AceGUI widget for something to click in a window: a box with
-- an edge all round in the accent colour, so it reads as a button and not as text.
-- Four looks: "on" (can be clicked now), "off" (greyed: a click says why not),
-- "picked" (the one of several that is chosen, filled) and "row" (a row of a sheet:
-- text in the text colour, so the colours inside it stand out). Text that doesn't fit
-- wraps and the button grows with it. With SetMark(true) it has a small "?" part of
-- its own on the left. Fires OnClick(button), OnMarkClick(button), OnEnter, OnLeave.
local _, ns = ...
local AceGUI = LibStub("AceGUI-3.0")
local Type, Version = "RPSheetButton", 2

local GAP = 3 -- space kept free to the right and below, between neighbouring buttons
local PAD = 4 -- between the edge and the text, left and right
local ROOM = 10 -- above and below the text together

-- Gives the text the width there is, and the button the height the text needs.
local function Fit(self)
    if self.fitting then return end
    local marked = self.marked and self.markWidth or 0
    local width = math.max(10, (self.frame.width or self.frame:GetWidth() or 0) - GAP - 2 * PAD - marked)
    self.text:SetWidth(width)
    local height = math.max(self.lineHeight or 12, self.text:GetStringHeight() or 0) + ROOM + GAP
    self.fitting = true
    self:SetHeight(height)
    self.fitting = nil
end

local methods = {
    OnAcquire = function(self)
        self.marked = false
        self:SetDisabled(false)
        self.mark:Hide()
        self.text:SetPoint("CENTER", self.fill, "CENTER", 0, 0)
        self:SetWidth(100)
        self:SetHeight(22)
        self:SetText("")
        self.hover:Hide()
        self.markHover:Hide()
    end,

    SetText = function(self, text)
        self.text:SetText(text)
        Fit(self)
    end,

    GetText = function(self)
        return self.text:GetText()
    end,

    -- Switched off: it takes no click at all. (The "off" look alone still does.)
    SetDisabled = function(self, off)
        self.disabled = off and true or false
        if off then self.frame:Disable() else self.frame:Enable() end
    end,

    OnWidthSet = function(self)
        Fit(self)
    end,

    -- The "?" part on the left, a button of its own (OnMarkClick).
    SetMark = function(self, on)
        self.marked = on and true or false
        self.mark:SetShown(self.marked)
        self.text:SetPoint("CENTER", self.fill, "CENTER", self.marked and self.markWidth / 2 or 0, 0)
        Fit(self)
    end,

    -- Colours, font and height from the theme. `look` is "on", "off", "picked" or "row".
    SetStyle = function(self, theme, look)
        local accent, muted = theme.accent, theme.muted
        local edge = look == "off" and muted or accent
        local color = look == "off" and muted or ((look == "picked" or look == "row") and theme.text or accent)
        self.look = look
        self.text:SetFont(ns.ThemeFont(theme), theme.fontSize, "")
        self.text:SetTextColor(color[1], color[2], color[3])
        self.text:SetShadowOffset(1, -1)
        self.text:SetShadowColor(0, 0, 0, theme.shadow and 1 or 0)
        self.fill:SetColorTexture(edge[1], edge[2], edge[3],
            look == "picked" and 0.45 or (look == "off" and 0.05 or (look == "row" and 0.09 or 0.14)))
        local solid = look == "off" and 0.35 or (look == "picked" and 1 or (look == "row" and 0.55 or 0.75))
        for _, line in ipairs(self.edges) do
            line:SetColorTexture(edge[1], edge[2], edge[3], solid)
        end
        self.hover:SetColorTexture(unpack(theme.highlight))
        self.markHover:SetColorTexture(unpack(theme.highlight))
        self.markLine:SetColorTexture(edge[1], edge[2], edge[3], solid)
        self.markText:SetFont(ns.ThemeFont(theme), theme.fontSize, "")
        self.markText:SetTextColor(muted[1], muted[2], muted[3])
        self.markWidth = theme.fontSize + 4
        self.mark:SetWidth(self.markWidth)
        self.lineHeight = theme.fontSize
        Fit(self)
    end,
}

local function Edge(frame, fill, from, to, width, height)
    local line = frame:CreateTexture(nil, "ARTWORK")
    line:SetPoint(from, fill, from)
    line:SetPoint(to, fill, to)
    if width then line:SetWidth(width) else line:SetHeight(height) end
    return line
end

local function Constructor()
    local frame = CreateFrame("Button", nil, UIParent)
    frame:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    frame:Hide()

    local fill = frame:CreateTexture(nil, "BACKGROUND")
    fill:SetPoint("TOPLEFT")
    fill:SetPoint("BOTTOMRIGHT", -GAP, GAP)

    local hover = frame:CreateTexture(nil, "BORDER")
    hover:SetAllPoints(fill)
    hover:SetBlendMode("ADD")

    local edges = {
        Edge(frame, fill, "TOPLEFT", "TOPRIGHT", nil, 1), Edge(frame, fill, "BOTTOMLEFT", "BOTTOMRIGHT", nil, 1),
        Edge(frame, fill, "TOPLEFT", "BOTTOMLEFT", 1), Edge(frame, fill, "TOPRIGHT", "BOTTOMRIGHT", 1),
    }

    local text = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    text:SetPoint("CENTER", fill, "CENTER", 0, 0)
    text:SetJustifyH("CENTER")
    text:SetWordWrap(true)

    -- The "?" part: a button inside the button, with a line between the two.
    local mark = CreateFrame("Button", nil, frame)
    mark:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    mark:SetPoint("TOPLEFT", fill, "TOPLEFT")
    mark:SetPoint("BOTTOMLEFT", fill, "BOTTOMLEFT")
    mark:SetWidth(16)
    mark:Hide()
    local markHover = mark:CreateTexture(nil, "BORDER")
    markHover:SetAllPoints(mark)
    markHover:SetBlendMode("ADD")
    markHover:Hide()
    local markLine = mark:CreateTexture(nil, "ARTWORK")
    markLine:SetPoint("TOPRIGHT", mark, "TOPRIGHT")
    markLine:SetPoint("BOTTOMRIGHT", mark, "BOTTOMRIGHT")
    markLine:SetWidth(1)
    local markText = mark:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    markText:SetPoint("CENTER", mark, "CENTER", 0, 0)
    markText:SetText("?")

    local widget = { type = Type, frame = frame, fill = fill, hover = hover, edges = edges, text = text,
        mark = mark, markHover = markHover, markLine = markLine, markText = markText }
    for name, method in pairs(methods) do widget[name] = method end

    frame:SetScript("OnClick", function(_, button) widget:Fire("OnClick", button) end)
    frame:SetScript("OnEnter", function()
        hover:Show()
        widget:Fire("OnEnter")
    end)
    frame:SetScript("OnLeave", function()
        hover:Hide()
        widget:Fire("OnLeave")
    end)
    mark:SetScript("OnClick", function(_, button) widget:Fire("OnMarkClick", button) end)
    mark:SetScript("OnEnter", function()
        markHover:Show()
        widget:Fire("OnEnter")
    end)
    mark:SetScript("OnLeave", function()
        markHover:Hide()
        widget:Fire("OnLeave")
    end)

    return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
