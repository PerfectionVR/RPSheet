-- "RPSheetBar": an AceGUI widget showing a value as a filled bar (HP, class resource,
-- counter). Two shapes: thin, a slim bar with its text above it (the sheet's
-- trackers), and full, the text on the bar (a combatant's health in the combat
-- window). Clickable like a row: fires OnClick(button), OnEnter, OnLeave.
local _, ns = ...
local AceGUI = LibStub("AceGUI-3.0")
local Type, Version = "RPSheetBar", 2

local GAP = 6 -- space kept free to the right and below, so neighbouring bars don't touch
local THIN = 6 -- height of a thin bar

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

    -- Bar colour, plus font, text colour and height from the theme.
    SetStyle = function(self, theme, color, thin)
        local tokens = ns.Tokens(theme)
        local track, bar, text = self.track, self.bar, self.text
        self.thin = thin and true or false
        bar:SetStatusBarTexture(ns.ThemeBarTexture(theme))
        bar:SetStatusBarColor(color[1], color[2], color[3], color[4] or 1)
        track:SetColorTexture(unpack(tokens.track))
        text:SetFont(ns.ThemeFont(theme), theme.fontSize, "")
        text:SetTextColor(tokens.text[1], tokens.text[2], tokens.text[3])
        text:SetShadowOffset(1, -1)
        text:SetShadowColor(0, 0, 0, (theme.shadow or not thin) and 1 or 0)
        self.hover:SetColorTexture(unpack(tokens.hover))
        track:ClearAllPoints()
        text:ClearAllPoints()
        if thin then
            track:SetPoint("BOTTOMLEFT", 0, GAP)
            track:SetPoint("BOTTOMRIGHT", -GAP, GAP)
            track:SetHeight(THIN)
            -- (from the widget: the text belongs to the slim bar, which is where a
            -- point without a frame would hang it)
            text:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 0, -2)
            text:SetPoint("TOPRIGHT", self.frame, "TOPRIGHT", -GAP, -2)
            text:SetJustifyH("LEFT")
            self:SetHeight(theme.fontSize + 6 + THIN + GAP)
        else
            track:SetPoint("TOPLEFT")
            track:SetPoint("BOTTOMRIGHT", -GAP, GAP)
            text:SetPoint("LEFT", track, "LEFT", 4, 0)
            text:SetPoint("RIGHT", track, "RIGHT", -4, 0)
            text:SetJustifyH("CENTER")
            self:SetHeight(theme.fontSize + 8 + GAP)
        end
    end,
}

local function Constructor()
    local frame = CreateFrame("Button", nil, UIParent)
    frame:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    frame:Hide()

    local track = frame:CreateTexture(nil, "BACKGROUND")
    track:SetPoint("TOPLEFT")
    track:SetPoint("BOTTOMRIGHT", -GAP, GAP)

    local bar = CreateFrame("StatusBar", nil, frame)
    bar:SetAllPoints(track)
    bar:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8")

    -- Under the mouse the whole widget lights up, the text of a thin bar included. The
    -- wash belongs to the bar's own frame, which is drawn over this one's textures.
    local hover = bar:CreateTexture(nil, "ARTWORK")
    hover:SetPoint("TOPLEFT", frame, "TOPLEFT")
    hover:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -GAP, GAP - 2)

    local text = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    text:SetWordWrap(false)

    local widget = { type = Type, frame = frame, track = track, bar = bar, text = text, hover = hover }
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
