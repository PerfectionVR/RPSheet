-- The basic weapons: every simple and martial weapon, with its damage, properties and
-- mastery. A weapon on a sheet that names one of these in `base` takes its properties
-- from here; a weapon without `base` is the player's own and is set up by hand.
--   category   "SIMPLE" or "MARTIAL"
--   ranged     true for a ranged weapon
--   dice       { count, sides }; versatile = sides when held in two hands
--   damage     damage type
--   props      property letters, see R.WEAPON_PROPERTIES
--   range      normal / long range in feet, for thrown and ranged weapons
--   mastery    its mastery property (see Data/Combat.lua)
local _, ns = ...
local R = ns.Rules

R.WEAPON_PROPERTIES = {
    A = { name = "Ammunition", desc = "Needs ammunition; each attack uses one piece." },
    F = { name = "Finesse", desc = "Uses Strength or Dexterity, whichever you choose." },
    H = { name = "Heavy", desc = "Disadvantage if your Strength (melee) or Dexterity (ranged) is below 13." },
    L = { name = "Light", desc = "After attacking with it you can make an extra attack with a second light weapon as a bonus action." },
    LD = { name = "Loading", desc = "Fires only once per action, bonus action or reaction." },
    R = { name = "Reach", desc = "Adds 5 feet to your reach." },
    T = { name = "Thrown", desc = "Can be thrown for a ranged attack, using the same ability." },
    ["2H"] = { name = "Two-Handed", desc = "Needs both hands." },
    V = { name = "Versatile", desc = "Deals more damage when held in two hands." },
}
R.WEAPON_PROPERTY_ORDER = { "F", "L", "H", "2H", "V", "R", "T", "A", "LD" }

R.WEAPONS = {}
R.WEAPON_ORDER = {} -- simple melee, simple ranged, martial melee, martial ranged

local function Weapon(name, category, ranged, count, sides, damage, props, mastery, extra)
    local weapon = {
        name = name, category = category, ranged = ranged, dice = { count, sides },
        damage = damage, props = {}, mastery = mastery,
    }
    for prop in (props or ""):gmatch("[^,]+") do weapon.props[prop] = true end
    for key, value in pairs(extra or {}) do weapon[key] = value end
    R.WEAPONS[name] = weapon
    R.WEAPON_ORDER[#R.WEAPON_ORDER + 1] = name
end

-- Simple melee
Weapon("Club", "SIMPLE", false, 1, 4, "bludgeoning", "L", "Slow")
Weapon("Dagger", "SIMPLE", false, 1, 4, "piercing", "F,L,T", "Nick", { range = "20/60" })
Weapon("Greatclub", "SIMPLE", false, 1, 8, "bludgeoning", "2H", "Push")
Weapon("Handaxe", "SIMPLE", false, 1, 6, "slashing", "L,T", "Vex", { range = "20/60" })
Weapon("Javelin", "SIMPLE", false, 1, 6, "piercing", "T", "Slow", { range = "30/120" })
Weapon("Light Hammer", "SIMPLE", false, 1, 4, "bludgeoning", "L,T", "Nick", { range = "20/60" })
Weapon("Mace", "SIMPLE", false, 1, 6, "bludgeoning", "", "Sap")
Weapon("Quarterstaff", "SIMPLE", false, 1, 6, "bludgeoning", "V", "Topple", { versatile = 8 })
Weapon("Sickle", "SIMPLE", false, 1, 4, "slashing", "L", "Nick")
Weapon("Spear", "SIMPLE", false, 1, 6, "piercing", "T,V", "Sap", { versatile = 8, range = "20/60" })
-- Simple ranged
Weapon("Dart", "SIMPLE", true, 1, 4, "piercing", "F,T", "Vex", { range = "20/60" })
Weapon("Light Crossbow", "SIMPLE", true, 1, 8, "piercing", "A,LD,2H", "Slow", { range = "80/320" })
Weapon("Shortbow", "SIMPLE", true, 1, 6, "piercing", "A,2H", "Vex", { range = "80/320" })
Weapon("Sling", "SIMPLE", true, 1, 4, "bludgeoning", "A", "Slow", { range = "30/120" })
-- Martial melee
Weapon("Battleaxe", "MARTIAL", false, 1, 8, "slashing", "V", "Topple", { versatile = 10 })
Weapon("Flail", "MARTIAL", false, 1, 8, "bludgeoning", "", "Sap")
Weapon("Glaive", "MARTIAL", false, 1, 10, "slashing", "H,R,2H", "Graze")
Weapon("Greataxe", "MARTIAL", false, 1, 12, "slashing", "H,2H", "Cleave")
Weapon("Greatsword", "MARTIAL", false, 2, 6, "slashing", "H,2H", "Graze")
Weapon("Halberd", "MARTIAL", false, 1, 10, "slashing", "H,R,2H", "Cleave")
Weapon("Lance", "MARTIAL", false, 1, 10, "piercing", "H,R,2H", "Topple")
Weapon("Longsword", "MARTIAL", false, 1, 8, "slashing", "V", "Sap", { versatile = 10 })
Weapon("Maul", "MARTIAL", false, 2, 6, "bludgeoning", "H,2H", "Topple")
Weapon("Morningstar", "MARTIAL", false, 1, 8, "piercing", "", "Sap")
Weapon("Pike", "MARTIAL", false, 1, 10, "piercing", "H,R,2H", "Push")
Weapon("Rapier", "MARTIAL", false, 1, 8, "piercing", "F", "Vex")
Weapon("Scimitar", "MARTIAL", false, 1, 6, "slashing", "F,L", "Nick")
Weapon("Shortsword", "MARTIAL", false, 1, 6, "piercing", "F,L", "Vex")
Weapon("Trident", "MARTIAL", false, 1, 8, "piercing", "T,V", "Topple", { versatile = 10, range = "20/60" })
Weapon("War Pick", "MARTIAL", false, 1, 8, "piercing", "V", "Sap", { versatile = 10 })
Weapon("Warhammer", "MARTIAL", false, 1, 8, "bludgeoning", "V", "Push", { versatile = 10 })
Weapon("Whip", "MARTIAL", false, 1, 4, "slashing", "F,R", "Slow")
-- Martial ranged
Weapon("Blowgun", "MARTIAL", true, 1, 1, "piercing", "A,LD", "Vex", { range = "25/100" })
Weapon("Hand Crossbow", "MARTIAL", true, 1, 6, "piercing", "A,L,LD", "Vex", { range = "30/120" })
Weapon("Heavy Crossbow", "MARTIAL", true, 1, 10, "piercing", "A,H,LD,2H", "Push", { range = "100/400" })
Weapon("Longbow", "MARTIAL", true, 1, 8, "piercing", "A,H,2H", "Slow", { range = "150/600" })
Weapon("Musket", "MARTIAL", true, 1, 12, "piercing", "A,LD,2H", "Slow", { range = "40/120" })
Weapon("Pistol", "MARTIAL", true, 1, 10, "piercing", "A,LD", "Vex", { range = "30/90" })

-- e.g. "1d8 slashing, versatile (1d10)" for a dropdown or a tooltip.
function R.WeaponSummary(name)
    local weapon = R.WEAPONS[name]
    local dice = weapon.dice[2] == 1 and "1" or ("%dd%d"):format(weapon.dice[1], weapon.dice[2])
    local parts = { ("%s %s"):format(dice, weapon.damage) }
    for _, prop in ipairs(R.WEAPON_PROPERTY_ORDER) do
        if weapon.props[prop] then
            local text = R.WEAPON_PROPERTIES[prop].name:lower()
            if prop == "V" then text = ("%s (1d%d)"):format(text, weapon.versatile) end
            if prop == "T" or (prop == "A" and weapon.range) then text = ("%s (%s ft)"):format(text, weapon.range) end
            parts[#parts + 1] = text
        end
    end
    return table.concat(parts, ", ")
end
