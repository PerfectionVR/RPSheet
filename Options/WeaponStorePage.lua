-- "Armoury" page under Customize: the weapons kept for all your characters
-- (Sheet/WeaponStore.lua), each with Rename, Delete and a string to share it, and a
-- box to take in a weapon string from someone else (Sheet/WeaponShare.lua).
local _, ns = ...
local RPSheet = ns.addon
local Opt = ns.Opt

-- What was pasted into the import box, and what it decoded to.
local pasted, decoded, problem = "", nil, nil

local args = {
    help = {
        type = "description", order = 0, fontSize = "medium",
        name = function()
            local count = #RPSheet:StoredWeapons()
            local have = count == 0 and "It is empty: open a weapon on the Weapons page and press Save to armoury."
                or ("It holds %s%d|r %s; pick one on the left."):format(Opt.GOLD, count, count == 1 and "weapon" or "weapons")
            return ("Your armoury keeps weapons for all your characters. A character takes a copy from it on the Weapons page, so changing or deleting a weapon here never changes one a character already carries.\n\n%s\n"):format(have)
        end,
    },
    importHeader = { type = "header", order = 1, name = "Add a weapon from a string" },
    import = {
        type = "input", order = 2, width = "full", multiline = 3, name = "Weapon string",
        desc = "Paste a weapon string someone shared with you and press Accept to check it.",
        get = function() return pasted end,
        set = function(_, text)
            pasted = text or ""
            decoded, problem = RPSheet:DecodeWeapon(pasted)
        end,
    },
    status = {
        type = "description", order = 3, fontSize = "medium",
        name = function()
            if pasted == "" then return "" end
            if not decoded then return Opt.RED .. problem .. "|r\n" end
            return ("%sReady to add: %s, %s|r\n"):format(Opt.GREEN, decoded.name, ns.StoredWeaponSummary(decoded))
        end,
    },
    apply = {
        type = "execute", order = 4, name = "Add to armoury",
        disabled = function() return not decoded end,
        confirm = function()
            if not RPSheet:FindStoredWeapon(decoded.name) then return false end
            return ("Your armoury already has a weapon called %s. Replace it with this one?"):format(decoded.name)
        end,
        func = function()
            RPSheet:StoreWeapon(decoded)
            pasted, decoded, problem = "", nil, nil
            ns.RebuildOptions()
        end,
    },
}

-- The page of one stored weapon. `index` is its place in the store.
local function Build(index, weapon)
    return {
        summary = {
            type = "description", order = 0, fontSize = "medium",
            name = function() return ns.StoredWeaponSummary(weapon) .. "\n" end,
        },
        name = {
            type = "input", order = 1, name = "Rename",
            get = function() return weapon.name end,
            set = function(_, value)
                value = value:trim():gsub("[|%c]", "")
                if not RPSheet:RenameStoredWeapon(index, value) then
                    RPSheet:Print(value == "" and "A stored weapon needs a name." or ("Your armoury already has a weapon called %s."):format(value))
                end
                ns.RebuildOptions() -- the pages are sorted by name
            end,
        },
        add = {
            type = "execute", order = 2, name = "Add to this character",
            desc = "Puts a copy of this weapon on the character you are playing now.",
            func = function()
                RPSheet:AddStoredWeapon(index)
                RPSheet:Print(("%s added to your weapons."):format(weapon.name))
                ns.RebuildOptions()
                Opt.Changed()
            end,
        },
        share = {
            type = "input", order = 3, width = "full", multiline = 3, name = "Share this weapon",
            desc = "This text is the weapon. Click in the box, press Ctrl+A then Ctrl+C, and paste it to a friend; they add it on their own Armoury page.",
            get = function() return RPSheet:ExportStoredWeapon(index) end,
            set = function() end, -- read-only: edits are discarded
        },
        delete = {
            type = "execute", order = 2000, name = "Delete from armoury",
            confirm = function()
                return ("Delete %s from your armoury? Characters that already carry a copy keep it."):format(weapon.name)
            end,
            func = function()
                RPSheet:DeleteStoredWeapon(index)
                ns.RebuildOptions()
            end,
        },
    }
end

-- One page per stored weapon, by name.
table.insert(Opt.rebuilders, function()
    for key in pairs(args) do
        if key:find("^stored") then args[key] = nil end
    end
    local store = RPSheet:StoredWeapons()
    for rank, index in ipairs(RPSheet:StoredWeaponOrder()) do
        local weapon = store[index]
        args["stored" .. index] = {
            type = "group", order = 10 + rank,
            name = function() return weapon.name end,
            args = Build(index, weapon),
        }
    end
end)

Opt.custom.armoury = { type = "group", order = 1.5, name = "Armoury", childGroups = "tree", args = args }
