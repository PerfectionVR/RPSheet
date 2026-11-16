-- The ability a species' or lineage's spells are cast with. The rules let the player
-- choose Intelligence, Wisdom or Charisma when the lineage is chosen (the species, for
-- one without lineages): sheet.lineageStat. A Tauren lineage with a saving throw
-- chooses Strength, Constitution or Wisdom for its DC the same way (`saveStats` in
-- Data/Lineages.lua). The wizard and the level dialog ask for it
-- (Wizard/PageOrigin.lua, Options/LineageAbility.lua); Customize > Lineage, languages,
-- renown changes it freely. The spells themselves are in Sheet/LineageSpells.lua.
local _, ns = ...
local R = ns.Rules

-- What gives the spells: the chosen lineage's entry, or the species' own for one
-- without lineages (Gnome, Haranir). Nil when they give none (or no lineage is chosen).
function ns.LineageSource(speciesKey, lineageName)
    local lineages, option = R.Lineage(speciesKey, lineageName)
    local from = lineages and option or (not lineages and R.SPECIES[speciesKey or ""]) or nil
    if from and (from.cantrips or from.spells) then return from end
end

-- True when the species and lineage give spells, so the ability is to be chosen.
function ns.LineageCasts(speciesKey, lineageName)
    return ns.LineageSource(speciesKey, lineageName) ~= nil
end

-- The abilities the lineage lets the player choose from: Strength, Constitution or
-- Wisdom for a Tauren lineage's DC, otherwise those of spells.
function ns.LineageStats(speciesKey, lineageName)
    local _, option = R.Lineage(speciesKey or "", lineageName)
    return option and option.saveStats or R.LINEAGE_STATS
end

-- True when the species and lineage ask for an ability: for their spells or a DC.
function ns.LineageAsks(speciesKey, lineageName)
    local _, option = R.Lineage(speciesKey or "", lineageName)
    return ns.LineageCasts(speciesKey, lineageName) or (option ~= nil and option.saveStats ~= nil)
end

-- What the ability is for, in a few words: "its spells" or "its save DC".
function ns.LineageStatUse(speciesKey, lineageName)
    return ns.LineageCasts(speciesKey, lineageName) and "its spells" or "its save DC"
end

-- The trait the spells come with, as the sheet calls it ("Elven Lineage").
function ns.LineageTrait(speciesKey)
    local lineages, species = R.LINEAGES[speciesKey or ""], R.SPECIES[speciesKey or ""]
    return lineages and lineages.trait or species and species.spellTrait or "Lineage"
end

-- The chosen ability, or nil when none (or one the rules don't offer) is set.
function ns.LineageStatChosen(sheet)
    for _, stat in ipairs(ns.LineageStats(sheet.species, sheet.lineage)) do
        if sheet.lineageStat == stat then return stat end
    end
end

-- The ability the spells are cast with: the chosen one, or until one is chosen the
-- best of the three, so the numbers aren't worse than they will be.
function ns.LineageCastStat(sheet)
    local chosen = ns.LineageStatChosen(sheet)
    if chosen then return chosen end
    local best, score
    for _, stat in ipairs(ns.LineageStats(sheet.species, sheet.lineage)) do
        local value = ns.FeatureKit.Score(sheet, stat)
        if not score or value > score then best, score = stat, value end
    end
    return best
end

-- The three abilities for a dropdown: { INT = "Intelligence", ... }.
function ns.LineageStatValues(speciesKey, lineageName)
    local values = {}
    for _, stat in ipairs(ns.LineageStats(speciesKey, lineageName)) do values[stat] = R.STAT_NAMES[stat] end
    return values
end

-- The names of the three, for a sentence: "Intelligence, Wisdom or Charisma".
function ns.LineageStatWords(speciesKey, lineageName)
    local stats = ns.LineageStats(speciesKey, lineageName)
    return ("%s, %s or %s"):format(R.STAT_NAMES[stats[1]], R.STAT_NAMES[stats[2]], R.STAT_NAMES[stats[3]])
end

-- True when the character's spells or DC from its species want the ability chosen.
function ns.LineageStatMissing(sheet)
    return ns.LineageAsks(sheet.species, sheet.lineage) and not ns.LineageStatChosen(sheet)
end

-- The cantrip a lineage that lets it be exchanged after a long rest (an elf's
-- Prestidigitation, for another Wizard cantrip) has right now.
function ns.LineageCantrip(sheet)
    local from = ns.LineageSource(sheet.species, sheet.lineage)
    local swap = from and from.swap
    if not swap then return end
    local list = R.PICK_LISTS[R.CANTRIP_LISTS[swap.list] or ""]
    local name = sheet.lineageCantrip or ""
    if list and list.items[name] then return name end
    return swap.cantrip
end

-- The cantrips it can be exchanged for, in the list's order (Data/SpellPicks.lua).
function ns.LineageCantripChoices(sheet)
    local from = ns.LineageSource(sheet.species, sheet.lineage)
    local list = from and from.swap and R.PICK_LISTS[R.CANTRIP_LISTS[from.swap.list] or ""]
    return list and list.order or {}
end

-- A sentence for the lineage's text on the sheet: which ability its spells use, or
-- that one is still to be chosen. Empty for a lineage without spells.
function ns.LineageCastingText(sheet)
    if not ns.LineageAsks(sheet.species, sheet.lineage) then return "" end
    local chosen = ns.LineageStatChosen(sheet)
    if not ns.LineageCasts(sheet.species, sheet.lineage) then
        if chosen then return (" Its save DC uses %s."):format(R.STAT_NAMES[chosen]) end
        return " Choose the ability its save DC uses under Customize, Lineage, languages, renown."
    end
    if chosen then return (" Its spells are cast with %s."):format(R.STAT_NAMES[chosen]) end
    return " Choose the ability its spells are cast with under Customize, Lineage, languages, renown."
end
