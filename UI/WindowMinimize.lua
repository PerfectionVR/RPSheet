-- Minimizing for the sheet window (UI/Window.lua): a minimized window is only its
-- title bar, opens while the mouse is over it and folds up again shortly after the
-- mouse has left.
local _, ns = ...

local FOLD_DELAY = 0.4 -- seconds the mouse must be away before the window folds up
local PLUS, MINUS = "Interface\\Buttons\\UI-PlusButton-Up", "Interface\\Buttons\\UI-MinusButton-Up"

-- Adds SetCollapsed and SetMinimized to the window widget. `barHeight` is the height
-- of the folded window.
function ns.AttachMinimize(widget, barHeight)
    local frame = widget.frame
    local away = 0

    -- Folds the window up to its title bar, or opens it to the height it had.
    function widget:SetCollapsed(on)
        if (self.collapsed == true) == on then return end
        self.collapsed = on
        -- Pin the top-left corner first. Dragging leaves the window anchored wherever
        -- the game likes (often its middle), and it would fold towards that point.
        local left, top = frame:GetLeft(), frame:GetTop()
        if left and top then
            frame:ClearAllPoints()
            frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left, top)
        end
        if on then
            self.fullHeight = frame:GetHeight()
            frame:SetHeight(barHeight)
        else
            frame:SetHeight(self.fullHeight or frame:GetHeight())
        end
        self.content:SetShown(not on)
        if self.rail then self.rail:SetShown(not on and self.railOn == true) end
        self.sizer:SetShown(not on and not self.locked)
    end

    local function Watch(_, elapsed)
        -- Held open while it is being dragged or resized.
        local over = frame:IsMouseOver() or (not widget.collapsed and IsMouseButtonDown("LeftButton"))
        if over then
            away = 0
            widget:SetCollapsed(false)
        else
            away = away + elapsed
            if away >= FOLD_DELAY then widget:SetCollapsed(true) end
        end
    end

    function widget:SetMinimized(on)
        self.minimized = on
        self.minimizeButton.icon:SetTexture(on and PLUS or MINUS)
        away = 0
        if not on then self:SetCollapsed(false) end
        frame:SetScript("OnUpdate", on and Watch or nil)
    end
end
