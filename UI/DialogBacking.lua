-- The options library's windows are see-through, which makes them hard to read over
-- anything busy. This puts a nearly solid panel in the sheet theme's background colour
-- behind our own windows (settings, creation wizard, level dialog) while they are open.
--
-- The window frames are shared with other addons' settings, so the panel is ours
-- alone: it is attached when one of our windows opens and hidden when that frame closes.
local ADDON, ns = ...
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

local OURS = { [ADDON] = true, [ADDON .. "Wizard"] = true, [ADDON .. "Level"] = true }
local MIN_ALPHA = 0.95
local backings = {} -- one panel per window name

function ns.AddDialogBacking(dialog)
    local widget = AceConfigDialog.OpenFrames[dialog]
    local frame = widget and widget.frame
    if not frame then return end

    local backing = backings[dialog]
    if not backing then
        backing = UIParent:CreateTexture(nil, "BACKGROUND", nil, -8)
        backings[dialog] = backing
    end
    local theme = ns.addon.db and ns.addon.db.profile.theme
    local color = theme and theme.bg or { 0.04, 0.04, 0.05, 1 }
    backing:SetColorTexture(color[1], color[2], color[3], math.max(MIN_ALPHA, color[4] or 1))
    backing:SetParent(frame)
    backing:ClearAllPoints()
    backing:SetPoint("TOPLEFT", 6, -6)
    backing:SetPoint("BOTTOMRIGHT", -6, 6)
    backing:Show()

    if not frame.rpSheetBackingHook then
        frame.rpSheetBackingHook = true
        frame:HookScript("OnHide", function(self)
            for _, panel in pairs(backings) do
                if panel:GetParent() == self then panel:Hide() end
            end
        end)
    end
end

-- Every way one of our windows gets opened or redrawn goes through this.
hooksecurefunc(AceConfigDialog, "Open", function(_, appName)
    if OURS[appName] then ns.AddDialogBacking(appName) end
end)
