-- The sheet window itself: creating it, showing and hiding, locking, and theming.
-- What goes inside it is in SheetContent.lua.
local ADDON, ns = ...
local RPSheet = ns.addon
local UI = ns.UI
local AceGUI = LibStub("AceGUI-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

function RPSheet:BuildWindow()
    local saved = self.db.char
    local theme = self.db.profile.theme
    UI.SetColors(theme)

    local window = AceGUI:Create("RPSheetWindow")
    window:SetStatusTable(self.db.profile.window)
    window:SetLayout("Fill")
    window:SetTheme(theme)
    window:SetCallback("OnLockClick", function() self:ToggleLock() end)
    window:SetCallback("OnEditClick", function() AceConfigDialog:Open(ADDON) end)
    window:SetCallback("OnClose", function() saved.shown = false end)
    window:SetCallback("OnShow", function() saved.shown = true; self:Refresh() end)
    self.window = window

    local body = AceGUI:Create("ScrollFrame")
    body:SetLayout("Flow")
    window:AddChild(body)
    self.body = body

    self:Populate()
    self:ApplyLock()
    if not saved.shown then window:Hide() end
end

function RPSheet:ToggleWindow()
    if self.window.frame:IsShown() then self.window:Hide() else self.window:Show() end
end

-- Locked: the window can't be moved or resized, and its title bar, background and
-- edges let clicks through to the game. The rows on the sheet stay clickable.
function RPSheet:ApplyLock()
    self.window:SetLocked(self.db.profile.locked)
end

function RPSheet:ToggleLock()
    self.db.profile.locked = not self.db.profile.locked
    self:ApplyLock()
    self:Refresh()
end

-- Re-skins the window after a theme change (see Themes.lua).
function RPSheet:ApplyTheme()
    local theme = self.db.profile.theme
    UI.SetColors(theme)
    self.window:SetTheme(theme)
    self:Populate()
end

-- Re-applies everything that comes from the general settings, after the player
-- switched, copied or reset the settings profile.
function RPSheet:SettingsChanged()
    if not self.window then return end
    self.window:SetStatusTable(self.db.profile.window)
    self:ApplyLock()
    self:SetMinimapIconShown(not self.db.profile.minimap.hide)
    self:ApplyTheme()
end

-- Replaces the saved theme with a preset; every value can be changed afterwards.
function RPSheet:LoadThemePreset(key)
    local preset = ns.Themes[key]
    if not preset then return end
    local theme = self.db.profile.theme
    for field, value in pairs(preset) do
        theme[field] = type(value) == "table" and CopyTable(value) or value
    end
    self.db.profile.themePreset = key
    self:ApplyTheme()
end
