-- Beasts a druid can know as Wild Shape forms: the ones the rules recommend for the
-- classic cat, bear, travel, aquatic and flight forms. Each is an option of the
-- "forms" pick list (see Data/Picks.lua) and a form (see Data/Forms.lua) that is in
-- effect while the passive "<Beast> form" is switched on.
--
-- R.BEASTS[name] = {
--     level      druid level that can learn it; moonLevel for the Circle of the Moon,
--                which reaches higher challenge ratings sooner (never sooner for flying)
--     ac, speed  Armor Class and walking speed; moves = its other ways of moving
--     str, dex   the scores the character takes on
--     skills     skills the beast is proficient in
--     attacks    { { name, attack bonus, dice, sides, flat damage, damage type, note } }
--     note       anything else worth knowing
-- }
local _, ns = ...
local R = ns.Rules

R.BEASTS = {
    ["Rat"] = { level = 2, ac = 10, speed = 20, moves = "climbing 20 feet", str = 2, dex = 11, skills = { "Perception" }, size = "Tiny",
        attacks = { { "Bite", 2, 0, 4, 1, "piercing" } } },
    ["Riding Horse"] = { level = 2, ac = 11, speed = 60, str = 16, dex = 13, skills = {}, size = "Large",
        attacks = { { "Hooves", 5, 1, 8, 3, "bludgeoning" } } },
    ["Spider"] = { level = 2, ac = 12, speed = 20, moves = "climbing 20 feet, also on ceilings and webs", str = 2, dex = 14, skills = { "Stealth" }, size = "Tiny",
        attacks = { { "Bite", 4, 1, 4, 1, "piercing, the die is poison" } } },
    ["Wolf"] = { level = 2, ac = 12, speed = 40, str = 14, dex = 15, skills = { "Perception", "Stealth" }, size = "Medium",
        note = "Advantage on attacks against a creature with one of your allies next to it.",
        attacks = { { "Bite", 4, 1, 6, 2, "piercing", "A Medium or smaller target is knocked prone." } } },
    ["Panther"] = { level = 2, ac = 13, speed = 50, moves = "climbing 40 feet", str = 14, dex = 16, skills = { "Perception", "Stealth" }, size = "Medium",
        attacks = { { "Rend", 5, 1, 6, 3, "slashing" } } },
    ["Elk"] = { level = 2, ac = 10, speed = 50, str = 16, dex = 10, skills = { "Perception" }, size = "Large",
        attacks = { { "Ram", 5, 1, 6, 3, "bludgeoning", "After moving 20 feet straight at a Large or smaller target: 1d6 more, and it is knocked prone." } } },
    ["Black Bear"] = { level = 4, moonLevel = 3, ac = 11, speed = 30, moves = "climbing and swimming 30 feet", str = 15, dex = 12, skills = { "Perception" }, size = "Medium",
        attacks = { { "Rend", 4, 1, 6, 2, "slashing", "Two of these with the Attack action: click once for each." } } },
    ["Giant Seahorse"] = { level = 4, moonLevel = 3, ac = 14, speed = 5, moves = "swimming 40 feet, breathes only water", str = 15, dex = 12, skills = {}, size = "Large",
        attacks = { { "Ram", 4, 2, 6, 2, "bludgeoning", "After moving 20 feet straight at the target the dice are d8s." } } },
    ["Tiger"] = { level = 8, moonLevel = 3, ac = 13, speed = 40, str = 17, dex = 16, skills = { "Perception", "Stealth" }, size = "Large",
        attacks = { { "Rend", 5, 2, 6, 3, "slashing", "A Large or smaller target is knocked prone." } } },
    ["Brown Bear"] = { level = 8, moonLevel = 3, ac = 11, speed = 40, moves = "climbing 30 feet", str = 17, dex = 12, skills = { "Perception" }, size = "Large",
        note = "One Bite and one Claw with the Attack action.",
        attacks = { { "Bite", 5, 1, 8, 3, "piercing" }, { "Claw", 5, 1, 4, 3, "slashing", "A Large or smaller target is knocked prone." } } },
    ["Eagle"] = { level = 8, ac = 12, speed = 10, moves = "flying 60 feet", str = 6, dex = 15, skills = { "Perception" }, size = "Small",
        attacks = { { "Talons", 4, 1, 4, 2, "slashing" } } },
    ["Giant Bat"] = { level = 8, ac = 13, speed = 10, moves = "flying 60 feet", str = 15, dex = 16, skills = {}, size = "Large",
        attacks = { { "Bite", 5, 1, 6, 3, "piercing" } } },
    ["Hawk"] = { level = 8, ac = 13, speed = 10, moves = "flying 60 feet", str = 5, dex = 16, skills = { "Perception" }, size = "Tiny",
        attacks = { { "Talons", 5, 0, 4, 1, "slashing" } } },
    ["Pteranodon"] = { level = 8, ac = 13, speed = 10, moves = "flying 60 feet, without provoking opportunity attacks when it flies out of reach", str = 12, dex = 15, skills = { "Perception" }, size = "Medium",
        attacks = { { "Bite", 4, 1, 8, 2, "piercing" } } },
    ["Raven"] = { level = 8, ac = 12, speed = 10, moves = "flying 50 feet", str = 2, dex = 14, skills = { "Perception" }, size = "Tiny",
        note = "It can mimic simple sounds it has heard.",
        attacks = { { "Beak", 4, 0, 4, 1, "piercing" } } },
}

-- The name of the passive that marks a beast form as taken.
function R.BeastFormPassive(name)
    return name .. " form"
end

local items, order = {}, {}
for name, beast in pairs(R.BEASTS) do
    order[#order + 1] = name
    local skills = #beast.skills > 0 and (" Proficient in " .. table.concat(beast.skills, " and ") .. ".") or ""
    beast.desc = ("%s beast. Armor Class %d, speed %d feet%s. Strength %d, Dexterity %d.%s%s"):format(
        beast.size, beast.ac, beast.speed, beast.moves and (", " .. beast.moves) or "", beast.str, beast.dex, skills,
        beast.note and (" " .. beast.note) or "")
    items[name] = { desc = beast.desc, level = beast.level, moonLevel = beast.moonLevel }
    R.FORMS[R.BeastFormPassive(name)] = {
        name = name, beast = true, ac = beast.ac, speed = beast.speed,
        scores = { STR = beast.str, DEX = beast.dex }, skills = beast.skills,
    }
end
table.sort(order)

-- Known forms by druid level. `custom`: put on the sheet by Sheet/BeastForms.lua.
R.PICK_LISTS.forms = {
    title = "Wild Shape forms", base = "Druid", custom = true,
    known = { { 2, 4 }, { 4, 6 }, { 8, 8 } },
    items = items, order = order,
}
R.PICK_LIST_ORDER[#R.PICK_LIST_ORDER + 1] = "forms"
