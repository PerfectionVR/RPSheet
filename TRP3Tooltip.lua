-- Adds a "Stats" section to Total RP 3 character tooltips, below the OOC block:
-- always on your own, and on other players whose stats were received (see Sync.lua).
--
-- TRP3 has no extension point for its tooltip, so this wraps two methods of its
-- tooltip builder in memory (no TRP3 files are changed). Going through the builder
-- keeps TRP3's own line counting and font sizing correct. If TRP3 changes its
-- tooltip code, the section falls back to the bottom or simply doesn't appear.
local _, ns = ...

-- TRP3 separates its tooltip blocks with AddSpace; the 4th one closes the OOC block.
local SPACES_BEFORE_SECTION = 4

function ns.RefreshTRP3Tooltip() end -- replaced below once the hook is in place

function ns.HookTRP3Tooltip(addon)
    local tooltipAPI = TRP3_API and TRP3_API.ui and TRP3_API.ui.tooltip
    local tooltip = TRP3_CharacterTooltip
    if not (tooltipAPI and tooltip and tooltipAPI.createTooltipBuilder) then return end

    -- Every builder shares one prototype; a throwaway builder gives access to it.
    local ok, proto = pcall(function()
        return getmetatable(tooltipAPI.createTooltipBuilder(tooltip)).__index
    end)
    if not ok or type(proto) ~= "table" or not (proto.AddSpace and proto.AddLine and proto.Build) then return end

    local spaces, added = 0, false

    local function AddSection(builder)
        if not addon.db.profile.tooltip then return end
        local data
        if tooltip.target == TRP3_API.globals.player_id then
            data = addon:GetStatData()
        else
            data = addon:GetCachedStats(tooltip.target)
        end
        if not data then return end
        local colors = tooltipAPI.getTooltipTextColors()
        builder:AddLine("Stats", colors.MAIN, tooltipAPI.getSubLineFontSize())
        for _, line in ipairs(addon:GetStatLines(data)) do
            builder:AddLine(line, colors.SECONDARY, tooltipAPI.getSmallLineFontSize(), true)
        end
    end

    local addSpace, build = proto.AddSpace, proto.Build

    proto.AddSpace = function(self)
        addSpace(self)
        if self.tooltip ~= tooltip or added then return end
        spaces = spaces + 1
        if spaces == SPACES_BEFORE_SECTION then
            added = true
            pcall(AddSection, self)
            addSpace(self)
        end
    end

    proto.Build = function(self)
        if self.tooltip == tooltip then
            if not added then
                addSpace(self)
                pcall(AddSection, self)
            end
            spaces, added = 0, false
        end
        return build(self)
    end

    tooltip:HookScript("OnHide", function() spaces, added = 0, false end)

    -- Stats usually arrive a moment after the tooltip opened. Re-send TRP3's own
    -- "mouse over changed" event so it redraws the tooltip that is already showing.
    function ns.RefreshTRP3Tooltip(targetID)
        if not tooltip:IsShown() or tooltip.target ~= targetID or not tooltip.targetType then return end
        pcall(function()
            TRP3_Addon:TriggerEvent(TRP3_Addon.Events.MOUSE_OVER_CHANGED, tooltip.target, tooltip.targetMode, tooltip.targetType)
        end)
    end
end
