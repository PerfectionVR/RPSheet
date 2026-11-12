-- "RPSheetBar": an AceGUI widget showing a value as a filled bar with text on top
-- (HP, class resource, counter). Clickable like a row: fires OnClick(button), OnEnter, OnLeave.
local AceGUI = LibStub("AceGUI-3.0")
local Type, Version = "RPSheetBar", 1

local GAP = 3 -- space kept free to the right and below, so neighbouring bars don't touch

local methods = {
    OnAcquire = function(self)
        self:SetWidth(200)
        self:SetHeight(18)
        self:SetValue(0, 1)
        self:SetText("")
        self.hover:Hide()
    end,

    SetValue = function(self, value, max)
        self.bar:SetMinMaxValues(0, math.max(1, max))
        self.bar:SetValue(math.max(0, math.min(value, max)))
    end,

    SetText = function(self, text)
        self.text:SetText(text)
    end,

    -- Bar colour, plus font, text colour and row height from the theme.
    SetStyle = function(self, theme, color)
        self.bar:SetStatusBarColor(color[1], color[2], color[3], color[4] or 1)
        self.text:SetFont(theme.font, theme.fontSize, "")
        self.text:SetTextColor(theme.text[1], theme.text[2], theme.text[3])
        self.text:SetShadowOffset(1, -1)
        self.text:SetShadowColor(0, 0, 0, theme.shadow and 1 or 0)
        self.hover:SetColorTexture(unpack(theme.highlight))
        self:SetHeight(theme.fontSize + 7 + GAP)
    end,
}

local function Constructor()
    local frame = CreateFrame("Button", nil, UIParent)
    frame:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    frame:Hide()

    local track = frame:CreateTexture(nil, "BACKGROUND")
    track:SetPoint("TOPLEFT")
    track:SetPoint("BOTTOMRIGHT", -GAP, GAP)
    track:SetColorTexture(0, 0, 0, 0.45)

    local bar = CreateFrame("StatusBar", nil, frame)
    bar:SetAllPoints(track)
    bar:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8")

    local hover = bar:CreateTexture(nil, "ARTWORK")
    hover:SetAllPoints(track)
    hover:SetBlendMode("ADD")

    local text = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    text:SetPoint("LEFT", 4, 0)
    text:SetPoint("RIGHT", -4, 0)
    text:SetJustifyH("CENTER")
    text:SetWordWrap(false)

    local widget = { type = Type, frame = frame, bar = bar, text = text, hover = hover }
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

    return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
