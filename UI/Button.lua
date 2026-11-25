-- "RPSheetButton": an AceGUI widget for something to click in a window: a box with
-- an edge all round in the accent colour, so it reads as a button and not as text.
-- Three looks: "on" (can be clicked now), "off" (greyed: a click says why not) and
-- "picked" (the one of several that is chosen, filled). Fires OnClick(button),
-- OnEnter and OnLeave.
local _, ns = ...
local AceGUI = LibStub("AceGUI-3.0")
local Type, Version = "RPSheetButton", 1

local GAP = 3 -- space kept free to the right and below, between neighbouring buttons

local methods = {
    OnAcquire = function(self)
        self:SetWidth(100)
        self:SetHeight(22)
        self:SetText("")
        self.hover:Hide()
    end,

    SetText = function(self, text)
        self.text:SetText(text)
    end,

    -- Colours, font and height from the theme. `look` is "on", "off" or "picked".
    SetStyle = function(self, theme, look)
        local accent, muted = theme.accent, theme.muted
        local edge = look == "off" and muted or accent
        local color = look == "off" and muted or (look == "picked" and theme.text or accent)
        self.text:SetFont(ns.ThemeFont(theme), theme.fontSize, "")
        self.text:SetTextColor(color[1], color[2], color[3])
        self.text:SetShadowOffset(1, -1)
        self.text:SetShadowColor(0, 0, 0, theme.shadow and 1 or 0)
        self.fill:SetColorTexture(edge[1], edge[2], edge[3], look == "picked" and 0.45 or (look == "off" and 0.05 or 0.14))
        for _, line in ipairs(self.edges) do
            line:SetColorTexture(edge[1], edge[2], edge[3], look == "off" and 0.35 or (look == "picked" and 1 or 0.75))
        end
        self.hover:SetColorTexture(unpack(theme.highlight))
        self:SetHeight(theme.fontSize + 10 + GAP)
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
    text:SetPoint("LEFT", fill, 4, 0)
    text:SetPoint("RIGHT", fill, -4, 0)
    text:SetJustifyH("CENTER")
    text:SetWordWrap(false)

    local widget = { type = Type, frame = frame, fill = fill, hover = hover, edges = edges, text = text }
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
