-- Carried armor, shields and basic weapons as the things you wear and wield: equipping
-- one in the inventory puts the armor on, raises the shield or readies the weapon, and
-- putting it away undoes that.
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon

-- "armor", "shield" or "weapon" for an item that is one of those; nil for the rest.
function ns.ItemSlot(item)
    if R.ARMOR_ITEMS[item.name] then return "armor" end
    if item.name == R.SHIELD_ITEM then return "shield" end
    if R.WEAPONS[item.name] then return "weapon" end
end

-- The sheet's weapons that are at hand: named and not put away.
function ns.ReadyWeapons(sheet)
    local ready = {}
    for _, weapon in ipairs(sheet.weapons) do
        if weapon.name ~= "" and not weapon.stowed then ready[#ready + 1] = weapon end
    end
    return ready
end

-- Readies or puts away the sheet's weapons of one basic kind. A kind that isn't on
-- the sheet yet gets an entry when it is readied.
local function ReadyWeapon(sheet, name, on, modifier, canMaster)
    local found = false
    for _, weapon in ipairs(sheet.weapons) do
        if weapon.base == name then
            weapon.stowed, found = not on, true
        end
    end
    if found or not on then return end
    sheet.weapons[#sheet.weapons + 1] = ns.NewBasicWeapon(name, modifier, ns.WeaponProficient(sheet.class, name), canMaster())
end

-- Equips an item of `sheet` or puts it away. `modifier(stat)` gives the character's
-- ability modifiers and `canMaster()` says whether a new weapon may take a mastery.
function ns.EquipItem(sheet, item, on, modifier, canMaster)
    item.equipped = on
    local slot = ns.ItemSlot(item)
    if slot == "armor" then
        local key = R.ARMOR_ITEMS[item.name]
        if on then
            sheet.armor = key
            -- One suit at a time.
            for _, other in ipairs(sheet.items) do
                if other ~= item and R.ARMOR_ITEMS[other.name] then other.equipped = false end
            end
        elseif sheet.armor == key then
            sheet.armor = "NONE"
        end
    elseif slot == "shield" then
        sheet.shield = on
    elseif slot == "weapon" then
        ReadyWeapon(sheet, item.name, on, modifier, canMaster)
    end
end

-- Makes the armor and shield items say what the sheet wears, after the armor was set
-- somewhere else (the Defense page, a new character).
function ns.MatchWorn(sheet)
    for _, item in ipairs(sheet.items) do
        local key = R.ARMOR_ITEMS[item.name]
        if key then
            item.equipped = key == sheet.armor
        elseif item.name == R.SHIELD_ITEM then
            item.equipped = sheet.shield == true
        end
    end
end

function RPSheet:SetEquipped(item, on)
    ns.EquipItem(self:Sheet(), item, on,
        function(stat) return self:Mod(stat) end,
        function() return self:MasteriesUsed() < self:MasteryLimit() end)
    -- The weapon in hand may just have been put away.
    local state, count = self:State(), #ns.ReadyWeapons(self:Sheet())
    if (state.weapon or 1) > math.max(1, count) then state.weapon = 1 end
    if ns.ItemSlot(item) == "weapon" then ns.RebuildOptions() end -- a weapon page may have been added
end
