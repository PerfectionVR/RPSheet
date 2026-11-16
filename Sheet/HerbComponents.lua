-- Herbs in place of a priced material component: the feat Inscription Adept lets the
-- spells it gives be cast with gathered herbs (sheet.materials.herbs, Sheet/Professions.lua)
-- of the component's worth instead of the component itself. The check and the taking
-- in Sheet/SpellComponents.lua ask here for what the carried things don't cover.
local _, ns = ...
local RPSheet = ns.addon

local FEATS = { ["Inscription Adept"] = true }
local KIND = "herbs"

-- The feat that lets herbs stand in for this spell's components, or nil.
function RPSheet:HerbFeat(spell)
    local found = spell and ns.FeatSpells(self:Sheet())[spell.name]
    return found and FEATS[found.feat] and found.feat or nil
end

-- How many of a part the herbs pay for (0 for a part that is a weapon, ammunition,
-- coins or has no price, or for a spell no such feat gives).
function RPSheet:HerbParts(spell, part)
    if part.weapon or part.ammo or part.coins or (part.cost or 0) <= 0 or not self:HerbFeat(spell) then return 0 end
    return math.floor((self:Trade().materials[KIND] or 0) / part.cost)
end

-- Pays for one of the part with herbs. Returns what was used, for the announcement.
function RPSheet:TakeHerbs(part)
    self:AddMaterials(KIND, -part.cost)
    return ("herbs worth %s"):format(ns.CoinText(part.cost))
end

-- A line for the spell's tooltip, or nil.
function RPSheet:HerbHelp(spell, part)
    local feat = self:HerbFeat(spell)
    if not feat or part.weapon or part.ammo or part.coins or (part.cost or 0) <= 0 then return end
    return ("%s: herbs worth %s each can stand in for it. You have %s in herbs."):format(
        feat, ns.CoinText(part.cost), ns.CoinText(self:Trade().materials[KIND] or 0))
end
