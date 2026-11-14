-- The player's armoury: weapons kept for the whole account, to copy onto any character.
-- (Not Sheet/Armoury.lua, which works out a weapon's numbers.)
-- An entry is a full copy of a sheet weapon, so it has the fields of Rules.TEMPLATES.weapon.
-- Names are unique in the armoury, whatever their capitals.
local _, ns = ...
local R = ns.Rules
local RPSheet = ns.addon
local Util = ns.Util

local checked -- true once the saved list was brought into the current shape

-- The stored weapons, in the order they were saved.
function RPSheet:StoredWeapons()
    local global = self.db.global
    if type(global.weaponStore) ~= "table" then global.weaponStore = {} end
    if not checked then
        -- Weapons stored by an older version get the fields added since, like a sheet's.
        Util.NormalizeList(global.weaponStore, R.TEMPLATES.weapon)
        checked = true
    end
    return global.weaponStore
end

-- Index of the stored weapon with this name, or nil.
function RPSheet:FindStoredWeapon(name)
    name = (name or ""):lower()
    for index, weapon in ipairs(self:StoredWeapons()) do
        if weapon.name:lower() == name then return index end
    end
end

-- Stores a copy of a weapon, in place of the one with the same name if there is one.
function RPSheet:StoreWeapon(weapon)
    local store = self:StoredWeapons()
    local index = self:FindStoredWeapon(weapon.name) or #store + 1
    store[index] = Util.FillDefaults(CopyTable(weapon), R.TEMPLATES.weapon)
    return index
end

-- A copy of a stored weapon, ready to go on a sheet.
function RPSheet:CopyStoredWeapon(index)
    local weapon = self:StoredWeapons()[index]
    return weapon and CopyTable(weapon) or nil
end

-- Adds a copy of a stored weapon to the active character. Returns false if it is gone.
function RPSheet:AddStoredWeapon(index)
    local weapon = self:CopyStoredWeapon(index)
    if not weapon then return false end
    local weapons = self:Sheet().weapons
    weapons[#weapons + 1] = weapon
    return true
end

-- Returns false when the name is empty or another stored weapon has it.
function RPSheet:RenameStoredWeapon(index, name)
    local weapon, other = self:StoredWeapons()[index], self:FindStoredWeapon(name)
    if not weapon or name == "" or (other and other ~= index) then return false end
    weapon.name = name
    return true
end

function RPSheet:DeleteStoredWeapon(index)
    table.remove(self:StoredWeapons(), index)
end

-- The indexes of the stored weapons, sorted by name.
function RPSheet:StoredWeaponOrder()
    local store, order = self:StoredWeapons(), {}
    for index in ipairs(store) do order[index] = index end
    table.sort(order, function(a, b)
        local nameA, nameB = store[a].name:lower(), store[b].name:lower()
        if nameA == nameB then return a < b end
        return nameA < nameB
    end)
    return order
end

-- One line about a weapon that isn't on the sheet: its dice, type, properties and
-- mastery, e.g. "Longsword: 1d8 slashing, versatile (1d10), mastery: Sap".
function ns.StoredWeaponSummary(weapon)
    local data, parts = ns.WeaponData(weapon), {}
    if data then
        parts[1] = R.WeaponSummary(data.name)
        -- Say what it is when the player gave it a name of their own.
        if weapon.name ~= data.name then parts[1] = ("%s: %s"):format(data.name, parts[1]) end
    else
        parts[1] = ("%dd%d %s"):format(weapon.dice, weapon.sides, weapon.heal and "healing" or "damage")
        parts[2] = R.STAT_NAMES[weapon.stat] or weapon.stat
    end
    if data and weapon.heal then parts[#parts + 1] = "healing" end
    if R.MASTERIES[weapon.mastery] then parts[#parts + 1] = "mastery: " .. weapon.mastery end
    if not weapon.proficient then parts[#parts + 1] = "not proficient" end
    return table.concat(parts, ", ")
end
