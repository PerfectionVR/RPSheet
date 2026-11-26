-- The side rail of a window (UI/Window.lua): a darker pane down its left side with a
-- few lines about what the window shows on top, and under them one entry for each of
-- its pages, with an icon. The open page is marked with a wash and a strip in the
-- accent colour. A window without pages has no rail.
--   widget:SetRail(theme, head, items, open, pick)
--     head    text over the entries
--     items   a list of { name, icon, tip }
--     open    the name of the page that is showing
--     pick    pick(name) is called for a click on another
--   widget:SetRail()   takes the rail away
--   widget.railItems   the entries shown: { frame, name, open, text }
local _, ns = ...

local WIDTH, INSET = 126, 10

local function Entry(rail)
    local button = CreateFrame("Button", nil, rail)
    button.wash = button:CreateTexture(nil, "BACKGROUND")
    button.wash:SetAllPoints()
    button.hover = button:CreateTexture(nil, "BORDER")
    button.hover:SetAllPoints()
    button.hover:Hide()
    button.strip = button:CreateTexture(nil, "ARTWORK")
    button.strip:SetPoint("TOPLEFT")
    button.strip:SetPoint("BOTTOMLEFT")
    button.strip:SetWidth(2)
    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetPoint("LEFT", INSET, 0)
    button.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92) -- without the icon's own edge
    button.text = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    button.text:SetPoint("RIGHT", -4, 0)
    button.text:SetJustifyH("LEFT")
    button.text:SetWordWrap(false)
    button:SetScript("OnEnter", function(self)
        if not self.open then self.hover:Show() end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(self.name)
        if self.tip then GameTooltip:AddLine(self.tip, 1, 1, 1, true) end
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function(self)
        self.hover:Hide()
        GameTooltip:Hide()
    end)
    button:SetScript("OnClick", function(self)
        if not self.open and self.pick then self.pick(self.name) end
    end)
    return button
end

-- `top` is where the rail starts under the frame's top edge; `changed()` is called
-- when the rail comes, goes or is filled, so the window can give its contents the
-- room that is left (widget.railWidth).
function ns.AttachRail(widget, top, changed)
    local frame = widget.frame
    local rail = CreateFrame("Frame", nil, frame)
    rail:SetPoint("TOPLEFT", 1, -top)
    rail:SetPoint("BOTTOMLEFT", 1, 1)
    rail:SetWidth(WIDTH)
    rail:Hide()
    local ground = rail:CreateTexture(nil, "BACKGROUND")
    ground:SetAllPoints()
    local edge = rail:CreateTexture(nil, "ARTWORK")
    edge:SetPoint("TOPRIGHT")
    edge:SetPoint("BOTTOMRIGHT")
    edge:SetWidth(1)
    local head = rail:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    head:SetPoint("TOPLEFT", INSET, -INSET)
    head:SetWidth(WIDTH - INSET * 2)
    head:SetJustifyH("LEFT")
    head:SetWordWrap(true)

    local entries = {}
    widget.rail, widget.railItems, widget.railWidth = rail, {}, 0

    function widget:SetRail(theme, text, items, open, pick)
        wipe(self.railItems)
        for _, entry in ipairs(entries) do entry:Hide() end
        self.railOn = items ~= nil
        self.railWidth = items and WIDTH or 0
        rail:SetShown(self.railOn and not self.collapsed)
        if not items then return changed(self) end

        local tokens = ns.Tokens(theme)
        local font, size = ns.ThemeFont(theme), theme.fontSize
        ground:SetColorTexture(unpack(tokens.shade))
        edge:SetColorTexture(unpack(tokens.line))
        head:SetFont(font, math.max(9, size - 1), "")
        head:SetTextColor(tokens.muted[1], tokens.muted[2], tokens.muted[3])
        head:SetText(text or "")
        local y = -(INSET * 2 + (head:GetStringHeight() or 0))
        local height = size + 16
        for index, item in ipairs(items) do
            local entry = entries[index] or Entry(rail)
            entries[index] = entry
            local isOpen = item.name == open
            entry.name, entry.tip, entry.open, entry.pick = item.name, item.tip, isOpen, pick
            entry:ClearAllPoints()
            entry:SetPoint("TOPLEFT", 0, y)
            entry:SetPoint("TOPRIGHT", -1, y)
            entry:SetHeight(height)
            entry.wash:SetColorTexture(tokens.wash[1], tokens.wash[2], tokens.wash[3], isOpen and tokens.wash[4] or 0)
            entry.hover:SetColorTexture(unpack(tokens.hover))
            entry.strip:SetColorTexture(tokens.accent[1], tokens.accent[2], tokens.accent[3], isOpen and 1 or 0)
            entry.icon:SetSize(size + 4, size + 4)
            entry.icon:SetTexture(item.icon)
            entry.icon:SetDesaturated(not isOpen)
            entry.icon:SetAlpha(isOpen and 1 or 0.6)
            entry.text:SetPoint("LEFT", INSET + size + 12, 0)
            entry.text:SetFont(font, size, "")
            local color = isOpen and tokens.text or tokens.dim
            entry.text:SetTextColor(color[1], color[2], color[3])
            entry.text:SetText(item.name)
            entry:Show()
            self.railItems[index] = { frame = entry, name = item.name, open = isOpen, text = entry.text }
            y = y - height
        end
        changed(self)
    end
end
