-- The armoury on the "Weapons" tab (Options/Weapons.lua): a button on each weapon that
-- stores it, and a dropdown that copies a stored weapon onto this character.
-- The store itself is Sheet/WeaponStore.lua; its own page is Options/WeaponStorePage.lua.
local _, ns = ...
local RPSheet = ns.addon
local Opt = ns.Opt

-- "Save to armoury" on a weapon's page.
function Opt.StoreWeaponButton(weapon)
    return {
        type = "execute", order = 10, name = "Save to armoury",
        desc = "Keeps a copy of this weapon in your armoury, where all your characters can take it from. Changing the weapon here afterwards doesn't change the copy: save it again for that.",
        disabled = function() return weapon.name == "" end,
        -- Only asks when a stored weapon would be replaced.
        confirm = function()
            if not RPSheet:FindStoredWeapon(weapon.name) then return false end
            return ("Your armoury already has a weapon called %s. Replace it with this one?"):format(weapon.name)
        end,
        func = function()
            RPSheet:StoreWeapon(weapon)
            RPSheet:Print(("%s is now in your armoury."):format(weapon.name))
            ns.RebuildOptions()
        end,
    }
end

-- The stored weapon chosen in the dropdown, by name: names stay right when another
-- weapon is deleted from the armoury, indexes don't.
local picked = ""

local function NoStore()
    return #RPSheet:StoredWeapons() == 0
end

-- "Add from armoury" at the top of the tab, below the basic weapons.
function Opt.StoredWeaponPicker(args)
    args.stored = {
        type = "select", order = 0.8, name = "Add from armoury", width = "double",
        desc = "The weapons you saved to your armoury, on this or another character. Adding one puts a copy on this character; the stored weapon stays as it is.",
        hidden = NoStore,
        values = function()
            local class, values = Opt.Sheet().class, {}
            for _, weapon in ipairs(RPSheet:StoredWeapons()) do
                local data = ns.WeaponData(weapon)
                values[weapon.name] = ("%s - %s%s"):format(weapon.name, ns.StoredWeaponSummary(weapon),
                    (data and not ns.WeaponProficient(class, data.name)) and " |cffff5555(not proficient)|r" or "")
            end
            return values
        end,
        sorting = function()
            local store, names = RPSheet:StoredWeapons(), {}
            for _, index in ipairs(RPSheet:StoredWeaponOrder()) do names[#names + 1] = store[index].name end
            return names
        end,
        get = function() return RPSheet:FindStoredWeapon(picked) and picked or "" end,
        set = function(_, value) picked = value end,
    }
    args.addStored = {
        type = "execute", order = 0.85, name = "Add a copy",
        desc = "The copy is an ordinary weapon: change it freely. Its mastery counts toward your masteries like any other.",
        hidden = NoStore,
        disabled = function() return picked == "" or not RPSheet:FindStoredWeapon(picked) end,
        func = function()
            RPSheet:AddStoredWeapon(RPSheet:FindStoredWeapon(picked))
            picked = ""
            ns.RebuildOptions()
            Opt.Changed()
        end,
    }
    args.breakStored = { type = "description", order = 0.9, name = "", hidden = NoStore }
end
