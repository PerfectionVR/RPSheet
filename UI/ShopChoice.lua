-- The "Buying from" line at the top of the item browser and the stable: whose
-- merchant the character is dealing with, which decides the discount on the Buy
-- buttons (Sheet/Shop.lua). Only shown when some faction gives the character one.
local _, ns = ...
local UI = ns.UI

local NOBODY = "nobody in particular"

local function Tip(self, factions)
    local lines = {
        "Merchants of a faction take a share off their prices once you are Honored with it: 10% off ordinary equipment and Common and Uncommon magic items. Revered makes it 15% and adds Rare items; Exalted 25% and Very Rare ones.",
        "The sheet can't tell where you are shopping, so say whose merchant you are buying from. Mounts and machines only a faction breeds or builds, fuel and spell components keep their price.",
    }
    local own = {}
    for _, faction in ipairs(factions) do
        own[#own + 1] = ("%s %d%%"):format(faction, (ns.RenownDiscount(self:Sheet(), faction)))
    end
    lines[#lines + 1] = "Your discounts: " .. table.concat(own, ", ") .. "."
    lines[#lines + 1] = "Left-click for the next one, right-click for the one before."
    return table.concat(lines, "\n\n")
end

-- Adds the line to `body`. Clicking goes through nobody in particular and every
-- faction with a discount, then fills the browser again with the new prices.
function UI.AddShopChoice(self, body)
    local factions = ns.ShopFactions(self:Sheet())
    if #factions == 0 then return end
    local current, at = self:ShopFaction(), 0
    for index, faction in ipairs(factions) do
        if faction == current then at = index end
    end
    local shown = current and ("%s (%d%% off)"):format(current, (ns.RenownDiscount(self:Sheet(), current))) or NOBODY
    UI.AddLabel(body, 1, ("Buying from  %s%s|r"):format(UI.ACCENT, shown), function(button)
        -- Position 0 is nobody; the list wraps around both ways.
        local step = button == "RightButton" and -1 or 1
        self:SetShopFaction(factions[(at + step) % (#factions + 1)])
        -- On the next frame: the line is part of what gets rebuilt.
        C_Timer.After(0, function() self:PopulateItemBrowser() end)
    end, "Buying from", Tip(self, factions))
end
