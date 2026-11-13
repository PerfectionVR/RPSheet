-- The minimap icon (also available to broker display addons).
local ADDON, ns = ...
local RPSheet = ns.addon
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

function RPSheet:BuildMinimapIcon()
    local broker = LibStub("LibDataBroker-1.1"):NewDataObject(ADDON, {
        type = "launcher",
        text = "RP Sheet",
        icon = "Interface\\ICONS\\INV_Misc_Dice_02",
        OnClick = function(_, button)
            if button == "RightButton" then
                AceConfigDialog:Open(ADDON)
            elseif IsShiftKeyDown() then
                self:ToggleLock()
            else
                self:ToggleWindow()
            end
        end,
        OnTooltipShow = function(tooltip)
            tooltip:AddLine("RP Sheet")
            tooltip:AddLine("Left-click: show or hide the sheet", 1, 1, 1)
            tooltip:AddLine("Shift-click: lock or unlock the sheet", 1, 1, 1)
            tooltip:AddLine("Right-click: settings", 1, 1, 1)
        end,
    })
    LibStub("LibDBIcon-1.0"):Register(ADDON, broker, self.db.profile.minimap)
end

function RPSheet:SetMinimapIconShown(shown)
    self.db.profile.minimap.hide = not shown
    local icon = LibStub("LibDBIcon-1.0")
    if shown then icon:Show(ADDON) else icon:Hide(ADDON) end
end
