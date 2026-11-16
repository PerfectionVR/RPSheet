-- The spells a species or its lineage gives (`cantrips` and `spells` in
-- Data/Lineages.lua and Data/Species.lua): cantrips from level 1, and a spell at levels
-- 3 and 5 that is cast once per long rest without a slot, and with slots like any
-- other. All are always prepared and count against no limit. They are on the spell
-- list marked auto = "species:<name>" and are cast with the ability the player chose
-- with the lineage: sheet.lineageStat ("INT", "WIS" or "CHA", Sheet/LineageCasting.lua).
-- The casting without a slot goes through ns.SpellChoice (Sheet/SpellChoices.lua,
-- Actions/SpellChoices.lua), as a feat's does.
local _, ns = ...
local R = ns.Rules

local LEVELS = { 3, 5 }
local PREFIX = "species:"
local OLD = "lineagespell:" -- these spells were abilities with a bar of one use before

-- { { name =, level = <character level>, once = true for the levelled ones } } for the
-- spells the character's species and lineage give at its level, cantrips first.
-- `sheet` may be the wizard's draft or the level dialog's stand-in.
function ns.SpeciesSpells(sheet)
    local list = {}
    local from = ns.LineageSource(sheet.species, sheet.lineage)
    if not from then return list end
    for _, name in ipairs(from.cantrips or {}) do
        -- An elf may have learned another Wizard cantrip in place of Prestidigitation.
        if from.swap and name == from.swap.cantrip then name = ns.LineageCantrip(sheet) end
        if R.SPELLS[name] then list[#list + 1] = { name = name, level = 1 } end
    end
    for index, name in ipairs(from.spells or {}) do
        local level = LEVELS[index]
        if level and (sheet.level or 1) >= level and R.SPELLS[name] then list[#list + 1] = { name = name, level = level, once = true } end
    end
    return list
end

-- { [name] = true } for the cantrips among them.
function ns.SpeciesCantrips(sheet)
    local names = {}
    for _, given in ipairs(ns.SpeciesSpells(sheet)) do
        if R.SPELLS[given.name].level == 0 then names[given.name] = true end
    end
    return names
end

-- How a spell is cast without a slot because the lineage gives it, in the form of an
-- entry of R.SPELL_CHOICES, or nil.
function ns.LineageSpellCasting(sheet, name)
    for _, given in ipairs(type(sheet.species) == "string" and ns.SpeciesSpells(sheet) or {}) do
        if given.name == name and given.once and not (sheet.dismissed or {})[PREFIX .. name] then
            local trait = ns.LineageTrait(sheet.species)
            return {
                feature = trait, spellLevel = R.SPELLS[name].level, once = true, mark = "lineage",
                note = ("%s: always prepared. You cast it once without a spell slot; a long rest brings that casting back. Other castings spend a slot."):format(trait),
            }
        end
    end
end

-- The ability a spell is cast with if the species or lineage put it on the list, or nil.
function ns.SpeciesSpellStat(sheet, spell)
    if (spell.auto or "") ~= PREFIX .. (spell.name or "") then return end
    return ns.LineageCastStat(sheet)
end

-- Sheet upkeep: keeps the spell list in step with the species and lineage, and takes
-- off the abilities these spells were before.
function ns.ApplyLineageSpells(sheet)
    for index = #sheet.abilities, 1, -1 do
        if (sheet.abilities[index].auto or ""):find("^" .. OLD) then table.remove(sheet.abilities, index) end
    end
    local wanted = {}
    for _, given in ipairs(ns.SpeciesSpells(sheet)) do
        -- One the player deleted from the spell list stays off.
        if not sheet.dismissed[PREFIX .. given.name] then wanted[given.name] = true end
    end
    -- A spell another source put on the list (a class, a feat) isn't listed twice.
    local have = {}
    for _, spell in ipairs(sheet.spells) do
        local auto = spell.auto or ""
        if auto ~= "" and not auto:find("^" .. PREFIX) and wanted[spell.name] and R.SPELLS[spell.name].level == spell.level then
            have[spell.name] = true
        end
    end
    for index = #sheet.spells, 1, -1 do
        local spell = sheet.spells[index]
        local auto = spell.auto or ""
        local own = auto:match("^" .. PREFIX .. "(.+)$")
        if own then
            if wanted[own] and not have[own] then have[own] = true else table.remove(sheet.spells, index) end
        elseif auto == "" and wanted[spell.name] and R.SPELLS[spell.name].level == spell.level and not have[spell.name] then
            -- Added by hand before: from now on it belongs to the lineage.
            spell.auto, spell.free = PREFIX .. spell.name, true
            have[spell.name] = true
        end
    end
    for _, given in ipairs(ns.SpeciesSpells(sheet)) do
        if wanted[given.name] and not have[given.name] then
            local spell = CopyTable(R.SPELLS[given.name])
            spell.free, spell.auto = true, PREFIX .. given.name
            sheet.spells[#sheet.spells + 1] = spell
            have[given.name] = true
        end
    end
end
