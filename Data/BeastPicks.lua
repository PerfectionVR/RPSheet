-- Turns the beasts (Data/Beasts.lua and the Data/BeastsCR*.lua files) into the "forms"
-- pick list of the level dialog and into forms the sheet can be in.
--
-- The druid level a beast needs follows from its challenge rating: up to 1/4 from
-- level 2, 1/2 from level 4, 1 from level 8, and nothing that flies before level 8.
-- A Circle of the Moon druid reaches a challenge rating of a third of its level, so
-- 1 at level 3 and 6 at level 18; the flying rule stays.
local _, ns = ...
local R = ns.Rules

local CR_NAMES = { [0] = "0", [1 / 8] = "1/8", [1 / 4] = "1/4", [1 / 2] = "1/2" }
local SENSES = { "Blindsight", "Darkvision" }

-- level (nil: never without the circle) and moonLevel (nil: no sooner than level).
local function Levels(beast)
    local cr = beast.cr
    local level = (cr <= 1 / 4 and 2) or (cr <= 1 / 2 and 4) or (cr <= 1 and 8) or nil
    local moon = math.max(3, math.ceil(cr * 3))
    if beast.fly then
        level = 8
        moon = math.max(8, moon)
    end
    if level and moon >= level then moon = nil end
    return level, moon
end

-- "Senses: blindsight 10 feet, darkvision 60 feet." Sheet/Senses.lua reads the ranges
-- from the form itself; the wording is for the player.
local function SensesText(beast)
    local parts = {}
    for _, sense in ipairs(SENSES) do
        if beast.senses[sense] then parts[#parts + 1] = ("%s %d feet"):format(sense:lower(), beast.senses[sense]) end
    end
    return #parts > 0 and (" Senses: " .. table.concat(parts, ", ") .. ".") or ""
end

local items, order = {}, {}
for name, beast in pairs(R.BEASTS) do
    order[#order + 1] = name
    beast.level, beast.moonLevel = Levels(beast)
    local crName = CR_NAMES[beast.cr] or ("%d"):format(beast.cr)
    local skills = #beast.skills > 0 and (" Proficient in " .. table.concat(beast.skills, ", ") .. ".") or ""
    beast.desc = ("%s beast, challenge rating %s. Armor Class %d, speed %d feet%s. Strength %d, Dexterity %d, Constitution %d.%s%s%s"):format(
        beast.size, crName, beast.ac, beast.speed, beast.moves and (", " .. beast.moves) or "", beast.str, beast.dex, beast.con,
        SensesText(beast), skills, beast.note and (" " .. beast.note) or "")
    local group = "Challenge rating " .. crName
    if not beast.level then group = ("%s (Circle of the Moon, level %d)"):format(group, beast.moonLevel) end
    items[name] = { desc = beast.desc, level = beast.level, moonLevel = beast.moonLevel, group = group }
    R.FORMS[R.BeastFormPassive(name)] = {
        name = name, beast = true, ac = beast.ac, speed = beast.speed,
        scores = { STR = beast.str, DEX = beast.dex, CON = beast.con },
        senses = beast.senses, skills = beast.skills,
    }
end
-- By challenge rating, then by name, so each rating is one heading in the dialog.
table.sort(order, function(a, b)
    local first, second = R.BEASTS[a].cr, R.BEASTS[b].cr
    if first ~= second then return first < second end
    return a < b
end)

-- Known forms by druid level. `custom`: put on the sheet by Sheet/BeastForms.lua.
-- The list is long, so beasts the character can't learn yet are left out.
R.PICK_LISTS.forms = {
    title = "Wild Shape forms", base = "Druid", custom = true, hideBlocked = true,
    known = { { 2, 4 }, { 4, 6 }, { 8, 8 } },
    items = items, order = order,
}
R.PICK_LIST_ORDER[#R.PICK_LIST_ORDER + 1] = "forms"
