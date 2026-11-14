-- The spells a lineage grants at levels 3 and 5 (see Data/Lineages.lua). Each can be
-- cast once per long rest without a slot, so each is a clickable ability with a bar
-- of one use. They are marked auto = "lineagespell:<name>".
local _, ns = ...
local R = ns.Rules

local LEVELS = { 3, 5 }
local PREFIX = "lineagespell:"

-- { { name = "Misty Step", level = 5 }, ... } for the spells the character has reached
-- and not deleted.
local function Spells(sheet)
    local _, option = R.Lineage(sheet.species, sheet.lineage)
    local list = {}
    for index, name in ipairs(option and option.spells or {}) do
        local level = LEVELS[index]
        if level and sheet.level >= level and not sheet.dismissed[PREFIX .. name] then
            list[#list + 1] = { name = name, level = level }
        end
    end
    return list
end

-- Their bars, in the same form as class `pools` (see Data/Classes.lua).
function ns.LineagePools(sheet)
    local pools = {}
    for _, spell in ipairs(Spells(sheet)) do
        pools[#pools + 1] = { name = spell.name, from = spell.level, steps = { { spell.level, 1 } } }
    end
    return pools
end

-- Puts the lineage's spells on the sheet and takes off those of another lineage or
-- of a level the character no longer has.
function ns.ApplyLineageSpells(sheet)
    local current = {}
    for _, spell in ipairs(Spells(sheet)) do current[PREFIX .. spell.name] = spell end

    for index = #sheet.abilities, 1, -1 do
        local auto = sheet.abilities[index].auto or ""
        if auto:find("^" .. PREFIX) then
            if current[auto] then
                current[auto] = nil -- already there
            else
                table.remove(sheet.abilities, index)
            end
        end
    end
    for key, spell in pairs(current) do
        sheet.abilities[#sheet.abilities + 1] = {
            name = spell.name, auto = key,
            desc = ("Lineage spell, gained at level %d. Cast it once per long rest without a spell slot; you can also cast it with your slots."):format(spell.level),
            actions = { ns.FeatureKit.Spend(spell.name) },
        }
    end
end
