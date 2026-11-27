-- "RPSheetButton": an AceGUI widget for everything that is clicked in a window. Its
-- looks (UI/ButtonLooks.lua) are of three kinds:
--   a button    "on", "off" (greyed: a click says why not), "picked" (the main action,
--               or the one of several that is chosen): a filled shape, text centred
--   a row       "row", "rowoff": a line of a list. No box: a hairline under it and a
--               wash under the mouse. Text after two spaces ("Name  info") stands
--               on the right in the muted colour
--   a tile      "tile": a number worth a glance. Text before a line break is the
--               small label over it
-- Text that doesn't fit wraps and the widget grows with it. With SetMark(true) it has
-- a small "?" part of its own on the right. Fires OnClick(button),
-- OnMarkClick(button), OnEnter, OnLeave.
local _, ns = ...
local AceGUI = LibStub("AceGUI-3.0")
local Type, Version = "RPSheetButton", 3

-- Gives the texts the width there is, and the widget the height they need.
local function Fit(self)
    if self.fitting then return end
    local kind = self.kind
    if not kind then return end
    local marked = self.marked and self.markWidth or 0
    local width = math.max(10, (self.frame.width or self.frame:GetWidth() or 0) - kind.gap - 2 * kind.pad - (kind.tile and 0 or marked))
    local height
    if kind.tile then
        -- (a tile's "?" stands in its corner, beside the label: the number has the whole width)
        self.side:SetWidth(math.max(10, width - marked))
        self.text:SetWidth(width)
        height = (self.side:GetStringHeight() or 0) + 2 + math.max(self.lineHeight + 4, self.text:GetStringHeight() or 0)
    else
        local side = 0
        if kind.split and (self.side:GetText() or "") ~= "" then
            side = math.min(self.side:GetStringWidth() or 0, width * 0.6)
            self.side:SetWidth(side)
            side = side + 8
        end
        self.text:SetWidth(math.max(10, width - side))
        height = math.max(self.lineHeight, self.text:GetStringHeight() or 0)
    end
    self.fitting = true
    self:SetHeight(height + kind.room + kind.below)
    self.fitting = nil
end

-- Where the texts stand for the kind of look.
local function Place(self)
    local kind, fill, text, side = self.kind, self.fill, self.text, self.side
    local right = -kind.pad - (self.marked and self.markWidth or 0)
    text:ClearAllPoints()
    side:ClearAllPoints()
    if kind.tile then
        side:SetPoint("TOPLEFT", fill, "TOPLEFT", kind.pad, -kind.room / 2)
        text:SetPoint("BOTTOMLEFT", fill, "BOTTOMLEFT", kind.pad, kind.room / 2)
        text:SetJustifyH("LEFT")
        side:SetJustifyH("LEFT")
        side:SetWordWrap(true)
        self.mark:ClearAllPoints()
        self.mark:SetPoint("TOPRIGHT", fill, "TOPRIGHT")
        self.mark:SetHeight(self.lineHeight + kind.room / 2 + 2)
    elseif kind.split then
        text:SetPoint("LEFT", fill, "LEFT", kind.pad, 0)
        side:SetPoint("RIGHT", fill, "RIGHT", right, 0)
        text:SetJustifyH("LEFT")
        side:SetJustifyH("RIGHT")
        side:SetWordWrap(false)
    else
        text:SetPoint("CENTER", fill, "CENTER", self.marked and -self.markWidth / 2 or 0, 0)
        text:SetJustifyH("CENTER")
    end
    if not kind.tile then
        self.mark:ClearAllPoints()
        self.mark:SetPoint("TOPRIGHT", fill, "TOPRIGHT")
        self.mark:SetPoint("BOTTOMRIGHT", fill, "BOTTOMRIGHT")
    end
    fill:ClearAllPoints()
    fill:SetPoint("TOPLEFT")
    fill:SetPoint("BOTTOMRIGHT", -kind.gap, kind.below)
end

local methods = {
    OnAcquire = function(self)
        self.marked, self.kind, self.look, self.whole = false, nil, nil, nil
        self:SetDisabled(false)
        self.mark:Hide()
        self:SetWidth(100)
        self:SetHeight(22)
        self.text:SetText("")
        self.side:SetText("")
        self.hover:Hide()
        self.markHover:Hide()
    end,

    -- A row's text is split at the first two spaces, a tile's at the first line break.
    SetText = function(self, text)
        local kind = self.kind
        local main, side = text, ""
        if kind and kind.tile then
            local label, value = text:match("^(.-)\n(.*)$")
            if label then main, side = value, label end
        elseif kind and kind.split then
            local left, right = text:match("^(.-)  +(.*)$")
            if left and left ~= "" and right ~= "" then main, side = left, right end
        end
        self.whole = text
        self.text:SetText(main)
        self.side:SetText(side)
        Fit(self)
    end,

    GetText = function(self)
        return self.whole or self.text:GetText()
    end,

    -- Switched off: it takes no click at all. (The "off" look alone still does.)
    SetDisabled = function(self, off)
        self.disabled = off and true or false
        if off then self.frame:Disable() else self.frame:Enable() end
    end,

    OnWidthSet = function(self)
        Fit(self)
    end,

    -- The "?" part on the right, a button of its own (OnMarkClick).
    SetMark = function(self, on)
        self.marked = on and true or false
        self.mark:SetShown(self.marked)
        if self.kind then Place(self) end
        Fit(self)
    end,

    -- Colours, font and sizes from the theme. `look`: see the top of this file.
    SetStyle = function(self, theme, look)
        self.look = look
        self.kind = ns.PaintButton(self, theme, look)
        self.lineHeight = theme.fontSize
        self.markWidth = theme.fontSize + 8
        self.mark:SetWidth(self.markWidth)
        Place(self)
        if self.whole then self:SetText(self.whole) else Fit(self) end
    end,
}

local function Constructor()
    local frame = CreateFrame("Button", nil, UIParent)
    frame:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    frame:Hide()

    local fill = frame:CreateTexture(nil, "BACKGROUND")
    fill:SetPoint("TOPLEFT")
    fill:SetPoint("BOTTOMRIGHT")

    local hover = frame:CreateTexture(nil, "BORDER")
    hover:SetAllPoints(fill)

    -- The hairline under a row.
    local line = frame:CreateTexture(nil, "ARTWORK")
    line:SetPoint("BOTTOMLEFT", fill, "BOTTOMLEFT")
    line:SetPoint("BOTTOMRIGHT", fill, "BOTTOMRIGHT")
    line:SetHeight(1)

    local text = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    text:SetWordWrap(true)
    local side = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")

    -- The "?" part: a button inside the button.
    local mark = CreateFrame("Button", nil, frame)
    mark:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    mark:SetPoint("TOPRIGHT", fill, "TOPRIGHT")
    mark:SetPoint("BOTTOMRIGHT", fill, "BOTTOMRIGHT")
    mark:SetWidth(16)
    mark:Hide()
    local markHover = mark:CreateTexture(nil, "BORDER")
    markHover:SetAllPoints(mark)
    markHover:Hide()
    local markText = mark:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    markText:SetPoint("CENTER", mark, "CENTER", 0, 0)
    markText:SetText("?")

    local widget = { type = Type, frame = frame, fill = fill, hover = hover, line = line, text = text, side = side,
        mark = mark, markHover = markHover, markText = markText }
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
