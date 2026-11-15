-- What an item's block in the item browser says about it (UI/ItemBrowser.lua): what a
-- weapon or armor does, a magic item's rarity and effects, price and weight.
local _, ns = ...
local R = ns.Rules
local UI = ns.UI

local RED = "|cffff5555"

local function ArmorLine(data, kind)
    local parts = { ("%s armor, Armor Class %d"):format(kind:gsub("^%l", string.upper), data.ac) }
    if not data.dexCap then
        parts[1] = parts[1] .. " + Dexterity modifier"
    elseif data.dexCap > 0 then
        parts[1] = parts[1] .. (" + Dexterity modifier (at most %d)"):format(data.dexCap)
    end
    if data.minStr then parts[#parts + 1] = ("needs Strength %d"):format(data.minStr) end
    if data.stealth then parts[#parts + 1] = "disadvantage on Stealth" end
    return table.concat(parts, ", ") .. "."
end

-- Lines for the item called `name`. `item` is the carried entry when there is one;
-- its own note, rarity and effects go before the catalogue's. `classKey` judges the
-- training by a class alone (the wizard's draft) and not by the active character.
function UI.ItemLines(self, name, item, classKey)
    local training = classKey and ns.ArmorTraining(classKey) or self:ArmorTraining()
    local known, lines = R.ITEMS[name], {}
    -- A magic or named item is described by the plain thing it counts as.
    local base = item and ns.ItemBase(item) or name
    local weapon, armor = R.WEAPONS[base], R.ARMOR_ITEMS[base]
    if base ~= name then lines[#lines + 1] = ("Counts as: %s."):format(base) end
    if weapon then
        lines[#lines + 1] = ("%s weapon: %s. Mastery: %s."):format(
            weapon.category == "SIMPLE" and "Simple" or "Martial", R.WeaponSummary(base), weapon.mastery)
        local proficient
        if classKey then proficient = ns.WeaponProficient(classKey, base) else proficient = ns.SheetWeaponProficient(self:Sheet(), base) end
        if not proficient then lines[#lines + 1] = RED .. "You are not proficient with it.|r" end
    elseif armor then
        local kind = ns.ArmorKind(armor)
        lines[#lines + 1] = ArmorLine(R.ARMOR[armor], kind)
        if not training[kind] then lines[#lines + 1] = RED .. "You have no training with it.|r" end
    elseif base == R.SHIELD_ITEM then
        lines[#lines + 1] = ("+%d to Armor Class while equipped."):format(R.SHIELD_AC)
        if not training.shield then lines[#lines + 1] = RED .. "You have no training with shields.|r" end
    end

    if item and (item.bonus or 0) > 0 and (weapon or armor or base == R.SHIELD_ITEM) then
        lines[#lines + 1] = UI.GREEN .. (weapon and ("+%d to attack and damage rolls with it."):format(item.bonus)
            or ("+%d to Armor Class while equipped."):format(item.bonus)) .. "|r"
    end

    local rarity = item and item.rarity ~= "" and item.rarity or (known and known.rarity)
    local attune = item and item.attune or (known and known.attune)
    if rarity or (item and item.magic) then
        lines[#lines + 1] = ("%sMagic item%s%s|r"):format(R.RARITY_COLORS[rarity] or UI.ACCENT,
            rarity and (", " .. rarity:lower()) or "", attune and ", requires attunement" or "")
    end
    local desc = item and item.desc ~= "" and item.desc or (known and known.desc)
    if desc and desc ~= "" then lines[#lines + 1] = desc end
    -- A spell scroll says whose numbers it casts with and whether this character can read it.
    for _, line in ipairs(item and not classKey and self:ScrollHelp(item) or {}) do lines[#lines + 1] = UI.GREY .. line .. "|r" end
    for _, effect in ipairs(item and item.effects or (known and known.effects) or {}) do
        lines[#lines + 1] = UI.GREEN .. self:EffectText(effect) .. "|r"
    end

    local cost, weight = item and item.cost or (known and known.cost), item and item.weight or (known and known.weight)
    local summary = R.ItemSummary(cost, weight)
    if summary ~= "" then lines[#lines + 1] = UI.GREY .. summary .. " each|r" end
    return lines
end
