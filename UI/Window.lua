-- "RPSheetWindow": a plain AceGUI container whose look is entirely set by a theme
-- (see Themes.lua). Movable by its title bar, resizable from the bottom-right corner,
-- and it remembers size and position in a status table like AceGUI's own Window.
local _, ns = ...
local AceGUI = LibStub("AceGUI-3.0")
local Type, Version = "RPSheetWindow", 1

local TITLE_HEIGHT, PADDING = 22, 8
local LOCK_ICON = "Interface\\PetBattles\\PetBattle-LockIcon"
local EDIT_ICON = "Interface\\Buttons\\UI-OptionsButton"

-- A small icon button in the title bar. Clicking it fires `event` on the widget
-- (set with widget:SetCallback); `tooltip(widget)` returns its title and text.
local function TitleButton(widget, offset, texture, event, tooltip)
    local button = CreateFrame("Button", nil, widget.frame)
    button:SetSize(TITLE_HEIGHT, TITLE_HEIGHT)
    button:SetPoint("TOPRIGHT", -1 - offset * TITLE_HEIGHT, -1)
    button:SetFrameLevel(widget.titleBar:GetFrameLevel() + 1)
    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetPoint("CENTER")
    button.icon:SetSize(TITLE_HEIGHT - 4, TITLE_HEIGHT - 4)
    button.icon:SetTexture(texture)
    button.icon:SetDesaturated(true) -- so the theme's accent colour can tint it
    local highlight = button:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints()
    highlight:SetColorTexture(1, 1, 1, 0.15)
    button:SetScript("OnClick", function() widget:Fire(event) end)
    button:SetScript("OnEnter", function(self)
        local title, text = tooltip(widget)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT")
        GameTooltip:AddLine(title)
        GameTooltip:AddLine(text, 1, 1, 1, true)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", GameTooltip_Hide)
    return button
end

local function SaveStatus(self)
    local frame, status = self.frame, self.status or self.localstatus
    status.width, status.height = frame:GetWidth(), frame:GetHeight()
    status.top, status.left = frame:GetTop(), frame:GetLeft()
end

local methods = {
    OnAcquire = function(self)
        self.frame:SetParent(UIParent)
        self.frame:SetFrameStrata("MEDIUM")
        self:ApplyStatus()
        self:SetLocked(false)
        self:Show()
    end,

    OnRelease = function(self)
        self.status = nil
        wipe(self.localstatus)
    end,

    Show = function(self) self.frame:Show() end,
    Hide = function(self) self.frame:Hide() end,
    SetTitle = function(self, title) self.titleText:SetText(title) end,

    SetStatusTable = function(self, status)
        self.status = status
        self:ApplyStatus()
    end,

    ApplyStatus = function(self)
        local frame, status = self.frame, self.status or self.localstatus
        self:SetWidth(status.width or 280)
        self:SetHeight(status.height or 480)
        frame:ClearAllPoints()
        if status.top and status.left then
            frame:SetPoint("TOP", UIParent, "BOTTOM", 0, status.top)
            frame:SetPoint("LEFT", UIParent, "LEFT", status.left, 0)
        else
            frame:SetPoint("CENTER", UIParent, "CENTER", 300, 0)
        end
    end,

    OnWidthSet = function(self, width)
        local contentWidth = math.max(0, width - PADDING * 2)
        self.content:SetWidth(contentWidth)
        self.content.width = contentWidth
    end,

    OnHeightSet = function(self, height)
        local contentHeight = math.max(0, height - TITLE_HEIGHT - PADDING * 2)
        self.content:SetHeight(contentHeight)
        self.content.height = contentHeight
    end,

    -- Locked: can't be moved or resized, and the frame itself lets clicks through.
    SetLocked = function(self, locked)
        self.locked = locked
        self.titleBar:EnableMouse(not locked)
        self.frame:EnableMouse(not locked)
        self.sizer:SetShown(not locked)
        -- One padlock: solid while locked, faded while unlocked.
        self.lockButton.icon:SetAlpha(locked and 1 or 0.35)
    end,

    SetTheme = function(self, theme)
        local accent = theme.accent
        self.frame:SetBackdropColor(unpack(theme.bg))
        self.frame:SetBackdropBorderColor(unpack(theme.border))
        self.frame:SetScale(theme.scale)
        self.titleBackground:SetColorTexture(accent[1], accent[2], accent[3], 0.15)
        self.titleText:SetFont(ns.ThemeFont(theme), theme.fontSize + 2, "")
        self.titleText:SetTextColor(accent[1], accent[2], accent[3])
        self.titleText:SetShadowOffset(1, -1)
        self.titleText:SetShadowColor(0, 0, 0, theme.shadow and 1 or 0)
        self.closeText:SetTextColor(accent[1], accent[2], accent[3])
        self.lockButton.icon:SetVertexColor(accent[1], accent[2], accent[3])
        self.editButton.icon:SetVertexColor(accent[1], accent[2], accent[3])
        self.sizerTexture:SetVertexColor(accent[1], accent[2], accent[3])
    end,
}

local function Constructor()
    local frame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:SetResizable(true)
    frame:SetResizeBounds(220, 200)
    frame:EnableMouse(true)
    frame:Hide()

    local widget = { type = Type, frame = frame, localstatus = {} }
    for name, method in pairs(methods) do widget[name] = method end
    frame.obj = widget

    frame:SetScript("OnShow", function() widget:Fire("OnShow") end)
    frame:SetScript("OnHide", function() widget:Fire("OnClose") end)

    -- Title bar: drag handle, title, close button
    local titleBar = CreateFrame("Frame", nil, frame)
    titleBar:SetPoint("TOPLEFT", 1, -1)
    titleBar:SetPoint("TOPRIGHT", -1, -1)
    titleBar:SetHeight(TITLE_HEIGHT)
    titleBar:EnableMouse(true)
    titleBar:SetScript("OnMouseDown", function() frame:StartMoving() end)
    titleBar:SetScript("OnMouseUp", function()
        frame:StopMovingOrSizing()
        SaveStatus(widget)
    end)
    widget.titleBar = titleBar

    widget.titleBackground = titleBar:CreateTexture(nil, "BACKGROUND")
    widget.titleBackground:SetAllPoints()

    widget.titleText = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    widget.titleText:SetPoint("LEFT", PADDING, 0)
    widget.titleText:SetPoint("RIGHT", -TITLE_HEIGHT * 3, 0)
    widget.titleText:SetJustifyH("LEFT")
    widget.titleText:SetWordWrap(false)

    local close = CreateFrame("Button", nil, frame)
    close:SetSize(TITLE_HEIGHT, TITLE_HEIGHT)
    close:SetPoint("TOPRIGHT", -1, -1)
    close:SetFrameLevel(titleBar:GetFrameLevel() + 1)
    close:SetScript("OnClick", function() widget:Hide() end)
    widget.closeText = close:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    widget.closeText:SetPoint("CENTER")
    widget.closeText:SetText("x")
    local closeHighlight = close:CreateTexture(nil, "HIGHLIGHT")
    closeHighlight:SetAllPoints()
    closeHighlight:SetColorTexture(1, 1, 1, 0.15)

    -- Lock and edit icons, left of the close button. They stay clickable while locked.
    widget.lockButton = TitleButton(widget, 1, LOCK_ICON, "OnLockClick", function(self)
        if self.locked then
            return "Unlock window", "The window is locked. Click to move or resize it again."
        end
        return "Lock window", "Stops the window from being moved or resized, and lets clicks on its title bar, background and edges through to the game. The rows stay clickable."
    end)
    widget.editButton = TitleButton(widget, 2, EDIT_ICON, "OnEditClick", function()
        return "Edit character", "Stats, armor, weapons, abilities, passives and appearance."
    end)

    -- Resize grip
    local sizer = CreateFrame("Frame", nil, frame)
    sizer:SetSize(14, 14)
    sizer:SetPoint("BOTTOMRIGHT", -1, 1)
    sizer:EnableMouse(true)
    sizer:SetScript("OnMouseDown", function() frame:StartSizing("BOTTOMRIGHT") end)
    sizer:SetScript("OnMouseUp", function()
        frame:StopMovingOrSizing()
        SaveStatus(widget)
    end)
    widget.sizer = sizer
    widget.sizerTexture = sizer:CreateTexture(nil, "OVERLAY")
    widget.sizerTexture:SetAllPoints()
    widget.sizerTexture:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")

    local content = CreateFrame("Frame", nil, frame)
    content:SetPoint("TOPLEFT", PADDING, -(TITLE_HEIGHT + PADDING))
    content:SetPoint("BOTTOMRIGHT", -PADDING, PADDING)
    content.obj = widget
    widget.content = content

    return AceGUI:RegisterAsContainer(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
