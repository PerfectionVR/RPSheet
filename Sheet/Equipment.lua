-- Carried armor, shields and weapons as the things you wear and wield: equipping one
-- in the inventory puts the armor on, raises the shield or readies the weapon, and
-- putting it away undoes that. An item is one of those by its name, or by the plain
-- thing it counts as (item.base), which is how a magic sword or a named suit of armor
-- works; item.bonus is the magic bonus that goes with it.
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon

-- The plain item this one counts as: its own name unless a base is set.
function ns.ItemBase(item)
    return (item.base and item.base ~= "") and item.base or item.name
end

-- "armor", "shield" or "weapon" for an item that is one of those; nil for the rest.
function ns.ItemSlot(item)
    local base = ns.ItemBase(item)
    if R.ARMOR_ITEMS[base] then return "armor" end
    if base == R.SHIELD_ITEM then return "shield" end
    if R.WEAPONS[base] then return "weapon" end
end

-- The sheet's weapons that are at hand: named and not put away.
function ns.ReadyWeapons(sheet)
    local ready = {}
    for _, weapon in ipairs(sheet.weapons) do
        if weapon.name ~= "" and not weapon.stowed then ready[#ready + 1] = weapon end
    end
    return ready
end

-- Readies or puts away the sheet's weapons that go with an item: the ones of its
-- name, and for a plain basic weapon the ones of that kind. A basic kind that isn't
-- on the sheet yet gets an entry when it is readied; a weapon of your own is only
-- found by its name.
local function ReadyWeapon(sheet, item, on, modifier, canMaster)
    local base, found = ns.ItemBase(item), false
    local plain = base == item.name
    for _, weapon in ipairs(sheet.weapons) do
        if weapon.name == item.name or (plain and weapon.base == base) then
            weapon.stowed, found = not on, true
        end
    end
    if found or not on or not R.WEAPONS[base] then return end
    local weapon = ns.NewBasicWeapon(base, modifier, ns.SheetWeaponProficient(sheet, base), canMaster())
    weapon.name, weapon.magic = item.name, item.bonus or 0
    sheet.weapons[#sheet.weapons + 1] = weapon
end

-- Equips an item of `sheet` or puts it away. `modifier(stat)` gives the character's
-- ability modifiers and `canMaster()` says whether a new weapon may take a mastery.
function ns.EquipItem(sheet, item, on, modifier, canMaster)
    item.equipped = on
    local slot = ns.ItemSlot(item)
    if slot == "armor" then
        local key = R.ARMOR_ITEMS[ns.ItemBase(item)]
        if on then
            sheet.armor = key
            -- One suit at a time.
            for _, other in ipairs(sheet.items) do
                if other ~= item and ns.ItemSlot(other) == "armor" then other.equipped = false end
            end
        elseif sheet.armor == key then
            sheet.armor = "NONE"
        end
    elseif slot == "shield" then
        sheet.shield = on
        for _, other in ipairs(sheet.items) do
            if on and other ~= item and ns.ItemSlot(other) == "shield" then other.equipped = false end
        end
    else
        ReadyWeapon(sheet, item, on, modifier, canMaster)
    end
end

-- Makes the armor and shield items say what the sheet wears, after the armor was set
-- somewhere else (the Defense page, a new character). Of several suits of the same
-- kind, the one that was on stays on.
function ns.MatchWorn(sheet)
    local function Match(slot, wanted)
        local keep
        for _, item in ipairs(sheet.items) do
            if ns.ItemSlot(item) == slot and wanted(item) and (not keep or (item.equipped and not keep.equipped)) then keep = item end
        end
        for _, item in ipairs(sheet.items) do
            if ns.ItemSlot(item) == slot then item.equipped = item == keep end
        end
    end
    Match("armor", function(item) return R.ARMOR_ITEMS[ns.ItemBase(item)] == sheet.armor end)
    Match("shield", function() return sheet.shield == true end)
end

-- The magic bonus to Armor Class of the armor and shield that are on.
function RPSheet:WornBonus()
    local total = 0
    for _, item in ipairs(self:Sheet().items) do
        local slot = ns.ItemSlot(item)
        if item.equipped and (slot == "armor" or slot == "shield") and item.name ~= "" then total = total + (item.bonus or 0) end
    end
    return total
end

function RPSheet:SetEquipped(item, on)
    ns.EquipItem(self:Sheet(), item, on,
        function(stat) return self:Mod(stat) end,
        function() return self:MasteriesUsed() < self:MasteryLimit() end)
    -- The weapon in hand may just have been put away.
    local state, count = self:State(), #ns.ReadyWeapons(self:Sheet())
    if (state.weapon or 1) > math.max(1, count) then state.weapon = 1 end
    ns.RebuildOptions() -- a weapon page may have been added
end
