-- Spell components that are a weapon at hand, coins from the purse or pieces of
-- ammunition (data in Data/SpellComponentKinds.lua): how many of a part the character
-- has, and what a part is called. Sheet/SpellComponents.lua asks here for every part, so the check, the
-- taking and the tooltip treat all kinds alike.
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon

-- True if a weapon of that kind (`ranged` or melee), worth that much, is what the part
-- asks for.
local function Fits(part, ranged, proficient, worth)
    if part.weapon == "melee" and ranged then return false end
    if part.weapon == "proficient" and not proficient then return false end
    return (worth or 0) >= part.cost
end

-- What a ready weapon is worth: what a weapon of the player's own says it is worth
-- (the Weapons page), the carried item of its name, or the basic weapon's price.
local function Worth(sheet, weapon)
    if (weapon.cost or 0) > 0 then return weapon.cost end
    for _, item in ipairs(sheet.items or {}) do
        if item.name == weapon.name and (item.cost or 0) > 0 then return item.cost end
    end
    local listed = R.ITEMS[weapon.base]
    return listed and listed.cost or 0
end

-- The name of a weapon that serves as the part, or nil: one of the weapons that are
-- ready, or a thrown weapon carried in the inventory.
function RPSheet:ComponentWeapon(part)
    local sheet = self:Sheet()
    for _, weapon in ipairs(ns.ReadyWeapons(sheet)) do
        local base = weapon.base or ""
        if weapon.heal then
            -- a healing "weapon" is no weapon
        elseif not R.WEAPONS[base] then
            -- A weapon of the player's own says itself whether it is ranged and what
            -- it is worth; one without a worth is no component (claws, a bite).
            if Fits(part, weapon.ranged == true, weapon.proficient, Worth(sheet, weapon)) then return weapon.name end
        elseif Fits(part, R.WEAPONS[base].ranged, weapon.proficient, Worth(sheet, weapon)) then
            return weapon.name
        end
    end
    for _, item in ipairs(sheet.items or {}) do
        local base = ns.ItemBase(item)
        local data = R.WEAPONS[base]
        if item.name ~= "" and (item.qty or 0) > 0 and data and data.props.T then
            local worth = (item.cost or 0) > 0 and item.cost or (R.ITEMS[base] and R.ITEMS[base].cost)
            if Fits(part, data.ranged, ns.SheetWeaponProficient(sheet, base), worth) then return item.name end
        end
    end
end

-- How many castings' worth of a part the character has: things carried, coins in
-- the purse, or 1 for a weapon (it is kept, so one does for any number).
function RPSheet:ComponentCount(part)
    if part.weapon then return self:ComponentWeapon(part) and 1 or 0 end
    if part.ammo then return self:AmmoCount(part) end -- Sheet/ComponentAmmo.lua
    if part.coins then return math.floor(self:Coins() / part.coins) end
    local _, count = self:CarriedComponent(part)
    return count
end

-- How many of a part a casting on `targets` targets needs.
function ns.ComponentNeed(part, targets)
    if part.weapon then return 1 end
    return (part.qty or 1) * (part.each and math.max(1, targets or 1) or 1)
end

-- "4 x Ivory strip (50 gp)", "a melee weapon worth at least 1 sp", "2 cp", "4 arrows or bolts",
-- "Black onyx (150 gp) for each corpse", or with a number of targets "3 x Black onyx (150 gp)".
function ns.ComponentText(part, targets)
    if part.weapon then
        return ("%s worth at least %s"):format(R.COMPONENT_WEAPONS[part.weapon] or "a weapon", ns.CoinText(part.cost))
    end
    local need = ns.ComponentNeed(part, targets)
    if part.ammo then return ("%d %s"):format(need, part.words) end
    if part.coins then return ns.CoinText(part.coins * need) end
    local text = need > 1 and ("%d x %s"):format(need, part.item) or part.item
    if part.each and not targets then text = ("%s for each %s"):format(text, part.each) end
    return text
end
